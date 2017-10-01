//
//  AccountSetupViewController.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 8/16/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import UIKit
import ChromaColorPicker
import ReachabilitySwift

class AccountSetupViewController: UIViewController {
    
    //Storyboard Elements
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var submitButton: UIButton!
    
    @IBOutlet weak var favoriteColorLabel: UILabel!
    
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet weak var backgroundColorView: UIView!
    
    @IBOutlet weak var headingTextLabel: UILabel!
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //Variables to make the editing process easier
    var editModeIsActive = false
    var editProfile: Profile!
    var editColor: UIColor!
    
    //Pulled from the Login View Controller
    var userIDFromLogin: String!
    var firebaseIDFromLogin: String!
    
    //Controllers and APIs
    let twitterAPI = TwitterApiController.sharedInstance
    let colorAPI = ColorApiController()
    let coreDataController = CoreDataController.sharedInstance
    let fireBaseController = FirebaseController.sharedInstance
    let errorAlertController = ErrorAlertController()
    
    //Programatic UIElements that need a global call
    private var blurEffectView = UIVisualEffectView()
    var colorPicker = ChromaColorPicker()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Removes the background Color if the device is an iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            backgroundColorView.isHidden = true
        }
        
        //Sets up the Chroma Color Picker and connects two methods to the actions you can use with it
        colorPicker = setupChromaColorPicker()
        view.addSubview(colorPicker)
        
        //Turns the Image and the Background Color View into a circle
        profileImage.layer.cornerRadius = profileImage.frame.size.width / 2
        profileImage.clipsToBounds = true
        backgroundColorView.layer.cornerRadius = profileImage.frame.size.width / 2
        backgroundColorView.clipsToBounds = true
        
        //Sends the subviews to the back of the View in order to make everything function properly
        view.sendSubview(toBack: backgroundColorView)
        view.sendSubview(toBack: blurEffectView)
        view.sendSubview(toBack: backgroundImage)
        
        
        //Begins to retrieve the users image from Twitter
        activityIndicator.startAnimating()
        twitterAPI.getImageForUserID(userID: userIDFromLogin, size: "Large") { (image) in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                
                switch UIDevice.current.userInterfaceIdiom {
                case .phone:
                    self.profileImage.image = image
                case .pad:
                    
                    //Scales the image for iPad sizes
                    let screenSize: CGRect = UIScreen.main.bounds
                    let selectedSize = screenSize.width/2.5
                    self.profileImage.image = self.ResizeImage(image: image!, targetSize: CGSize(width: selectedSize, height: selectedSize))
                    self.profileImage.removeConstraints(self.profileImage.constraints)
                    self.profileImage.frame = CGRect(x: 0, y: 0, width: Int(selectedSize), height: Int(selectedSize))
                    
                    
                default: return
                }
            }
            
        }
        
        //Moves the usernameTextField to the front
        view.bringSubview(toFront: usernameTextField)
        
        //If the view is in editmode and not login changes the values accordinglty
        if editModeIsActive {
            self.usernameTextField.text = editProfile.username
            colorPicker.adjustToColor(editColor)
        }
        
        twitterAPI.getUserData(userID: userIDFromLogin) { (user, error) in
            if let user = user {
                self.usernameTextField.text = user.screenName
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
        //Makes the view change in the background as a transition effect
        UIView.animate(withDuration: 0.5, animations: {
            self.view.backgroundColor = UIColor.white
            self.blurEffectView.alpha = 0.5
        })
    }

    @IBAction func submitPressed(_ sender: Any) {
        
        let reachability = Reachability()!
        
        //Only does the configuration on the client since no changes are needed on the back end
        if editModeIsActive {
            self.editProfile.color = self.colorPicker.currentColor.hexCode
            self.editProfile.username = self.usernameTextField.text!
            CoreDataController.saveContext()
            self.performSegue(withIdentifier: "MapSegue", sender: self)
            
        } else {
            
            //Determines if the app has an active internet connection, if not it listens until it does and then performs
            //The push to Firebase
            reachability.whenReachable = { reachability in
                DispatchQueue.main.async {
                    //Generates a new Profile from the CoreData model
                    let profile = self.coreDataController.createUserProfile(twitterId: self.userIDFromLogin, firebaseId: self.firebaseIDFromLogin, profileImage: self.profileImage.image!, username: self.usernameTextField.text!, color: self.colorPicker.currentColor.hexCode, anonymous: false)
                    
                    CoreDataController.saveContext()
                    
                    //Sends the new model to Firebase
                    self.fireBaseController.createUser(userProfile: profile, baseView: self)
                    self.performSegue(withIdentifier: "MapSegue", sender: self)
                }
            }
            //Displays an alert if there is no active internet connection
            reachability.whenUnreachable = { _ in
                DispatchQueue.main.async {
                    self.errorAlertController.displayAlert(title: "Connection Issue!", message: "We can't seem to find your connection to the internet", view: self)
                }
            }
            
            //Starts the Listener
            do {
                try reachability.startNotifier()
            } catch {
                print("Reachability Notifier did not properly start")
            }
        }
        
    }
    
    //Takes an image and resizes it, used to increase the size of the imageView when on iPad
    func ResizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "MapSegue" {
            let destinationNavigationController = segue.destination as! UINavigationController
            let targetController = destinationNavigationController.topViewController as! MapViewController
            targetController.userIDForProfile = firebaseIDFromLogin
        }
    }
    
    //Unwind segue for the Map View when entering Edit Mode
    @IBAction func unwindToAccountView(segue:UIStoryboardSegue) {
        
    }
    
    func blurSetup(){
        //Sets up the blur effect to the photo and moves it to the back
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.alpha = 0
        view.addSubview(blurEffectView)
    }

}

