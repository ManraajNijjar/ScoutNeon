//
//  NewPostViewController.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 9/4/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import UIKit
import MapKit
import ReachabilitySwift


class NewPostViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let firebaseController = FirebaseController.sharedInstance
    let validator = TextValidationController.sharedInstance
    let errorAlertController = ErrorAlertController()
    
    var reachabilityNetworkConnection = Reachability()!
    
    //Global Variables
    var color: UIColor!
    var userProfile: Profile!
    var postLongitude:Double!
    var postLatitude:Double!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleTextField.delegate = self
        messageTextField.delegate = self
        
        submitButton.isEnabled = false
        self.view.backgroundColor = color.lighterColor(0.3)
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: postLatitude, longitude: postLongitude)) { (placemarkArray, error) in
            if error == nil {
                let userLocation = placemarkArray?[0]
                self.titleLabel.text = userLocation?.thoroughfare
            }
        }
    }
    
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        
        reachabilityNetworkConnection.whenReachable = { reachable in
            DispatchQueue.main.async {
                if self.firebaseController.enforceNewPostRateLimit() {
                    self.activityIndicator.startAnimating()
                    
                    let dictionaryOfNewTopicValues = ["username": self.userProfile.username!, "twitterID": self.userProfile.twitterid!, "topicTitle": self.titleTextField.text!, "topicMessage": self.messageTextField.text!, "color": self.color.hexCode, "latitude": self.postLatitude, "longitude": self.postLongitude] as [String : Any]
                    
                    self.firebaseController.createNewTopicPostOnFirebase(dictionaryOfNewPostValues: dictionaryOfNewTopicValues, baseView: self, completionHandler: { (postWasInitiallyDelayed) in
                        
                        if postWasInitiallyDelayed == false {
                            if let navController = self.navigationController, navController.viewControllers.count >= 2 {
                                let viewController = navController.viewControllers[navController.viewControllers.count - 2] as! MapViewController
                                viewController.fromNewPost = true
                            }
                            self.navigationController?.popViewController(animated: true)
                        } else {
                            self.errorAlertController.displayAlert(title: "Update!", message: "Your post was sent succesfully!", view: self)
                        }
                    } )
                } else {
                    
                    self.errorAlertController.displayAlert(title: "Slow Down!", message: "Please wait 20 seconds between posting", view: self)
                    
                    //Resets the reachability library
                    self.reachabilityNetworkConnection = Reachability()!
                }
            }
        }
        reachabilityNetworkConnection.whenUnreachable = { _ in
            DispatchQueue.main.async {
                self.errorAlertController.displayAlert(title: "Connection Issue", message: "There was an issue with your connection, we'll keep trying to post though!", view: self)
            }
        }
        
        do {
            try reachabilityNetworkConnection.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
        
    }
    
    @IBAction func titleFieldChanged(_ sender: Any) {
        validateText()
    }
    
    @IBAction func messageFieldChanged(_ sender: Any) {
        validateText()
    }
    

    func validateText() {
        let titleText = titleTextField.text!.replacingOccurrences(of: " ", with: "")
        let messageText = messageTextField.text!.replacingOccurrences(of: " ", with: "")
        if validator.validator.validateString(titleText) && validator.validator.validateString(messageText) {
            submitButton.isEnabled = true
        } else {
            submitButton.isEnabled = false
        }
    }
}

extension NewPostViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
