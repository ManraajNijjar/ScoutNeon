//
//  FirebaseController.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 8/27/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import Foundation
import FirebaseDatabase

class FirebaseController {
    var ref:DatabaseReference?
    
    init() {
        ref = Database.database().reference()
    }
    
    func createUser(userProfile: Profile) {
        ref?.child("Users").child(userProfile.id!).setValue(["username": userProfile.username!, "twitterId": userProfile.twitterid!])
    }
    
    func userExists(userId: String) -> Bool {
        let users = ref?.child("Users").queryEqual(toValue: userId)
        ref?.child("Users").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            print(value)
            
            // ...
        }) { (error) in
            print(error.localizedDescription)
        }
        
        return false
    }
    
    //Generate a Singleton instance of the TwitterAPIController
    class func sharedInstance() -> FirebaseController {
        struct Singleton {
            static var sharedInstance = FirebaseController()
        }
        return Singleton.sharedInstance
    }
}
