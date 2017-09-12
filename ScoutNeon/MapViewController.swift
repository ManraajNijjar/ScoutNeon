//
//  MapViewController.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 8/27/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import ChromaColorPicker

class MapViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var mainMapView: MKMapView!
    @IBOutlet weak var scoutButton: UIButton!
    @IBOutlet weak var chromaView: UIView!
    @IBOutlet weak var chromaViewConstraint: NSLayoutConstraint!
    
    
    let coreDataController = CoreDataController.sharedInstance()
    
    let firebaseController = FirebaseController.sharedInstance()
    
    let colorAPI = ColorApiController()
    
    let operationQueue = DispatchQueue(label: "com.appcoda.myqueue")
    
    let locationManager = CLLocationManager()
    
    var userIDForProfile: String!
    var userProfile = Profile()
    var colorPicker = ChromaColorPicker()
    var selectedColor = UIColor()
    var messageListForTransfer = [[String:String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainMapView.delegate = self
        
        //Moves the slide in menu off screen
        chromaViewConstraint.constant = self.view.frame.height
        
        //Sets up the location manager and begins the process
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        //Thread Safe implementation of retrieving the User Profile data
        coreDataController.getUserProfile(userID: userIDForProfile!) { (success, profile) in
            if success {
                self.userProfile = profile!
            } else {
                print("login as guest")
            }
        }
        
        setupButton()
        
        selectedColor = UIColor(hex: userProfile.color!)
        
        colorPicker = setupChromaColorPicker()
        colorPicker.addTarget(self, action: #selector(AccountSetupViewController.colorSliderMoved), for: .touchUpInside)
        colorPicker.shadeSlider.addTarget(self, action: #selector(AccountSetupViewController.colorSliderMoved), for: .touchUpInside)
        
        chromaView.addSubview(colorPicker)
        
    }
    
    func setupButton(){
        //Sets up the button, places it dynamically, and makes it circular
        let sizeBox = self.view.frame.size.width/5
        scoutButton.frame = CGRect(x: self.view.center.x - (sizeBox/2), y: ((self.view.center.y * 1.3)), width: sizeBox, height: sizeBox)
        scoutButton.setTitle("Scout",for: .normal)
        scoutButton.layer.masksToBounds = true
        scoutButton.layer.cornerRadius = scoutButton.bounds.size.width / 2
        scoutButton.layer.borderWidth = 5
        scoutButton.layer.borderColor = UIColor.white.cgColor
        scoutButton.backgroundColor = UIColor(hex: userProfile.color!)
        
        //Sets up the long touch on the Scout button
        let longTouchRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.displayChromaColorPicker(_:)))
        longTouchRecognizer.minimumPressDuration = 0.5
        scoutButton.addGestureRecognizer(longTouchRecognizer)
    }
    
    
    
    @IBAction func scoutButtonPressed(_ sender: Any) {
        operationQueue.async {
            self.firebaseController.findPostsByHexAndLocation(colorHex: self.selectedColor.hexCode, latitude: (self.locationManager.location?.coordinate.latitude)!, longitude: (self.locationManager.location?.coordinate.longitude)!) { (posts) in
                DispatchQueue.main.async {
                    self.mainMapView.removeAnnotations(self.mainMapView.annotations)
                    for post in posts {
                        let newPin = ColorPinAnnotation()
                        newPin.coordinate = CLLocationCoordinate2D(latitude: post["latitude"] as! Double, longitude: post["longitude"] as! Double)
                        newPin.pinTintColor = self.selectedColor
                        newPin.title = post["title"] as? String
                        newPin.subtitle = post["author"] as? String
                        newPin.id = post["postID"] as? String
                        self.mainMapView.addAnnotation(newPin)
                    }
                }
            }
        }
    }
    
    @IBAction func newPostButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "NewPostSegue", sender: self)
        
    }
    
    func displayChromaColorPicker(_ sender: UITapGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            chromaViewConstraint.constant = self.view.frame.height * 0.6
            UIView.animate(withDuration: 0.15, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @IBAction func slideOutMenuCancelled(_ sender: Any) {
        chromaViewConstraint.constant = self.view.frame.height
        UIView.animate(withDuration: 0.25, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        let span:MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
        let myLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        let region:MKCoordinateRegion = MKCoordinateRegion(center: myLocation, span: span)
        mainMapView.setRegion(region, animated: true)
        self.mainMapView.showsUserLocation = true
    }
    
    
    func colorSliderMoved() {
        operationQueue.async {
            self.colorAPI.getColorNameByHex(selectColor: self.colorPicker.currentColor) { (results, error) in
                if error == nil {
                    DispatchQueue.main.async {
                        let resultsName = results!["name"]! as AnyObject
                        print(resultsName["value"]! as? String!)
                        self.colorSwitched()
                    }
                }
            }
        }
    }
    func colorSwitched() {
        selectedColor = self.colorPicker.currentColor
        scoutButton.backgroundColor = selectedColor
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NewPostSegue" {
            let destinationViewController = segue.destination as! NewPostViewController
            destinationViewController.userProfile = self.userProfile
            destinationViewController.color = self.selectedColor
            destinationViewController.postLatitude = locationManager.location?.coordinate.latitude
            destinationViewController.postLongitude = locationManager.location?.coordinate.longitude
        }
        
        if segue.identifier == "MessagesSegue" {
            let destinationViewController = segue.destination as! MessageTableViewController
            destinationViewController.messages = messageListForTransfer
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
}

extension MapViewController: ChromaColorPickerDelegate {
    
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
        //colorPicker.center = CGPoint(x: chromaView.center.x, y: chromaView.center.y)
        return colorPicker
    }
    
    //Triggers whenever the slider is moved
    func colorPickerDidChooseColor(_ colorPicker: ChromaColorPicker, color: UIColor) {
        print(colorPicker.currentColor)
    }
    
    
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "myAnnotation") as? MKPinAnnotationView
        
        //Prevents a custom pin from returning for the users current location
        if annotation is MKUserLocation{
            return nil
        }
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myAnnotation")
        } else {
            annotationView?.annotation = annotation
        }
        
        if let annotation = annotation as? ColorPinAnnotation {
            annotationView?.pinTintColor = annotation.pinTintColor
            annotationView?.canShowCallout = true
            annotationView?.rightCalloutAccessoryView = UIButton(type: .infoDark)
            (annotationView?.annotation as! ColorPinAnnotation).id = annotation.id

        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl){
        if view.annotation is ColorPinAnnotation {
            let colorPin = view.annotation as! ColorPinAnnotation
            print(colorPin.id)
            firebaseController.messagesForPost(postID: colorPin.id!, messageForPostCompletionHanlder: { (messageList) in
                self.messageListForTransfer = messageList
                self.performSegue(withIdentifier: "MessagesSegue", sender: self)
            })
        }
    }
}

