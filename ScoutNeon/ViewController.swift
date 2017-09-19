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
import ReachabilitySwift

class ViewController: UIViewController {
    
    //Pulls a singleton instance for the core data controller
    let coreDataController = CoreDataController.sharedInstance()
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let twitterAPI = TwitterApiController.sharedInstance()
    let errorController = ErrorAlertController()
    let reachability = Reachability()!
    
    //A variable that's to be setup and pulled in the segue
    var loginId = ""
    var firebaseId = ""
    var autoLog = true
    var loginAdded = false

    override func viewDidLoad() {
        super.viewDidLoad()
        //intilizes the login button this isn't placed in the API Controller as the actual Twitter connection elements are all contained within the TwitterKit library
        let logInButton = TWTRLogInButton(logInCompletion: { session, error in
            self.activityIndicator.startAnimating()
            if (session != nil) {
                self.completeLogin(session: session!)
            } else {
                print("error: \(String(describing: error?.localizedDescription))")
                self.activityIndicator.stopAnimating()
                self.errorController.displayAlert(title: "Connection Issue", message: "Sorry there was an issue connecting to Twitter Servers", view: self)
            }
        })
        
        //Places it in the center of the screen
        logInButton.center = CGPoint(x: self.view.center.x, y: (self.view.center.y * 1.55))
        
        
        let store = Twitter.sharedInstance().sessionStore
        if let session = store.session() {
            if autoLog {
                activityIndicator.startAnimating()
                completeLogin(session: session as! TWTRSession)
            }
        }
        
        reachability.whenReachable = { reachability in
            DispatchQueue.main.async {
                print("Hello")
                if self.loginAdded == false {
                    self.view.addSubview(logInButton)
                    self.loginAdded = true
                }
                logInButton.isEnabled = true
                
            }
        }
        reachability.whenUnreachable = { _ in
            self.errorController.displayAlert(title: "Connection Issue", message: "Sorry there was an issue connecting the internet", view: self)
            logInButton.isEnabled = false
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    func completeLogin(session: TWTRSession){
        self.loginId = (Twitter.sharedInstance().sessionStore.session()?.userID)!
        self.twitterAPI.guestToUserClientSwitch(userID: (Twitter.sharedInstance().sessionStore.session()?.userID)!)
        let credentials = TwitterAuthProvider.credential(withToken: (session.authToken), secret: (session.authTokenSecret))
        Auth.auth().signIn(with: credentials, completion: {(user, error) in
            if user != nil {
                //Check for a corresponding core data user profile
                self.coreDataController.getUserProfile(userID: user!.uid, completionHandler: { (success, userProfile) in
                    self.activityIndicator.stopAnimating()
                    self.firebaseId = user!.uid
                    //If one is found it succeeds
                    if success {
                        DispatchQueue.main.async { [unowned self] in
                            self.performSegue(withIdentifier: "MapSegue", sender: self)
                        }
                    }
                    //if one isn't found it fails and triggers the segue to the profile creation screen
                    if !success {
                        DispatchQueue.main.async { [unowned self] in
                            self.performSegue(withIdentifier: "SetupSegue", sender: self)
                        }
                    }
                })
                
            } else {
                print("error: \(String(describing: error?.localizedDescription))")
                self.activityIndicator.stopAnimating()
                self.errorController.displayAlert(title: "Connection Issue", message: "Sorry there was an issue connecting to Google Servers", view: self)
            }
        })
    }
    
    @IBAction func unwindToLoginView(segue:UIStoryboardSegue) {
        
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SetupSegue" {
            let viewController = segue.destination as! AccountSetupViewController
            viewController.userIDFromLogin = loginId
            viewController.firebaseIDFromLogin = firebaseId
        }
        
        if segue.identifier == "MapSegue" {
            let destinationNavigationController = segue.destination as! UINavigationController
            let targetController = destinationNavigationController.topViewController as! MapViewController
            targetController.userIDForProfile = firebaseId
        }
    }

}

