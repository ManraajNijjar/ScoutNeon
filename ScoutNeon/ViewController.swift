//
//  ViewController.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 8/9/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import UIKit
import TwitterKit
import FirebaseAuth

class ViewController: UIViewController {
    
    //Pulls a singleton instance for the core data controller
    let coreDataController = CoreDataController.sharedInstance()
    
    let twitterAPI = TwitterApiController.sharedInstance()
    //A variable that's to be setup and pulled in the segue
    var loginId = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //intilizes the login button this isn't placed in the API Controller as the actual Twitter connection elements are all contained within the TwitterKit library
        let logInButton = TWTRLogInButton(logInCompletion: { session, error in
            if (session != nil) {
                
                //Should use this for the username
                print("signed in as \(String(describing: session?.userName))")
                print(Twitter.sharedInstance().sessionStore.session()?.userID)
                self.twitterAPI.guestToUserClientSwitch(userID: (Twitter.sharedInstance().sessionStore.session()?.userID)!)
                let credentials = TwitterAuthProvider.credential(withToken: (session?.authToken)!, secret: (session?.authTokenSecret)!)
                Auth.auth().signIn(with: credentials, completion: {(user, error) in
                    if user != nil {
                        //Check for a corresponding core data user profile
                        self.coreDataController.getUserProfile(userID: user!.uid, completionHandler: { (success, userProfile) in
                            //If one is found it succeeds
                            if success {
                                print("success")
                            }
                            //if one isn't found it fails and triggers the segue to the profile creation screen
                            if !success {
                                print("failure")
                                self.loginId = user!.uid
                                DispatchQueue.main.async { [unowned self] in
                                    self.performSegue(withIdentifier: "SetupSegue", sender: self)
                                }
                            }
                        })
                        
                    } else {
                        print("error: \(String(describing: error?.localizedDescription))")
                    }
                })
                
            } else {
                print("error: \(String(describing: error?.localizedDescription))")
            }
        })
        
        //Places it in the center of the screen
        logInButton.center = self.view.center
        self.view.addSubview(logInButton)
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SetupSegue" {
            let viewController = segue.destination as! AccountSetupViewController
            viewController.userIDFromLogin = loginId
        }
    }

}

