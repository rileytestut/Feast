// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Restaurant.swift instead.

import Foundation
import CoreData

public enum RestaurantAttributes: String 
{
    case identifier
    case index
    case location
    case name
}

public class _Restaurant: NSManagedObject 
{

    // MARK: - Properties

    @NSManaged public var identifier: String

    @NSManaged public var index: Int16

    @NSManaged public var location: CLLocation?

    @NSManaged public var name: String

}

