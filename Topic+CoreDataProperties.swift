//
//  Topic+CoreDataProperties.swift
//  
//
//  Created by Manraaj Nijjar on 10/15/17.
//
//

import Foundation
import CoreData


extension Topic {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Topic> {
        return NSFetchRequest<Topic>(entityName: "Topic")
    }

    @NSManaged public var color: String?
    @NSManaged public var title: String?
    @NSManaged public var topicId: String?
    @NSManaged public var associateduser: Profile?

}
