//
//  MessageTableViewController.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 9/11/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import UIKit

class MessageTableViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var submitButton: UIButton!
    
    
    var messages: [[String: String]]!

    override func viewDidLoad() {
        super.viewDidLoad()
        print(messages)

        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func textFieldEdited(_ sender: Any) {
        
        
    }
    
    

}
