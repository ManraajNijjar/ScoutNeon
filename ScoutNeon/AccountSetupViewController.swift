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
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var submitButton: UIButton!
    
    @IBOutlet weak var favoriteColorLabel: UILabel!
    
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet weak var backgroundColorView: UIView!
    
    @IBOutlet weak var headingTextLabel: UILabel!
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //Variables to make the editing process easier
    var editmode = false
    var editProfile: Profile!
    var editColor: UIColor!
    var firstEdit = true
    
    var userIDFromLogin: String!
    
    var firebaseIDFromLogin: String!
    
    var colorPicker = ChromaColorPicker()
    
    let twitterAPI = TwitterApiController.sharedInstance
    
    let colorAPI = ColorApiController()
    
    let validator = TextValidationController.sharedInstance
    
    let coreDataController = CoreDataController.sharedInstance
    
    let fireBaseController = FirebaseController.sharedInstance
    
    let errorAlertController = ErrorAlertController()
    
    var blurEffectView = UIVisualEffectView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            backgroundColorView.isHidden = true
            
        default: return
        }
        //Disables the submit button at the start of account settings creation
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.alpha = 0
        view.addSubview(blurEffectView)
        submitButton.isEnabled = false
        
        colorPicker = setupChromaColorPicker()
        colorPicker.addTarget(self, action: #selector(AccountSetupViewController.colorSliderMoved), for: .touchUpInside)
        colorPicker.shadeSlider.addTarget(self, action: #selector(AccountSetupViewController.colorSliderMoved), for: .touchUpInside)

        view.addSubview(colorPicker)

        profileImage.layer.cornerRadius = profileImage.frame.size.width / 2
        profileImage.clipsToBounds = true
        backgroundColorView.layer.cornerRadius = profileImage.frame.size.width / 2
        backgroundColorView.clipsToBounds = true
        view.sendSubview(toBack: backgroundColorView)
        view.sendSubview(toBack: blurEffectView)
        view.sendSubview(toBack: backgroundImage)
        
        activityIndicator.startAnimating()
        twitterAPI.getImageForUserID(userID: userIDFromLogin, size: "Large") { (image) in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                
                switch UIDevice.current.userInterfaceIdiom {
                case .phone:
                    self.profileImage.image = image
                case .pad:
                    // It's an iPad
                    let screenSize: CGRect = UIScreen.main.bounds
                    let selectedSize = screenSize.width/2.5
                    self.profileImage.image = self.ResizeImage(image: image!, targetSize: CGSize(width: selectedSize, height: selectedSize))
                    self.profileImage.removeConstraints(self.profileImage.constraints)
                    self.profileImage.frame = CGRect(x: 0, y: 0, width: Int(selectedSize), height: Int(selectedSize))
                    
                    
                default: return
                }
            }
        }
        view.bringSubview(toFront: usernameTextField)
        
        usernameTextField.delegate = self
        if editmode {
            usernameTextField.text = editProfile.username
            colorPicker.adjustToColor(editColor)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
        UIView.animate(withDuration: 0.5, animations: {
            self.view.backgroundColor = UIColor.white
            self.blurEffectView.alpha = 0.5
        })
    }
    
    
    func colorSliderMoved() {
        backgroundColorView.backgroundColor = colorPicker.currentColor
        colorAPI.getColorNameByHex(selectColor: colorPicker.currentColor) { (results, error) in
            if error == nil {
                DispatchQueue.main.async {
                    let resultsName = results!["name"]! as AnyObject
                    self.favoriteColorLabel.text = resultsName["value"]! as? String
                }
            }
        }
    }

    @IBAction func textFieldChanged(_ sender: Any) {
        let potentialName = usernameTextField.text
        
        if editmode && firstEdit {
            errorAlertController.displayAlert(title: "Warning", message: "Changing your username will only affect future posts", view: self)
            firstEdit = false
        }
        
        if validator.validator.validateString(potentialName!) {
            //Could move this part to when submit is presed if the app is connecting to Firebase too often
            activityIndicator.startAnimating()
            fireBaseController.userExists(userId: potentialName!, baseView: self, userExistsCompletionHandler: { (userStatus) in
                self.submitButton.isEnabled = !(userStatus)
                self.activityIndicator.stopAnimating()
            })
        } else {
            submitButton.isEnabled = false
        }
    }
    
    @IBAction func submitPressed(_ sender: Any) {
        
        let reachability = Reachability()!
        if editmode {
            
            reachability.whenReachable = { reachability in
                DispatchQueue.main.async {
                    self.editProfile.color = self.colorPicker.currentColor.hexCode
                    self.editProfile.username = self.usernameTextField.text!
                    
                    CoreDataController.saveContext()
                    
                    self.fireBaseController.createUser(userProfile: self.editProfile, baseView: self)
                    self.performSegue(withIdentifier: "MapSegue", sender: self)
                }
            }
            reachability.whenUnreachable = { _ in
                DispatchQueue.main.async {
                    self.errorAlertController.displayAlert(title: "Connection Issue!", message: "We can't seem to find your connection to the internet", view: self)
                }
            }
            
            do {
                try reachability.startNotifier()
            } catch {
                print("Unable to start notifier")
            }
            
        } else {
            reachability.whenReachable = { reachability in
                DispatchQueue.main.async {
                    let profile = self.coreDataController.createUserProfile(twitterId: self.userIDFromLogin, firebaseId: self.firebaseIDFromLogin, profileImage: self.profileImage.image!, username: self.usernameTextField.text!, color: self.colorPicker.currentColor.hexCode, anonymous: false)
                    
                    CoreDataController.saveContext()
                    
                    self.fireBaseController.createUser(userProfile: profile, baseView: self)
                    self.performSegue(withIdentifier: "MapSegue", sender: self)
                }
            }
            reachability.whenUnreachable = { _ in
                DispatchQueue.main.async {
                    self.errorAlertController.displayAlert(title: "Connection Issue!", message: "We can't seem to find your connection to the internet", view: self)
                }
            }
            
            do {
                try reachability.startNotifier()
            } catch {
                print("Unable to start notifier")
            }
        }
        
    }
    
    func ResizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
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
    
    @IBAction func unwindToAccountView(segue:UIStoryboardSegue) {
        
    }

}

