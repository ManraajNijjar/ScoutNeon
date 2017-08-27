//
//  CoreDataController.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 8/15/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class CoreDataController {
    
    class func getContext() -> NSManagedObjectContext {
        return CoreDataController.persistentContainer.viewContext
    }

    static var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "ScoutNeon")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    
    //Checks to see if there is an associated userprofile and either returns yes with the profile or no with nothing
    func getUserProfile(userID: String, completionHandler: @escaping (_ success: Bool, _ userProfile: Profile?) -> Void){
        
        var profilesFromFetch = [Profile]()
        let fetchRequest: NSFetchRequest<Profile> = Profile.fetchRequest()
        do {
            let profileList = try CoreDataController.getContext().fetch(fetchRequest)
            profilesFromFetch = profileList.filter{$0.id == userID}
        } catch {
            print(error)
        }
        
        if(profilesFromFetch.count == 0){
            completionHandler(false, nil)
        }
        if(profilesFromFetch.count >= 1){
            completionHandler(true, profilesFromFetch.first)
        }
    }
    
    func createUserProfile(twitterId: String, firebaseId: String, profileImage: UIImage, username: String, color: String, anonymous: Bool) -> Profile {
        let profile: Profile = NSEntityDescription.insertNewObject(forEntityName: "Profile", into: CoreDataController.getContext()) as! Profile
        
        profile.twitterid = twitterId
        profile.id = firebaseId
        profile.profilepicture = UIImagePNGRepresentation(profileImage) as NSData?
        profile.username = username
        profile.color = color
        profile.anonymous = anonymous
        
        return profile
    }
    
    
    class func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    //Generate a Singleton instance of the CoreDataController
    class func sharedInstance() -> CoreDataController {
        struct Singleton {
            static var sharedInstance = CoreDataController()
        }
        return Singleton.sharedInstance
    }
}
