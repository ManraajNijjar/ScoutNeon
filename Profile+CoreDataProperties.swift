//
//  Profile+CoreDataProperties.swift
//  
//
//  Created by Manraaj Nijjar on 9/14/17.
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
    @NSManaged public var twitterid: String?
    @NSManaged public var username: String?
    @NSManaged public var favoritetopics: NSSet?

}

// MARK: Generated accessors for favoritetopics
extension Profile {

    @objc(addFavoritetopicsObject:)
    @NSManaged public func addToFavoritetopics(_ value: Topic)

    @objc(removeFavoritetopicsObject:)
    @NSManaged public func removeFromFavoritetopics(_ value: Topic)

    @objc(addFavoritetopics:)
    @NSManaged public func addToFavoritetopics(_ values: NSSet)

    @objc(removeFavoritetopics:)
    @NSManaged public func removeFromFavoritetopics(_ values: NSSet)

}
