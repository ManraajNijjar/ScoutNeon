//
//  AccountSetupViewController.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 8/16/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import UIKit

class AccountSetupViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var anonSwitch: UISegmentedControl!
    
    @IBOutlet weak var submitButton: UIButton!
    
    var userIDFromLogin: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func submitPressed(_ sender: Any) {
    }
    

}
