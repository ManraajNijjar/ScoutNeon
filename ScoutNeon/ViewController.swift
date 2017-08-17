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
    
    var loginId = ""

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

