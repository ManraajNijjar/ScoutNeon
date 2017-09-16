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
    var titleText: String!
    var topicColor: String!
    var userProfile: Profile!
    
    var postCount = 0
    
    var alphaComponent: Double = 0.5
    var alphaModifier: Double = 0
    

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        submitButton.isEnabled = false
        setupListener()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        firebaseController.detachListeners()
    }
    
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        if firebaseController.rateLimitPosts() {
            firebaseController.newMessage(postId: selectedTopic, messageValueString: textField.text!, author: username)
            textField.text = ""
            submitButton.isEnabled = false
        }
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
        let value = firebaseController.messageListener(postId: selectedTopic, messageTableView: self)
    }
    
    

}
extension MessageTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        postCount = messages.count + 1
        alphaModifier = alphaComponent.divided(by: Double(postCount))
        return postCount
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleCell") as! TitleTableViewCell
            cell.titleLabel.text = titleText
            cell.topicTitle = titleText
            cell.topicId = selectedTopic
            cell.topicColor = topicColor
            cell.userProfile = userProfile
            cell.backgroundColor = UIColor(hex: topicColor).withAlphaComponent(CGFloat(alphaComponent))
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell") as! MessageTableViewCell
            let value = messages[indexPath.row - 1]
            cell.authorLabel.text = value["author"]
            cell.messageLabel.text = value["text"]
            let backgroundValue = CGFloat(alphaComponent - (alphaModifier * Double(indexPath.row)))
            cell.backgroundColor = UIColor(hex: topicColor).withAlphaComponent(backgroundValue)
            return cell
        }
        
    }
    
}
