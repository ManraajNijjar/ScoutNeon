//
//  Profile+CoreDataProperties.swift
//  
//
//  Created by Manraaj Nijjar on 8/13/17.
//
//

import Foundation
import CoreData


extension Profile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Profile> {
        return NSFetchRequest<Profile>(entityName: "Profile")
    }

    @NSManaged public var anonymous: Bool
    @NSManaged public var color: String?
    @NSManaged public var username: String?
    @NSManaged public var profilepicture: NSData?
    @NSManaged public var favoritetopics: Topic?

}
