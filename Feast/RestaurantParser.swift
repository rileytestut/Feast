//
//  RestaurantParser.swift
//  Feast
//
//  Created by Riley Testut on 4/17/16.
//  Copyright © 2016 Spark SC. All rights reserved.
//

import Foundation
import CoreData

internal class RestaurantParser: JSONParser
{
    typealias ManagedObject = Restaurant
    
    public let managedObjectContext: NSManagedObjectContext
    
    public init(managedObjectContext: NSManagedObjectContext)
    {
        self.managedObjectContext = managedObjectContext
    }
    
    func buildManagedObject(JSONObject object: JSONObjectType) -> Restaurant
    {
        let restaurant = Restaurant.insertIntoManagedObjectContext(self.managedObjectContext)
        restaurant.identifier = object["_id"] as! String
        restaurant.name = object["name"] as! String
        
        return restaurant
    }
}