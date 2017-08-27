//
//  Topic+CoreDataProperties.swift
//  
//
//  Created by Manraaj Nijjar on 8/27/17.
//
//

import Foundation
import CoreData


extension Topic {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Topic> {
        return NSFetchRequest<Topic>(entityName: "Topic")
    }

    @NSManaged public var topicId: String?
    @NSManaged public var associateduser: Profile?

}