extension AccountSetupViewController: ChromaColorPickerDelegate {
    
    //The function called by the interactions with the Chroma Elements
    func colorSliderMoved() {
        backgroundColorView.backgroundColor = colorPicker.currentColor
        colorAPI.getColorNameByHex(selectColor: colorPicker.currentColor) { (apiCallResults, error) in
            if let result = apiCallResults {
                DispatchQueue.main.async {
                    let resultsColorName = result["name"]! as AnyObject
                    let resultsContrastColor = result["contrast"]! as AnyObject
                    
                    self.favoriteColorLabel.backgroundColor = UIColor(hex: resultsContrastColor["value"]! as! String)
                    self.favoriteColorLabel.text = resultsColorName["value"]! as? String
                    self.favoriteColorLabel.textColor = self.colorPicker.currentColor
                }
            }
        }
    }
    
    func setupChromaColorPicker() -> ChromaColorPicker {
        //Resolves inherent issue with ChromaColorPicker that is resolved on the repo but not in the pod
        //https://github.com/joncardasis/ChromaColorPicker/issues/8
        var sizeValue: CGFloat = 0
        let sizeHeight: CGFloat = view.frame.size.height * 0.1877
        
        //Switches up the size of the Picker depending on if the device is a phone or a pad
        if UIDevice.current.userInterfaceIdiom == .pad {
            sizeValue = view.frame.size.width * 0.4
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            sizeValue = view.frame.size.width * 0.586
        }
        
        //Sets up the UI aspects of the picker
        let colorPicker = ChromaColorPicker(frame: CGRect(x: 0, y: 0, width: sizeValue, height: sizeValue))
        colorPicker.delegate = self
        colorPicker.padding = 5
        colorPicker.stroke = 3
        colorPicker.hexLabel.textColor = UIColor.black
        colorPicker.center = CGPoint(x: self.view.center.x, y: self.view.center.y + sizeHeight)
        
        //Removes a button from the Chroma Picker
        colorPicker.addButton.isHidden = true
        colorPicker.addButton.isEnabled = false
        
        //Attaches methods to two interactions on the picker
        colorPicker.addTarget(self, action: #selector(AccountSetupViewController.colorSliderMoved), for: .touchUpInside)
        colorPicker.shadeSlider.addTarget(self, action: #selector(AccountSetupViewController.colorSliderMoved), for: .touchUpInside)
        
        return colorPicker
    }
    
    func colorPickerDidChooseColor(_ colorPicker: ChromaColorPicker, color: UIColor) {
        //Enabled to fit Chroma Delegate requirements, unused as the addbutton is disabled
    }
    
}
