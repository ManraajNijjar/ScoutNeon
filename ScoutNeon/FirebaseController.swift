//
//  FirebaseController.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 8/27/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import Foundation
import FirebaseDatabase
import UIKit

class FirebaseController {
    var ref:DatabaseReference?
    
    var lastDbInteraction = Date()
    var lastScout = Date()
    
    init() {
        ref = Database.database().reference()
    }
    
    func getRef() -> DatabaseReference? {
        return ref
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
    
    func rateLimitPosts() -> Bool {
        let currentTime = Date()
        if currentTime.timeIntervalSince(lastDbInteraction) >= 60 {
            lastDbInteraction = currentTime
            return true
        } else {
            return false
        }
    }
    
    func rateLimitScouts() -> Bool {
        let currentTime = Date()
        if currentTime.timeIntervalSince(lastScout) >= 6 {
            lastScout = currentTime
            return true
        } else {
            return false
        }
    }
    
    func newPost(username: String, topicTitle: String, topicMessage: String, color: String, latitude: Double, longitude: Double){
        //Generate the values for the database objects
        let postKey = ref?.child("Topics").childByAutoId()
        let messageKey = ref?.child("UsedKeys").childByAutoId()
        
        
        //Builds a list of used MessageKeys
        ref?.child("UsedKeys").child((messageKey?.key)!).setValue(["used": true])
        
        //Builds a list of topics with unique ids that contain the topic title mainly as a filler value
        ref?.child("TopicList").child((postKey?.key)!).setValue(["title": topicTitle])
        
        //Builds a list of messages with unique ids that contain reference to their associated topic
        ref?.child("MessageList").child((postKey?.key)!).child((messageKey?.key)!).setValue(["messagekey": messageKey?.key])
        
        //Builds the topic object with a unique name that contains the message list, location, and color
        ref?.child("Topic:"+(postKey?.key)!).setValue(["messageId": messageKey?.key, "latitude": latitude, "longitude": longitude, "color": color, "title" : topicTitle, "author": username])
        
        //An object unique for each hex value that contains the topic key
        ref?.child("Hex:"+color).childByAutoId().setValue(["topic": postKey?.key])
        
        //The message object that contains the username and the message.
        ref?.child("Message:"+(messageKey?.key)!).setValue(["author": username, "text": topicMessage])
        
        
        print(postKey?.key)
    }
    
    func newMessage(postId: String, messageValueString: String, author: String){
        let messageKey = ref?.child("UsedKeys").childByAutoId()
        
        ref?.child("MessageList").child(postId).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let messageTitleString = messageKey?.key as! String
            self.ref?.child("MessageList").child(postId).child((messageKey?.key)!).setValue(["messagekey": messageKey?.key])
            self.ref?.child("Message:"+(messageKey?.key)!).setValue(["author": author, "text": messageValueString])
        })
        
    }
    
    func findPostsByHexAndLocation(colorHex: String, latitude: Double, longitude: Double, findPostsCompletionHandler: @escaping (_ postId: [[String:Any]]) -> Void){
        var postArray = [String]()
        var postDictionary = [[String:Any]]()
        var postCount = 0
        var totalCount = 0
        ref?.child("Hex:"+colorHex).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            if (value != nil) {
                totalCount = (value?.count)!
                for (_, val) in value! {
                    for (_, valTwo) in (val as? NSDictionary)! {
                        self.postInProximity(postKey: valTwo as! String, latitude: latitude, longitude: longitude, proximity: 0.01, postInProximityCompletionHandler: { (postStatus, postId, author, title, latitude, longitude) in
                            print("keepin on keeping on")
                            postCount = postCount + 1
                            if postStatus {
                                postArray.append(postId)
                                postDictionary.append(["postID": postId, "author": author, "title": title, "latitude": latitude, "longitude": longitude])
                            }
                            if postCount >= totalCount {
                                print("internally ran")
                                findPostsCompletionHandler(postDictionary)
                            }
                        })
                    }
                }
            } else {
                print("No posts")
            }
            
            // ...
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func postInProximity(postKey: String, latitude: Double, longitude: Double, proximity: Double, postInProximityCompletionHandler: @escaping (_ postStatus: Bool, _ postId: String, _ author: String, _ title: String, _ latitude: Double, _ longitude: Double) -> Void){
        print("Topic:"+postKey)
        ref?.child("Topic:"+postKey).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            var latitudeInRange = true
            var longitudeInRange = true
            var postLatitude:Double = 0
            var postLongitude:Double = 0
            var author = ""
            var title = ""
            for (key, val) in value! {
                if (key as! String) == "author" {
                    author = val as! String
                }
                if (key as! String) == "title" {
                    title = val as! String
                }
                if (key as! String) == "latitude" {
                    postLatitude = val as! Double
                    if postLatitude > latitude + proximity || postLatitude < latitude - proximity {
                        latitudeInRange = false
                    }
                }
                if (key as! String) == "longitude" {
                    postLongitude = val as! Double
                    if postLongitude > longitude + proximity || postLongitude < longitude - proximity {
                        longitudeInRange = false
                    }
                }
            }
            if latitudeInRange && longitudeInRange {
                postInProximityCompletionHandler(true, postKey, author, title, postLatitude, postLongitude)
            } else {
                postInProximityCompletionHandler(false, postKey, author, title, postLatitude, postLongitude)
            }
            // ...
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func messageForPostID(postID: String, messageForPostCompletionHandler: @escaping (_ messageList: [[String: String]]) -> Void){
        var messageDictArray = [[String: String]]()
        var messageCount = 0
        var totalCount = 0
        ref?.child("MessageList").child(postID).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            totalCount = (value?.count)!
            
            for (key, _) in value! {
                self.retrieveMessageContents(messageID: key as! String, messageContentsCompletionHandler: { (messageContents) in
                    messageDictArray.append(messageContents)
                    messageCount = messageCount + 1
                    if messageCount >= totalCount {
                        messageForPostCompletionHandler(messageDictArray)
                    }
                })
            }
        })
    }

    
    func retrieveMessageContents(messageID: String, messageContentsCompletionHandler: @escaping (_ messageContents: [String: String]) -> Void){
        ref?.child("Message:"+messageID).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            var tempMessageDict = [String: String]()
            for (key, val) in value! {
                if key as! String == "author" {
                  tempMessageDict["author"] = val as! String
                }
                if key as! String == "text" {
                    tempMessageDict["text"] = val as! String
                }
            }
            messageContentsCompletionHandler(tempMessageDict)
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func messageListener(postId: String, messageTableView: MessageTableViewController) -> UInt{
        var messageDictArray = [[String: String]]()
        var messageCount = 0
        var totalCount = 0
        let listener = ref?.child("MessageList").child(postId).observe(.childAdded, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            print("observertriggered")
            totalCount = (value?.count)!
            for (_,key) in value! {
                self.retrieveMessageContents(messageID: key as! String, messageContentsCompletionHandler: { (messageContents) in
                    messageDictArray.append(messageContents)
                    messageCount = messageCount + 1
                    if messageCount >= totalCount {
                        messageTableView.messages = messageDictArray
                        DispatchQueue.main.async {
                            messageTableView.tableView.reloadData()
                        }
                    }
                })
            }
        })
        return listener!
    }
    
    func detachListeners(){
        ref?.removeAllObservers()
    }
    
    //Generate a Singleton instance of the TwitterAPIController
    class func sharedInstance() -> FirebaseController {
        struct Singleton {
            static var sharedInstance = FirebaseController()
        }
        return Singleton.sharedInstance
    }
}
