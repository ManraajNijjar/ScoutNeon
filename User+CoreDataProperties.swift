//
//  User+CoreDataProperties.swift
//  
//
//  Created by Manraaj Nijjar on 10/15/17.
//
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var twitterId: String?
    @NSManaged public var blockedBy: Profile?

}
