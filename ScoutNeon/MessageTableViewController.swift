//
//  MessageTableViewController.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 9/11/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import UIKit
import FirebaseDatabase

class MessageTableViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var submitButton: UIButton!
    
    let validator = TextValidationController.sharedInstance()
    let firebaseController = FirebaseController.sharedInstance()
    
    var messages: [[String: String]]!
    var selectedTopic: String!
    var username: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        submitButton.isEnabled = false
        
        var messageRef = firebaseController.getRef()
        messageRef = messageRef?.child("MessageListener").child(selectedTopic)
        /*messageRef?.observeSingleEvent(.value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            print(value)
            print("observertriggered")
        })*/
        messageRef?.observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            print(value)
        })
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        firebaseController.newMessage(postId: selectedTopic, messageValueString: textField.text!, author: username)
    }
    
    @IBAction func textFieldEdited(_ sender: Any) {
        if (textField.text?.characters.count)! > 0 {
            validateText()
        } else {
            submitButton.isEnabled = false
        }
    }
    
    func validateText() {
        let messageText = textField.text!.replacingOccurrences(of: " ", with: "")
        if validator.validator.validateString(messageText){
            submitButton.isEnabled = true
        } else {
            submitButton.isEnabled = false
        }
    }
    
    func setupListener() {
        print("settingup")
        let messageRef = firebaseController.getRef()
        messageRef?.child("MessageListener").child(selectedTopic).observe(.childAdded, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            print(value)
            print("observertriggered")
        })
    }
    
    

}
extension MessageTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell") as! MessageTableViewCell
        let value = messages[indexPath.row]
        cell.authorLabel.text = value["author"]
        cell.messageLabel.text = value["text"]
        return cell
    }
    
}
