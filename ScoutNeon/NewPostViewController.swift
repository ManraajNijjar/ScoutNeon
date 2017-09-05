//
//  NewPostViewController.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 9/4/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import UIKit

class NewPostViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var titleTextField: UITextField!
    
    @IBOutlet weak var messageTextField: UITextView!
    
    @IBOutlet weak var submitButton: UIButton!
    
    var color: UIColor!
    var userProfile: Profile!
    var postLongitude:Double!
    var postLatitude:Double!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //titleLabel.text = String(postLongitude)
        //self.view.backgroundColor = color
        
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        
    }

}
