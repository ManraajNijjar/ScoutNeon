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
    
    func userExists(userId: String, userExistsCompletionHandler: @escaping (_ userStatus: Bool) -> Void){
        
        //ref?.child("Users").queryOrderedByKey()
        
        ref?.child("Users").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            if((value?.count)! > 0) {
                var userCheck = false
                //Goes through each value for the user and processes each to check if has a similar username
                //This was done because it was too far along to change the data structure
                for (_, val) in value! {
                    for (keyTwo, valTwo) in (val as? NSDictionary)! {
                        if (keyTwo as! String) == "username" {
                            if (valTwo as! String) == userId {
                                userCheck = true
                            }
                        }
                    }
                }
                userExistsCompletionHandler(userCheck)
            } else {
                userExistsCompletionHandler(false)
            }
            // ...
        }) { (error) in
            print(error.localizedDescription)
        }
        
    }
    
    func newPost(){
        let postKey = ref?.child("Topics").childByAutoId()
        ref?.child("Topics").child((postKey?.key)!).setValue(["blank": "value"])
        
        print(postKey?.key)
    }
    
    //Generate a Singleton instance of the TwitterAPIController
    class func sharedInstance() -> FirebaseController {
        struct Singleton {
            static var sharedInstance = FirebaseController()
        }
        return Singleton.sharedInstance
    }
}
