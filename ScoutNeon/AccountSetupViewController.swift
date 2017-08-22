//
//  AccountSetupViewController.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 8/16/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import UIKit
import ChromaColorPicker

class AccountSetupViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var anonSwitch: UISegmentedControl!
    
    @IBOutlet weak var submitButton: UIButton!
    
    @IBOutlet weak var favoriteColorLabel: UILabel!
    
    @IBOutlet weak var profileImage: UIImageView!
    
    
    var userIDFromLogin: String!
    
    var colorPicker = ChromaColorPicker()
    
    let twitterAPI = TwitterApiController.sharedInstance()
    
    let colorAPI = ColorApiController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        colorPicker = setupChromaColorPicker()
        colorPicker.addTarget(self, action: #selector(AccountSetupViewController.colorSliderMoved), for: .touchUpInside)
        colorPicker.shadeSlider.addTarget(self, action: #selector(AccountSetupViewController.colorSliderMoved), for: .touchUpInside)

        view.addSubview(colorPicker)
        
        twitterAPI.getImageForUserID(userID: userIDFromLogin, size: "Normal") { (image) in
            DispatchQueue.main.async {
                self.profileImage.image = image
            }
        }
        
        //colorPickerView.addSubview(neatColorPicker)
        // Do any additional setup after loading the view.
    }
    
    func colorSliderMoved() {
        colorAPI.getColorNameByHex(selectColor: colorPicker.currentColor) { (results, error) in
            if error == nil {
                DispatchQueue.main.async {
                    let resultsName = results!["name"]! as AnyObject
                    self.favoriteColorLabel.text = resultsName["value"]! as? String
                }
            }
        }
    }

    
    @IBAction func submitPressed(_ sender: Any) {
        //let string = colorAPI.getColorNameByHex(selectColor: colorPicker.currentColor)
    }
    

}

extension AccountSetupViewController: ChromaColorPickerDelegate {
    
    func setupChromaColorPicker() -> ChromaColorPicker {
        //Sets up the chroma color picker
        let colorPicker = ChromaColorPicker(frame: CGRect(x: 0, y: 0, width: 220, height: 220))
        colorPicker.delegate = self
        colorPicker.padding = 5
        colorPicker.stroke = 3
        colorPicker.hexLabel.textColor = UIColor.black
        
        
        //Resolves inherent issue with ChromaColorPicker that was not resolved on the most recent version for some reason
        //https://github.com/joncardasis/ChromaColorPicker/issues/8
        
        //Places it in the center of the view should likely implement a place to put it so it has constraints
        //neatColorPicker.center = self.colorPickerView.center
        
        //colorPicker.center = self.view.center
        colorPicker.center = CGPoint(x: self.view.center.x, y: self.view.center.y + 110)
        return colorPicker
    }
    
    //Triggers whenever the slider is moved
    func colorPickerDidChooseColor(_ colorPicker: ChromaColorPicker, color: UIColor) {
        print("Color picked")
        print(colorPicker.currentColor)
    }
    
    
}
