//
//  MessageTableViewController.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 9/11/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import UIKit
import FirebaseDatabase
import ReachabilitySwift

class MessageTableViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var submitButton: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let validator = TextValidationController.sharedInstance
    let firebaseController = FirebaseController.sharedInstance
    let coreDataController = CoreDataController.sharedInstance
    let errorController = ErrorAlertController()
    
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
        textField.delegate = self
        submitButton.isEnabled = false
        setupListener()
        
        //Sets up observers for when the Keyboard activates
        NotificationCenter.default.addObserver(self, selector: #selector(MessageTableViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MessageTableViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        firebaseController.detachListeners()
    }
    
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        let reachability = Reachability()!
        
        reachability.whenReachable = { reachability in
            DispatchQueue.main.async {
                if self.firebaseController.rateLimitPosts() {
                    self.activityIndicator.startAnimating()
                    self.firebaseController.newMessage(postId: self.selectedTopic, messageValueString: self.textField.text!, author: self.username, baseView: self)
                    self.textField.text = ""
                    self.submitButton.isEnabled = false
                } else {
                    self.errorController.displayAlert(title: "Slow Down", message: "Please wait 20 seconds between posting", view: self)
                }
            }
        }
        reachability.whenUnreachable = { _ in
            DispatchQueue.main.async {
                self.errorController.displayAlert(title: "Connection Issue!", message: "There was an issue sending your message, please try again later", view: self)
            }
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
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
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
    
    

}
extension MessageTableViewController: UITableViewDelegate, UITableViewDataSource {
    
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
            if coreDataController.checkIfTopicFavorited(userProfile: userProfile, topicId: selectedTopic) {
                cell.starButton.imageView?.image = UIImage(named: "YellowStar")
            }
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

extension MessageTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