extension AccountSetupViewController: ChromaColorPickerDelegate {
    
    func setupChromaColorPicker() -> ChromaColorPicker {
        //Resolves inherent issue with ChromaColorPicker that was not resolved on the most recent version for some reason
        //https://github.com/joncardasis/ChromaColorPicker/issues/8
        
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            //Sets up the chroma color picker
            let sizeValue = view.frame.size.width * 0.4
            let colorPicker = ChromaColorPicker(frame: CGRect(x: 0, y: 0, width: sizeValue, height: sizeValue))
            colorPicker.delegate = self
            colorPicker.padding = 5
            colorPicker.stroke = 3
            colorPicker.hexLabel.textColor = UIColor.black
            //Places it in the center of the view should likely implement a place to put it so it has constraints
            //neatColorPicker.center = self.colorPickerView.center
            
            //colorPicker.center = self.view.center
            let sizeHeight = view.frame.size.height * 0.1877
            //Closest equivalent to 110 on iPhone7
            colorPicker.center = CGPoint(x: self.view.center.x, y: self.view.center.y + sizeHeight)
            return colorPicker
        case .phone:
            //Sets up the chroma color picker
            let sizeValue = view.frame.size.width * 0.586
            let colorPicker = ChromaColorPicker(frame: CGRect(x: 0, y: 0, width: sizeValue, height: sizeValue))
            colorPicker.delegate = self
            colorPicker.padding = 5
            colorPicker.stroke = 3
            colorPicker.hexLabel.textColor = UIColor.black
            //Places it in the center of the view should likely implement a place to put it so it has constraints
            //neatColorPicker.center = self.colorPickerView.center
            
            //colorPicker.center = self.view.center
            let sizeHeight = view.frame.size.height * 0.1877
            //Closest equivalent to 110 on iPhone7
            colorPicker.center = CGPoint(x: self.view.center.x, y: self.view.center.y + sizeHeight)
            return colorPicker
        default: print("Case not Found")
        }
        /*
        //Sets up the chroma color picker
        let sizeValue = view.frame.size.width * 0.586
        let colorPicker = ChromaColorPicker(frame: CGRect(x: 0, y: 0, width: sizeValue, height: sizeValue))
        colorPicker.delegate = self
        colorPicker.padding = 5
        colorPicker.stroke = 3
        colorPicker.hexLabel.textColor = UIColor.black
        //Places it in the center of the view should likely implement a place to put it so it has constraints
        //neatColorPicker.center = self.colorPickerView.center
        
        //colorPicker.center = self.view.center
        let sizeHeight = view.frame.size.height * 0.1877
        //Closest equivalent to 110 on iPhone7
        colorPicker.center = CGPoint(x: self.view.center.x, y: self.view.center.y + sizeHeight)
        return colorPicker */
        return ChromaColorPicker()
    }
    
    //Triggers whenever the slider is moved
    func colorPickerDidChooseColor(_ colorPicker: ChromaColorPicker, color: UIColor) {
        print(colorPicker.currentColor)
    }
    
    
    
}
extension AccountSetupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
