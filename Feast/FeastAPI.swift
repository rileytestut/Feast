//
//  FeastAPI.swift
//  Feast
//
//  Created by Riley Testut on 4/17/16.
//  Copyright © 2016 Spark SC. All rights reserved.
//

import Foundation
import Alamofire

public class FeastAPI
{
    public static let sharedAPI = FeastAPI()
    
    internal let baseURL = "https://uscdata.org/eats/v1"
    
    private init()
    {
        
    }
}

public extension FeastAPI
{
    func fetchRestaurants(completion: ([Restaurant]?, NSError?) -> Void)
    {
        let URL = self.baseURL + "/restaurants"
        
        Alamofire.request(.GET, URL).validate().responseJSON { (response) in
                        
            guard let JSON = response.result.value as? JSONObjectType else {
                completion(nil, response.result.error)
                return
            }
            
            let managedObjectContext = DatabaseManager.sharedManager.backgroundManagedObjectContext()
            
            let parser = RestaurantParser(managedObjectContext: managedObjectContext)
            
            let array = JSON["_items"] as! JSONArrayType
            let restaurants = parser.parsedManagedObjects(JSONArray: array)
            
            managedObjectContext.performBlock({ 
                completion(restaurants, nil)
            })
        }
    }
}