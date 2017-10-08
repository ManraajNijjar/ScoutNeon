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
    
    static let sharedInstance = FirebaseController()
    
    var ref:DatabaseReference?
    
    let errorController = ErrorAlertController()
    
    
    //Manages the rate limit on new posts from the user
    private var timeOfLastDatabaseInsert = Date()
    private var timeOfLastDatabaseQuery = Date()
    private var minimumTimeBetweenInserts: Double = 0
    private var minimumTimeBetweenQueries: Double = 0
    
    
    init() {
        ref = Database.database().reference()
    }
    
    //Used for removing the listener when exiting the MessageTableView
    func getRef() -> DatabaseReference? {
        return ref
    }
    
    //Prevents users from posting too frequently by enforcing a time limit
    func enforceNewPostRateLimit() -> Bool {
        let currentTimeForNewPost = Date()
        if currentTimeForNewPost.timeIntervalSince(timeOfLastDatabaseInsert) >= minimumTimeBetweenInserts {
            //If this is the first interaction between the user and Firebase we don't want to limit that so
            //we create the actual time limit here
            minimumTimeBetweenInserts = 20
            
            timeOfLastDatabaseInsert = currentTimeForNewPost
            return true
        } else {
            return false
        }
    }
    
    //Prevents users from searching too frequently by enforcing a time limit
    func enforcePostSearchLimit() -> Bool {
        let currentTimeForNewSearch = Date()
        if currentTimeForNewSearch.timeIntervalSince(timeOfLastDatabaseQuery) >= minimumTimeBetweenQueries {
            //If this is the first interaction between the user and Firebase we don't want to limit that so
            //we create the actual time limit here
            minimumTimeBetweenQueries = 6
            
            timeOfLastDatabaseQuery = currentTimeForNewSearch
            return true
        } else {
            return false
        }
    }
    
    func createNewUserOnFirebase(userProfile: Profile, baseView: UIViewController) {
        
        ref?.child("Users").child(userProfile.id!).setValue(["username": userProfile.username!, "twitterId": userProfile.twitterid!], withCompletionBlock: { (error, ref) in
            
            if (error != nil) {
                self.errorController.displayAlert(title: "DB Issue", message: "There was an error creating your account", view: baseView)
            }
            
        })
    }
    
    func createNewTopicPostOnFirebase(dictionaryOfNewPostValues: [String: Any], baseView: UIViewController, completionHandler: @escaping (_ gotDelayed: Bool) -> Void){
        
        //Used to indicate if the post happened immediately or the listener had to wait
        var postWasDelayedStatus = false
        
        //Reference to the view this was pulled from to manipulate it's activity indicator
        let newPostViewController = baseView as! NewPostViewController
        
        //Checks if the connection to Firebase is active
        let connectionToFirebaseServers = Database.database().reference(withPath: ".info/connected")
        
        connectionToFirebaseServers.observe(.value, with: { snapshot in
            if let connected = snapshot.value as? Bool, connected {
                
                //Pull keys for a new post and message from Firebase
                let postKey = self.ref?.child("Topics").childByAutoId().key
                let messageKey = self.ref?.child("UsedKeys").childByAutoId().key
                
                //Instantiate each object from the dictionary
                let newPostUsername = dictionaryOfNewPostValues["username"] as! String
                let newPostTwitterID = dictionaryOfNewPostValues["twitterID"] as! String
                let newPostTopicTitle = dictionaryOfNewPostValues["topicTitle"] as! String
                let newPostTopicMessage = dictionaryOfNewPostValues["topicMessage"] as! String
                let newPostColor = dictionaryOfNewPostValues["color"] as! String
                
                let newPostLatitude = dictionaryOfNewPostValues["latitude"] as! Double
                let newPostLongitude = dictionaryOfNewPostValues["longitude"] as! Double
                
                
                //Builds a list of used MessageKeys
                self.ref?.child("UsedKeys").child((messageKey)!).setValue(["used": true])
                
                //Builds a list of topics with unique ids that contain the topic title mainly as a filler value
                self.ref?.child("TopicList").child((postKey)!).setValue(["title": newPostTopicTitle])
                
                //Builds a list of messages with unique ids that contain reference to their associated topic
                self.ref?.child("MessageList").child((postKey)!).child((messageKey)!).setValue(["messagekey": messageKey])
                
                //Builds the topic object with a unique name that contains the message list, location, and color
                self.ref?.child("Topic:"+(postKey)!).setValue(["messageId": messageKey!, "latitude": newPostLatitude, "longitude": newPostLongitude, "color": newPostColor, "title" : newPostTopicTitle, "author": newPostUsername, "twitterID": newPostTwitterID, "filtered": false])
                
                //An object unique for each hex value that contains the topic key
                self.ref?.child("Hex:"+newPostColor).childByAutoId().setValue(["topic": postKey])
                
                //The message object that contains the username and the message.
                self.ref?.child("Message:"+messageKey!).setValue(["author": newPostUsername, "twitterID": newPostTwitterID,"text": newPostTopicMessage])
                
                newPostViewController.activityIndicator.stopAnimating()
                
                connectionToFirebaseServers.cancelDisconnectOperations()
                connectionToFirebaseServers.removeAllObservers()
                
                completionHandler(postWasDelayedStatus)
                
            } else {
                self.errorController.displayAlert(title: "Connection Issue", message: "We will keep trying to send your post, if you leave this page your post will still be sent but you won't be notified", view: baseView)
                postWasDelayedStatus = true
                newPostViewController.activityIndicator.stopAnimating()
            }
        })
        
    }
    
    func createMessageOnFirebase(dictionaryOfNewMessageValues: [String: String], baseView: UIViewController){
        let messageKey = ref?.child("UsedKeys").childByAutoId().key
        let postView = baseView as! MessageTableViewController
        
        let newMessageUsername = dictionaryOfNewMessageValues["username"]
        let newMessageTwitterID = dictionaryOfNewMessageValues["twitterID"]
        let newMessageTextValue = dictionaryOfNewMessageValues["messageValueString"]
        let newMessagePostId = dictionaryOfNewMessageValues["postId"]
        
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if let connected = snapshot.value as? Bool, connected {
                postView.activityIndicator.stopAnimating()
                self.ref?.child("MessageList").child(newMessagePostId!).observeSingleEvent(of: .value, with: { (snapshot) in
                    _ = snapshot.value as? NSDictionary
                    let messageTitleString = messageKey
                    self.ref?.child("MessageList").child(newMessagePostId!).child((messageKey)!).setValue(["messagekey": messageKey])
                    self.ref?.child("Message:"+(messageKey)!).setValue(["author": newMessageUsername, "text": newMessageTextValue, "twitterId": newMessageTwitterID])
                })
                connectedRef.cancelDisconnectOperations()
                connectedRef.removeAllObservers()
            } else {
                
                self.errorController.displayAlert(title: "Connection Issue", message: "Please try sending your message again later", view: baseView)
                postView.activityIndicator.stopAnimating()
                connectedRef.removeAllObservers()
            }
        })
        
    }
    
    
    /*func newMessage(postId: String, messageValueString: String, author: String, baseView: UIViewController){
        let messageKey = ref?.child("UsedKeys").childByAutoId()
        let postView = baseView as! MessageTableViewController
        
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if let connected = snapshot.value as? Bool, connected {
                postView.activityIndicator.stopAnimating()
                self.ref?.child("MessageList").child(postId).observeSingleEvent(of: .value, with: { (snapshot) in
                    _ = snapshot.value as? NSDictionary
                    let messageTitleString = messageKey?.key as! String
                    self.ref?.child("MessageList").child(postId).child((messageKey?.key)!).setValue(["messagekey": messageKey?.key])
                    self.ref?.child("Message:"+(messageKey?.key)!).setValue(["author": author, "text": messageValueString])
                })
                connectedRef.cancelDisconnectOperations()
                connectedRef.removeAllObservers()
            } else {
                
                self.errorController.displayAlert(title: "Connection Issue", message: "Please try sending your message again later", view: baseView)
                postView.activityIndicator.stopAnimating()
                connectedRef.removeAllObservers()
            }
        })
        
    }*/
    
    func findPostsByHexAndLocation(colorHex: String, latitude: Double, longitude: Double, baseView: UIViewController, findPostsCompletionHandler: @escaping (_ postId: [[String:Any]]) -> Void){
        
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if let connected = snapshot.value as? Bool, connected {
                print("Connected")
                var postArray = [String]()
                var postDictionary = [[String:Any]]()
                var postCount = 0
                var totalCount = 0
                self.ref?.child("Hex:"+colorHex).observeSingleEvent(of: .value, with: { (snapshot) in
                    // Get user value
                    let value = snapshot.value as? NSDictionary
                    if (value != nil) {
                        totalCount = (value?.count)!
                        for (_, val) in value! {
                            for (_, valTwo) in (val as? NSDictionary)! {
                                self.postInProximity(postKey: valTwo as! String, latitude: latitude, longitude: longitude, proximity: 0.01, postInProximityCompletionHandler: { (postStatus, postId, author, title, latitude, longitude) in
                                    postCount = postCount + 1
                                    if postStatus {
                                        postArray.append(postId)
                                        postDictionary.append(["postID": postId, "author": author, "title": title, "latitude": latitude, "longitude": longitude])
                                    }
                                    if postCount >= totalCount {
                                        findPostsCompletionHandler(postDictionary)
                                    }
                                })
                            }
                        }
                    } else {
                        let mapView = baseView as! MapViewController
                        mapView.activityIndicator.stopAnimating()
                        mapView.mainMapView.removeAnnotations(mapView.mainMapView.annotations)
                        print("No posts")
                    }
                    
                    // ...
                }) { (error) in
                    print(error.localizedDescription)
                    self.errorController.displayAlert(title: "Connection Issue", message: "There was an error connecting to our Databases", view: baseView)
                }
                connectedRef.cancelDisconnectOperations()
                connectedRef.removeAllObservers()
            } else {
                print("Not connected")
                let mapView = baseView as! MapViewController
                mapView.activityIndicator.stopAnimating()
                self.errorController.displayAlert(title: "Connection Issue", message: "There seems to be an issue with your connection", view: baseView)
                connectedRef.removeAllObservers()
            }
        })
    }
    
    func postInProximity(postKey: String, latitude: Double, longitude: Double, proximity: Double, postInProximityCompletionHandler: @escaping (_ postStatus: Bool, _ postId: String, _ author: String, _ title: String, _ latitude: Double, _ longitude: Double) -> Void){
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
    
    func messageForPostID(postID: String, baseView: UIViewController, messageForPostCompletionHandler: @escaping (_ messageList: [[String: String]]) -> Void){
        var messageDictArray = [[String: String]]()
        var messageCount = 0
        var totalCount = 0
        
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if let connected = snapshot.value as? Bool, connected {
                print("Connected")
                self.ref?.child("MessageList").child(postID).observeSingleEvent(of: .value, with: { (snapshot) in
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
                connectedRef.cancelDisconnectOperations()
                connectedRef.removeAllObservers()
            } else {
                print("Not connected")
                let mapView = baseView as! MapViewController
                mapView.activityIndicator.stopAnimating()
                self.errorController.displayAlert(title: "Connection Issue", message: "There was an error connecting to our Databases", view: baseView)
                connectedRef.removeAllObservers()
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
}
