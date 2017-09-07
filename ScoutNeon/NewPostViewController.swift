//
//  NewPostViewController.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 9/4/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import UIKit
import MapKit

class NewPostViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var titleTextField: UITextField!
    
    @IBOutlet weak var messageTextField: UITextField!
    
    
    @IBOutlet weak var submitButton: UIButton!
    
    let firebaseController = FirebaseController.sharedInstance()
    let validator = TextValidationController.sharedInstance()
    
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
        
    }
    
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        firebaseController.newPost(username: userProfile.username!, topicTitle: titleTextField.text!, topicMessage: messageTextField.text!, color: color.hexCode, latitude: postLatitude, longitude: postLongitude)
    }
    
    @IBAction func titleFieldChanged(_ sender: Any) {
        validateText()
    }
    
    @IBAction func messageFieldChanged(_ sender: Any) {
        validateText()
    }
    

    func validateText() {
        if validator.validator.validateString(titleTextField.text!) && validator.validator.validateString(messageTextField.text!) {
            submitButton.isEnabled = true
        } else {
            submitButton.isEnabled = false
        }
    }
}
