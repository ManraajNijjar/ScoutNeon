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
    
    //Setup controllers
    let coreDataController = CoreDataController.sharedInstance
    let twitterAPI = TwitterApiController.sharedInstance
    let errorController = ErrorAlertController()
    let reachability = Reachability()!
    
    //Pulls the activity indicator from the view
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    //Used to transfer information between ViewControllers
    //Stored here to be transferred during Segue
    private var loginIdFromTwitter = ""
    private var loginIdFromFirebase = ""
    
    
    //Checks to see whether or not to auto login accounts
    //Used so that if a User logs out but there's another session stored it doesn't Autolog them into that account
    //Should never happen but guards against that case
    var automaticLoginEnabled = true
    
    //Tracks whether the loginButton has been added through the reachability container. Could maybe be replaced by an optional
    var loginButtonAdded = false

    override func viewDidLoad() {
        super.viewDidLoad()
        //intilizes the login button this isn't placed in the API Controller as the actual Twitter connection elements are all contained within the TwitterKit library
        let logInButton = TWTRLogInButton(logInCompletion: { session, error in
            self.activityIndicator.startAnimating()
            
            //Handles the two cases upon completing the Login from the Twitter Bubbont
            if (session != nil) {
                self.completeLogin(session: session!)
            } else {
                print("error: \(String(describing: error?.localizedDescription))")
                self.activityIndicator.stopAnimating()
                self.errorController.displayAlert(title: "Connection Issue", message: "Sorry there was an issue connecting to Twitter Servers", view: self)
            }
        })
        logInButton.center = CGPoint(x: self.view.center.x, y: (self.view.center.y * 1.55))
        
        //Attempts to automatically login if
        let store = Twitter.sharedInstance().sessionStore
        if let session = store.session() {
            if automaticLoginEnabled {
                activityIndicator.startAnimating()
                completeLogin(session: session as! TWTRSession)
            }
        }
        
        //Creates a listener that places the LoginButton if there's an active internet connection and enables it
        reachability.whenReachable = { reachability in
            DispatchQueue.main.async {
                if self.loginButtonAdded == false {
                    self.view.addSubview(logInButton)
                    self.loginButtonAdded = true
                }
                logInButton.isEnabled = true
            }
        }
        
        //A listener that displays an alert letting the user know if there's issues 
        //with their connection as well as disabling the login button
        reachability.whenUnreachable = { _ in
            self.errorController.displayAlert(title: "Connection Issue", message: "Sorry there was an issue connecting the internet", view: self)
            logInButton.isEnabled = false
        }
        
        //Starts the lisners
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    func completeLogin(session: TWTRSession){
        //Pulls the login ID from the Twitter instance
        self.loginIdFromTwitter = (Twitter.sharedInstance().sessionStore.session()?.userID)!
                
        //Sets up the Twitter API to use the Users's session token
        self.twitterAPI.guestToUserClientSwitch(userID: (Twitter.sharedInstance().sessionStore.session()?.userID)!)
        
        //Creates the credential's object for Firebase
        let credentials = TwitterAuthProvider.credential(withToken: (session.authToken), secret: (session.authTokenSecret))
        
        //Attempts to login with Firebase
        Auth.auth().signIn(with: credentials, completion: {(user, error) in
            if user != nil {
                //Check for a corresponding core data user profile and then goes straight to the Map View if it's there
                //SetupView if it's not
                self.coreDataController.getUserProfile(userID: user!.uid, completionHandler: { (success, userProfile) in
                    self.activityIndicator.stopAnimating()
                    self.loginIdFromFirebase = user!.uid
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
                //Prints error if Firebase login fails
                print("error: \(String(describing: error?.localizedDescription))")
                self.activityIndicator.stopAnimating()
                self.errorController.displayAlert(title: "Connection Issue", message: "Sorry there was an issue connecting to Google Servers", view: self)
            }
        })
    }
    
    
    //Allows for unwind segues to this controller. Used in the MapView and the CreditsView
    @IBAction func unwindToLoginView(segue:UIStoryboardSegue) {
        
    }
    //Segues to the CreditsView
    @IBAction func creditsPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "CreditsSegue", sender: self)
        
    }
    
    
    //Controls data flows for the two segues that need them
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SetupSegue" {
            let viewController = segue.destination as! AccountSetupViewController
            viewController.userIDFromLogin = loginIdFromTwitter
            viewController.firebaseIDFromLogin = loginIdFromFirebase
        }
        
        if segue.identifier == "MapSegue" {
            let destinationNavigationController = segue.destination as! UINavigationController
            let targetController = destinationNavigationController.topViewController as! MapViewController
            targetController.userIDForProfile = loginIdFromFirebase
            targetController.fromLogin = true
        }
    }

}

