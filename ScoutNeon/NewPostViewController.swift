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
    
    let firebaseController = FirebaseController.sharedInstance()
    let validator = TextValidationController.sharedInstance()
    let errorAlertController = ErrorAlertController()
    var reachability = Reachability()!
    
    var color: UIColor!
    var userProfile: Profile!
    var postLongitude:Double!
    var postLatitude:Double!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        submitButton.isEnabled = false
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(CLLocation(latitude: postLatitude, longitude: postLongitude)) { (placemarkArray, error) in
            if error == nil {
                let pm = placemarkArray?[0]
                self.titleLabel.text = pm?.thoroughfare
            }
        }
        self.view.backgroundColor = color.lighterColor(0.3)
        
        titleTextField.delegate = self
        messageTextField.delegate = self
        
    }
    
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        
        reachability.whenReachable = { reachable in
            DispatchQueue.main.async {
                if self.firebaseController.rateLimitPosts() {
                    self.activityIndicator.startAnimating()
                    self.firebaseController.newPost(username: self.userProfile.username!, topicTitle: self.titleTextField.text!, topicMessage: self.messageTextField.text!, color: self.color.hexCode, latitude: self.postLatitude, longitude: self.postLongitude, baseView: self, completionHandler: { (delayed) in
                        if delayed == false {
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
                    self.reachability = Reachability()!
                }
            }
        }
        reachability.whenUnreachable = { _ in
            DispatchQueue.main.async {
                self.errorAlertController.displayAlert(title: "Connection Issue", message: "There was an issue with your connection, we'll keep trying to post though!", view: self)
            }
        }
        
        do {
            try reachability.startNotifier()
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
