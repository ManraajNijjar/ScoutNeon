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
    
    func newPost(username: String, topicTitle: String, topicMessage: String, color: String, latitude: Double, longitude: Double){
        //Generate the values for the database objects
        let postKey = ref?.child("Topics").childByAutoId()
        let messageKey = ref?.child("MessageList").childByAutoId()
        
        
        //Builds a list of topics with unique ids that contain the topic title mainly as a filler value
        ref?.child("TopicList").child((postKey?.key)!).setValue(["title": topicTitle])
        
        //Builds a list of messages with unique ids that contain reference to their associated topic
        ref?.child("MessageList").child((messageKey?.key)!).setValue(["topic": postKey?.key])
        
        //Builds the topic object with a unique name that contains the message list, location, and color
        ref?.child("Topic:"+(postKey?.key)!).setValue(["messageId": messageKey?.key, "latitude": latitude, "longitude": longitude, "color": color])
        
        //An object unique for each hex value that contains the topic key
        ref?.child("Hex:"+color).childByAutoId().setValue(["topic": postKey?.key])
        
        //The message object that contains the username and the message.
        ref?.child("Message:"+(messageKey?.key)!).setValue(["author": username, "text": topicMessage])
        
        print(postKey?.key)
    }
    
    func findPostsByHexAndLocation(colorHex: String, latitude: Double, longitude: Double, findPostsCompletionHandler: @escaping (_ postId: [String]) -> Void){
        var postArray = [String]()
        var postCount = 0
        var totalCount = 0
        ref?.child("Hex:"+colorHex).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            totalCount = (value?.count)!
            for (_, val) in value! {
                for (_, valTwo) in (val as? NSDictionary)! {
                    self.postInProximity(postKey: valTwo as! String, latitude: latitude, longitude: longitude, proximity: 0.002, postInProximityCompletionHandler: { (postStatus, postId) in
                        print("keepin on keeping on")
                        postCount = postCount + 1
                        if postStatus {
                            postArray.append(postId)
                        }
                        if postCount >= totalCount {
                            print("internally ran")
                            findPostsCompletionHandler(postArray)
                        }
                    })
                }
            }
            
            // ...
        }) { (error) in
            print(error.localizedDescription)
        }
        print("finished running")
        findPostsCompletionHandler(postArray)
    }
    
    func postInProximity(postKey: String, latitude: Double, longitude: Double, proximity: Double, postInProximityCompletionHandler: @escaping (_ postStatus: Bool, _ postId: String) -> Void){
        print("Topic:"+postKey)
        ref?.child("Topic:"+postKey).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            var latitudeInRange = true
            var longitudeInRange = true
            for (key, val) in value! {
                if (key as! String) == "latitude" {
                    let postLatitude = val as! Double
                    if postLatitude > latitude + proximity || postLatitude < latitude - proximity {
                        latitudeInRange = false
                    }
                }
                
                if (key as! String) == "longitude" {
                    let postLongitude = val as! Double
                    if postLongitude > longitude + proximity || postLongitude < longitude - proximity {
                        longitudeInRange = false
                    }
                }
            }
            if latitudeInRange && longitudeInRange {
                postInProximityCompletionHandler(true, postKey)
            } else {
                postInProximityCompletionHandler(false, postKey)
            }
            // ...
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    //Generate a Singleton instance of the TwitterAPIController
    class func sharedInstance() -> FirebaseController {
        struct Singleton {
            static var sharedInstance = FirebaseController()
        }
        return Singleton.sharedInstance
    }
}
