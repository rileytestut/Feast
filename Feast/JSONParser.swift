//
//  JSONParser.swift
//  Feast
//
//  Created by Riley Testut on 4/17/16.
//  Copyright © 2016 Spark SC. All rights reserved.
//

import Foundation
import CoreData

public typealias JSONObjectType = [String: AnyObject]
public typealias JSONArrayType = [[String: AnyObject]]

public protocol JSONParser
{
    associatedtype ManagedObject: NSManagedObject
    
    var managedObjectContext: NSManagedObjectContext { get }
    
    func parsedManagedObject(JSONObject object: JSONObjectType) -> ManagedObject
    func parsedManagedObjects(JSONArray array: JSONArrayType) -> [ManagedObject]
    
    func parsedJSONObject(managedObject managedObject: ManagedObject) -> JSONObjectType
    
    /* Private Use Only */
    func buildManagedObject(JSONObject object: JSONObjectType) -> ManagedObject
    func buildJSONObject(managedObject managedObject: ManagedObject) -> JSONObjectType
}

public extension JSONParser
{
    func parsedManagedObject(JSONObject object: JSONObjectType) -> ManagedObject
    {
        var parsedObject: ManagedObject! = nil
        
        self.managedObjectContext.performBlockAndWait {
            parsedObject = self.buildManagedObject(JSONObject: object)
        }
        
        return parsedObject
    }
    
    func parsedManagedObjects(JSONArray array: JSONArrayType) -> [ManagedObject]
    {
        var parsedObjects = [ManagedObject]()
        
        for object in array
        {
            let parsedObject = self.parsedManagedObject(JSONObject: object)
            parsedObjects.append(parsedObject)
        }
        
        return parsedObjects
    }
    
    func parsedJSONObject(managedObject managedObject: ManagedObject) -> JSONObjectType
    {
        var JSONObject: JSONObjectType!
        
        self.managedObjectContext.performBlockAndWait {
            JSONObject = self.buildJSONObject(managedObject: managedObject)
        }
        
        return JSONObject
    }
}

public extension JSONParser
{
    func buildJSONObject(managedObject managedObject: ManagedObject) -> JSONObjectType
    {
        // Optional. Only used when serializing model objects back into JSON
        
        var object = JSONObjectType()
        return object
    }
}