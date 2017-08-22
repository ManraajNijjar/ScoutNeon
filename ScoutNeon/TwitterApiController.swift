//
//  TwitterApiController.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 8/17/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import Foundation
import TwitterKit
import FirebaseAuth

class TwitterApiController {
    //Sets up the client with a guest connection at the start.
    var client = TWTRAPIClient()
    
    //Might need these methods later. Will keep them in until I know for certain they aren't necessary
    func generateLoginButton(completionHandlerForLogin: @escaping (_ session: TWTRSession?, _ error: NSError?) -> Void) -> TWTRLogInButton{
        return TWTRLogInButton(logInCompletion: completionHandlerForLogin as! TWTRLogInCompletion)
    }
    
    func generateLoginButtonWithTWTR(completionHandlerForLogin: @escaping TWTRLogInCompletion) -> TWTRLogInButton{
        return TWTRLogInButton(logInCompletion: completionHandlerForLogin)
    }
    
    func guestToUserClientSwitch(userID: String) {
        client = TWTRAPIClient(userID: userID)
    }
    
    func getUserData(userID: String, completionHandlerForUser: @escaping (_ userResult: TWTRUser?, _ error: Error?) -> Void){
        client.loadUser(withID: userID) { (user, error) -> Void in
            // handle the response or error
            if error == nil {
             completionHandlerForUser(user, nil)
            }
            
            if error != nil {
                print(error!)
                completionHandlerForUser(nil, error)
            }
        }
    }
    
    func getImageForUserID(userID: String, size: String, imageCompletionHandler: @escaping (_ userImage: UIImage?) -> Void) {
        
        getUserData(userID: userID) { (user, error) in
            if (error != nil) {
                imageCompletionHandler(nil)
            }
            if error == nil {
                if size == "Large" {
                    imageCompletionHandler(self.retrieveImageFromTwitter(imageURL: (user?.profileImageLargeURL)!))
                } else if size == "Mini" {
                    imageCompletionHandler(self.retrieveImageFromTwitter(imageURL: (user?.profileImageMiniURL)!))
                } else {
                    imageCompletionHandler(self.retrieveImageFromTwitter(imageURL: (user?.profileImageURL)!))
                }
            }
        }
    }
    
    func retrieveImageFromTwitter(imageURL: String) -> UIImage? {
        let photoURL = URL(string: imageURL)
        if let imageData = try? Data(contentsOf: photoURL!) {
            return UIImage(data:imageData as Data,scale:1.0)
        } else {
            return nil
        }
    }
    
    //Generate a Singleton instance of the TwitterAPIController
    class func sharedInstance() -> TwitterApiController {
        struct Singleton {
            static var sharedInstance = TwitterApiController()
        }
        return Singleton.sharedInstance
    }
}
