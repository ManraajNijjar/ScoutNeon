//
//  BlockedUsers+CoreDataProperties.swift
//  
//
//  Created by Manraaj Nijjar on 10/15/17.
//
//

import Foundation
import CoreData


extension BlockedUsers {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BlockedUsers> {
        return NSFetchRequest<BlockedUsers>(entityName: "BlockedUsers")
    }

    @NSManaged public var blockedUsers: NSSet?

}

// MARK: Generated accessors for blockedUsers
extension BlockedUsers {

    @objc(addBlockedUsersObject:)
    @NSManaged public func addToBlockedUsers(_ value: User)

    @objc(removeBlockedUsersObject:)
    @NSManaged public func removeFromBlockedUsers(_ value: User)

    @objc(addBlockedUsers:)
    @NSManaged public func addToBlockedUsers(_ values: NSSet)

    @objc(removeBlockedUsers:)
    @NSManaged public func removeFromBlockedUsers(_ values: NSSet)

}
