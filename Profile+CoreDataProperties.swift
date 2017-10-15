//
//  Profile+CoreDataProperties.swift
//  
//
//  Created by Manraaj Nijjar on 10/15/17.
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
    @NSManaged public var blockedUsers: NSSet?

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

// MARK: Generated accessors for blockedUsers
extension Profile {

    @objc(addBlockedUsersObject:)
    @NSManaged public func addToBlockedUsers(_ value: User)

    @objc(removeBlockedUsersObject:)
    @NSManaged public func removeFromBlockedUsers(_ value: User)

    @objc(addBlockedUsers:)
    @NSManaged public func addToBlockedUsers(_ values: NSSet)

    @objc(removeBlockedUsers:)
    @NSManaged public func removeFromBlockedUsers(_ values: NSSet)

}
