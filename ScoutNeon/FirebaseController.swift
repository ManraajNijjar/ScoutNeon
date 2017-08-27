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
        ref?.child("Users").child(userProfile.id!).setValue(["username": userProfile.username!, "twitterId": userProfile.twitterid!, "profilePicture": userProfile.profilepicture!])
    }
    
    func userExists(userId: String) -> Bool {
        let users = ref?.child("Users").queryEqual(toValue: userId)
        
        return false
    }
}
