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
    
    let coreDataController = CoreDataController.sharedInstance()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let logInButton = TWTRLogInButton(logInCompletion: { session, error in
            if (session != nil) {
                print("signed in as \(String(describing: session?.userName))")
                let credentials = TwitterAuthProvider.credential(withToken: (session?.authToken)!, secret: (session?.authTokenSecret)!)
                Auth.auth().signIn(with: credentials, completion: {(user, error) in
                    if user != nil {
                        //Check for a corresponding core data user profile
                        self.coreDataController.getUserProfile(userID: user!.uid, completionHandler: { (success, userProfile) in
                            if success {
                                print("success")
                            }
                            if !success {
                                print("failure")
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
        logInButton.center = self.view.center
        self.view.addSubview(logInButton)
        
        
    }
    
    

}

