//
//  DatabaseManager.swift
//  Delta
//
//  Created by Riley Testut on 10/4/15.
//  Copyright © 2015 Riley Testut. All rights reserved.
//

import CoreData

// Workspace
import Roxas

public class DatabaseManager
{
    public static let sharedManager = DatabaseManager()
    
    public let managedObjectContext: NSManagedObjectContext
    
    private let privateManagedObjectContext: NSManagedObjectContext
    private let validationManagedObjectContext: NSManagedObjectContext
    
    // MARK: - Initialization -
    /// Initialization
    
    private init()
    {
        let modelURL = NSBundle(forClass: DatabaseManager.self).URLForResource("Model", withExtension: "momd")
        let managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL!)
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel!)
        
        self.privateManagedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.privateManagedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        self.privateManagedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        self.managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        self.managedObjectContext.parentContext = self.privateManagedObjectContext
        self.managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        self.validationManagedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.validationManagedObjectContext.parentContext = self.managedObjectContext
        self.validationManagedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DatabaseManager.managedObjectContextWillSave(_:)), name: NSManagedObjectContextWillSaveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DatabaseManager.managedObjectContextDidSave(_:)), name: NSManagedObjectContextDidSaveNotification, object: nil)
    }
}

public extension DatabaseManager
{
    class var databaseDirectoryURL: NSURL
    {
        let documentsDirectoryURL = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first!
        
        let databaseDirectoryURL = documentsDirectoryURL.URLByAppendingPathComponent("Database")
        self.createDirectoryAtURLIfNeeded(databaseDirectoryURL)
        
        return databaseDirectoryURL
    }
}

public extension DatabaseManager
{
    func startWithCompletion(completionBlock: ((performingMigration: Bool) -> Void)?)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            
            let storeURL = DatabaseManager.databaseDirectoryURL.URLByAppendingPathComponent("Delta.sqlite")

            let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
            
            var performingMigration = false
            
            if let sourceMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStoreOfType(NSSQLiteStoreType, URL: storeURL, options: options),
                managedObjectModel = self.privateManagedObjectContext.persistentStoreCoordinator?.managedObjectModel
            {
                performingMigration = !managedObjectModel.isConfiguration(nil, compatibleWithStoreMetadata: sourceMetadata)
            }
            
            do
            {
                try self.privateManagedObjectContext.persistentStoreCoordinator?.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options)
            }
            catch let error as NSError
            {
                if error.code == NSMigrationMissingSourceModelError
                {
                    print("Migration failed. Try deleting \(storeURL)")
                }
                else
                {
                    print(error)
                }
                
                abort()
            }
            
            if let completionBlock = completionBlock
            {
                completionBlock(performingMigration: performingMigration)
            }
        }
    }
    
    // MARK: - Background Contexts -
    /// Background Contexts
    
    func backgroundManagedObjectContext() -> NSManagedObjectContext
    {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.parentContext = self.validationManagedObjectContext
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return managedObjectContext
    }
}

private extension DatabaseManager
{
    // MARK: - Saving -
    
    func save()
    {
        let backgroundTaskIdentifier = RSTBeginBackgroundTask("Save Database Task")
        
        self.validationManagedObjectContext.performBlockAndWait {
            
            do
            {
                try self.validationManagedObjectContext.save()
            }
            catch let error as NSError
            {
                print("Failed to save validation context:", error)
            }
            
            
            // Update main managed object context
            self.managedObjectContext.performBlockAndWait() {
                
                do
                {
                    try self.managedObjectContext.save()
                }
                catch let error as NSError
                {
                    print("Failed to save main context:", error)
                }
                
                
                // Save to disk
                self.privateManagedObjectContext.performBlock() {
                    
                    do
                    {
                        try self.privateManagedObjectContext.save()
                    }
                    catch let error as NSError
                    {
                        print("Failed to save private context to disk:", error)
                    }
                    
                    RSTEndBackgroundTask(backgroundTaskIdentifier)
                    
                }
                
            }
            
        }
    }
    
    // MARK: - Validation -
    
    func validateManagedObjectContextSave(managedObjectContext: NSManagedObjectContext)
    {
        
    }
    
    // MARK: - Notifications -
    
    @objc func managedObjectContextWillSave(notification: NSNotification)
    {
        guard let managedObjectContext = notification.object as? NSManagedObjectContext where managedObjectContext.parentContext == self.validationManagedObjectContext else { return }
        
        self.validationManagedObjectContext.performBlockAndWait {
            self.validateManagedObjectContextSave(managedObjectContext)
        }
    }
    
    @objc func managedObjectContextDidSave(notification: NSNotification)
    {
        guard let managedObjectContext = notification.object as? NSManagedObjectContext where managedObjectContext.parentContext == self.validationManagedObjectContext else { return }
        
        self.save()
    }
    
    // MARK: - File Management -
    
    class func createDirectoryAtURLIfNeeded(URL: NSURL)
    {
        do
        {
            try NSFileManager.defaultManager().createDirectoryAtURL(URL, withIntermediateDirectories: true, attributes: nil)
        }
        catch
        {
            print(error)
        }
    }
}