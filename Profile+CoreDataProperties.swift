//
//  Profile+CoreDataProperties.swift
//  
//
//  Created by Manraaj Nijjar on 8/27/17.
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
    @NSManaged public var id: String?
    @NSManaged public var profilepicture: NSData?
    @NSManaged public var username: String?
    @NSManaged public var twitterid: String?
    @NSManaged public var favoritetopics: Topic?

}
