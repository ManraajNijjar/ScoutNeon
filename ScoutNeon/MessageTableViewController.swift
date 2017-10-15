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
    
    var messageList: [[String: String]]!
    var selectedTopic: String!
    var titleTextForSelectedTopic: String!
    var topicColorForSelectedTopic: String!
    
    var userProfile: Profile!
    
    var postCountForCalculatingAlpha = 0
    var alphaComponentBaseForTableViewCells: Double = 0.5
    var alphaModifierForTableViewCells: Double = 0
    
    var keyboardShowing = false
    var keyboardHeight : CGFloat = 0

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
                if self.firebaseController.enforceNewPostRateLimit() {
                    self.activityIndicator.startAnimating()
                    let dictionaryOfNewMessageValues = ["postId": self.selectedTopic, "messageValueString": self.textField.text!, "author": self.userProfile.username, "twitterId": self.userProfile.twitterid] as! [String: String]
                    self.firebaseController.createMessageOnFirebase(dictionaryOfNewMessageValues: dictionaryOfNewMessageValues, baseView: self)
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
    
    func setupListener() {
        let _ = firebaseController.messageListener(postId: selectedTopic, userProfile: userProfile, messageTableView: self)
    }
    
    func validateText() {
        let messageText = textField.text!.replacingOccurrences(of: " ", with: "")
        if validator.validator.validateString(messageText){
            submitButton.isEnabled = true
        } else {
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
        postCountForCalculatingAlpha = messageList.count + 1
        alphaModifierForTableViewCells = alphaComponentBaseForTableViewCells.divided(by: Double(postCountForCalculatingAlpha))
        return postCountForCalculatingAlpha
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cellForTopic = tableView.dequeueReusableCell(withIdentifier: "TitleCell") as! TitleTableViewCell
            cellForTopic.titleLabel.text = titleTextForSelectedTopic
            cellForTopic.topicTitle = titleTextForSelectedTopic
            cellForTopic.topicId = selectedTopic
            cellForTopic.topicColor = topicColorForSelectedTopic
            cellForTopic.userProfile = userProfile
            cellForTopic.backgroundColor = UIColor(hex: topicColorForSelectedTopic).withAlphaComponent(CGFloat(alphaComponentBaseForTableViewCells))
            if coreDataController.checkIfTopicFavorited(userProfile: userProfile, topicId: selectedTopic) {
                cellForTopic.starButton.imageView?.image = UIImage(named: "YellowStar")
            }
            return cellForTopic
        } else {
            let cellForMessage = tableView.dequeueReusableCell(withIdentifier: "MessageCell") as! MessageTableViewCell
            let value = messageList[indexPath.row - 1]
            cellForMessage.userProfile = userProfile
            cellForMessage.authorTwitterId = value["twitterId"]
            cellForMessage.messageId = value["MessageId"]
            cellForMessage.authorLabel.text = value["author"]
            cellForMessage.messageLabel.text = value["text"]
            let backgroundValue = CGFloat(alphaComponentBaseForTableViewCells - (alphaModifierForTableViewCells * Double(indexPath.row)))
            cellForMessage.backgroundColor = UIColor(hex: topicColorForSelectedTopic).withAlphaComponent(backgroundValue)
            return cellForMessage
        }
        
    }
    
}

extension MessageTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
