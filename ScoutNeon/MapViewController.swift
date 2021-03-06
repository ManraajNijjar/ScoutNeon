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
import TwitterKit
import ReachabilitySwift

class MapViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var mainMapView: MKMapView!
    @IBOutlet weak var scoutButton: UIButton!
    @IBOutlet weak var chromaView: UIView!
    @IBOutlet weak var chromaViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var chromaViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var slideInTableView: UITableView!
    @IBOutlet weak var slideInCancelButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let coreDataController = CoreDataController.sharedInstance
    let firebaseController = FirebaseController.sharedInstance
    let errorAlertController = ErrorAlertController()
    let reachability = Reachability()!
    let locationManager = CLLocationManager()
    
    var userIDForProfile: String!
    var userProfile = Profile()
    var colorPicker = ChromaColorPicker()
    var selectedColor = UIColor()
    var messageListForTransfer = [[String:String]]()
    var selectedTopic = ""
    var selectedTitle = ""
    
    let operationQueue = DispatchQueue(label: "com.appcoda.myqueue")
    
    var fromNewPost = false
    var fromLogin = false
    
    var favoriteTopics = [Topic]()
    
    var scoutColors = [["name": "Scout Red", "hex": "FF3300"], ["name": "Scout Blue", "hex": "0999FF"], ["name": "Scout Green", "hex": "00FF66"], ["name": "Scout Purple", "hex": "9D00FF"]]
    
    let sectionTitles = ["Favorite Topics", "Scout's Recommended Colors"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let defaults:UserDefaults = UserDefaults.standard
        if defaults.bool(forKey: "EULA") != true{
            let alert = UIAlertController(title: "EULA", message: "By Agreeing to the ScoutNeon End User's License Agreement you agree to not conduct any kind of violence towards anyone or anything at any point", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in
                defaults.set(true, forKey: "EULA")
            }))
            alert.addAction(UIAlertAction(title: "Decline", style: UIAlertActionStyle.cancel, handler: {(alert: UIAlertAction!) in
                self.logout()
            }))
            self.present(alert, animated: true, completion: nil)
        }
        
        setupNavBar()
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
            }
        }
        
        for topic in userProfile.favoritetopics! {
            let topicPicked = topic as! Topic
            favoriteTopics.append(topicPicked)
        }
        
        //Setup the TableView methods for the slide in menu
        slideInTableView.delegate = self
        slideInTableView.dataSource = self
        
        setupButton()
        
        selectedColor = UIColor(hex: userProfile.color!)
        activityIndicator.color = selectedColor
        
        colorPicker = setupChromaColorPicker()
        colorPicker.addTarget(self, action: #selector(MapViewController.colorSwitched), for: .touchUpInside)
        colorPicker.shadeSlider.addTarget(self, action: #selector(MapViewController.colorSwitched), for: .touchUpInside)
        
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            chromaViewHeightConstraint.constant = view.frame.size.height / 2
            chromaView.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: (view.frame.size.height / 2))
            
        default:
            break
        }
        
        chromaView.addSubview(colorPicker)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        favoriteTopics.removeAll()
        for topic in userProfile.favoritetopics! {
            let topicPicked = topic as! Topic
            favoriteTopics.append(topicPicked)
        }
        slideInTableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if fromNewPost == true {
            scoutForTopics()
            fromNewPost = false
        }
    }
    
    func setupNavBar(){
        //Sets up the color for the Navbar and Toolbar throughout the app
        let navColor = UIColor.black.withAlphaComponent(0.95)
        navigationController?.navigationBar.barTintColor = navColor
        navigationController?.toolbar.barTintColor = navColor
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
    
    @IBAction func logoutButtonPressed(_ sender: Any) {
        logout()
    }
    
    func logout(){
        let store = Twitter.sharedInstance().sessionStore
        store.logOutUserID(userProfile.twitterid!)
        self.performSegue(withIdentifier: "unwindSegueToLogin", sender: self)
    }
    
    func scoutForTopics() {
        if firebaseController.enforcePostSearchLimit() {
            scoutButton.alpha = 0
            scoutButton.setTitle("1 Sec", for: .normal)
            UIView.animate(withDuration: 6, animations: {
                self.scoutButton.alpha = 1
            }, completion: { (value) in
                self.scoutButton.setTitle("Scout", for: .normal)
            })
            if fromNewPost == false {
                activityIndicator.startAnimating()
            }
            operationQueue.async {
                self.firebaseController.findPostsByHexAndLocation(colorHex: self.selectedColor.hexCode, latitude: (self.locationManager.location?.coordinate.latitude)!, longitude: (self.locationManager.location?.coordinate.longitude)!, baseView: self) { (posts) in
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
                        self.activityIndicator.stopAnimating()
                    }
                }
            }
        } else {
            print("rate limited")
        }
    }
    
    
    @IBAction func scoutButtonPressed(_ sender: Any) {
        let internalReach = Reachability()!
        internalReach.whenReachable = { reachable in
            DispatchQueue.main.async {
                self.scoutForTopics()
            }
        }
        internalReach.whenUnreachable = { _ in
            self.errorAlertController.displayAlert(title: "Connection Issue", message: "There seems to be an issue with your connection, please try again later!", view: self)
        }
        
        do {
            try internalReach.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
        
    }
    
    @IBAction func newPostButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "NewPostSegue", sender: self)
        
    }
    
    func displayChromaColorPicker(_ sender: UITapGestureRecognizer) {
        chromaView.bringSubview(toFront: slideInCancelButton)
        if sender.state == UIGestureRecognizerState.began {
            chromaViewConstraint.constant = self.view.frame.height * 0.5
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
    
    func colorSwitched() {
        selectedColor = self.colorPicker.currentColor
        scoutButton.backgroundColor = selectedColor
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        if fromLogin {
            fromLogin = false
            self.performSegue(withIdentifier: "MapToAccountSegue", sender: self)
        } else {
            print("hello")
            self.performSegue(withIdentifier: "unwindSegueToAccount", sender: self)
        }
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
            destinationViewController.messageList = messageListForTransfer
            destinationViewController.selectedTopic = self.selectedTopic
            destinationViewController.titleTextForSelectedTopic = self.selectedTitle
            destinationViewController.userProfile = self.userProfile
            destinationViewController.topicColorForSelectedTopic = self.selectedColor.hexCode
        }
        if segue.identifier == "unwindSegueToLogin" {
            let destinationViewController = segue.destination as! ViewController
            destinationViewController.automaticLoginEnabled = false
        }
        if segue.identifier == "unwindSegueToAccount"{
            let destinationViewController = segue.destination as! AccountSetupViewController
            destinationViewController.userIDFromLogin = userProfile.twitterid
            destinationViewController.firebaseIDFromLogin = userProfile.id
            destinationViewController.editModeIsActive = true
            destinationViewController.editProfile = userProfile
            destinationViewController.usernameTextField.text = userProfile.username
            destinationViewController.colorPicker.adjustToColor(UIColor(hex: userProfile.color!))
        }
        if segue.identifier == "MapToAccountSegue" {
            let destinationViewController = segue.destination as! AccountSetupViewController
            destinationViewController.userIDFromLogin = userProfile.twitterid
            destinationViewController.firebaseIDFromLogin = userProfile.id
            destinationViewController.editModeIsActive = true
            destinationViewController.editProfile = userProfile
            destinationViewController.editColor = UIColor(hex: userProfile.color!)
        }
    }
}

extension MapViewController: ChromaColorPickerDelegate {
    
    func setupChromaColorPicker() -> ChromaColorPicker {
        //Sets up the chroma color picker
        var sizeValue = view.frame.size.width * 0.586
        
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            sizeValue = view.frame.size.width * 0.5
            
        default: print("Not pad")
        }
        
        let colorPicker = ChromaColorPicker(frame: CGRect(x: 0, y: 0, width: sizeValue, height: sizeValue))
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
    
    //Kept to meet delegate requirements
    func colorPickerDidChooseColor(_ colorPicker: ChromaColorPicker, color: UIColor) {}
    
    
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
        let internalReach = Reachability()!
        internalReach.whenReachable = { reachable in
            DispatchQueue.main.async {
                if view.annotation is ColorPinAnnotation {
                    self.activityIndicator.startAnimating()
                    let colorPin = view.annotation as! ColorPinAnnotation
                    self.selectedTopic = colorPin.id!
                    self.selectedTitle = colorPin.title!
                    self.firebaseController.messageForPostID(postID: self.selectedTopic, userProfile: self.userProfile, baseView: self, messageForPostCompletionHandler: { (messageList) in
                        self.messageListForTransfer = messageList
                        self.performSegue(withIdentifier: "MessagesSegue", sender: self)
                        self.activityIndicator.stopAnimating()
                    })
                }
            }
        }
        internalReach.whenUnreachable = { _ in
            self.errorAlertController.displayAlert(title: "Connection Issue", message: "There seems to be an issue with your connection, please try again later!", view: self)
        }
        
        do {
            try internalReach.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
        
    }
}

extension MapViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if userProfile.favoritetopics != nil {
                return (userProfile.favoritetopics?.count)!
            }
        }
        if section == 1 {
            return scoutColors.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = String(indexPath.row)
        if indexPath.section == 0 {
            let cell = TopicMapTableViewCell()
            let pickedTopic = favoriteTopics[indexPath.row]
            cell.textLabel?.text = pickedTopic.title
            cell.backgroundColor = UIColor(hex: pickedTopic.color!) 
            return cell
        }
        if indexPath.section == 1 {
            let cell = ColorMapTableViewCell()
            cell.textLabel?.text = scoutColors[indexPath.row]["name"]
            let bgColorHex = scoutColors[indexPath.row]["hex"]
            let bgColor = UIColor(hex: bgColorHex!)
            cell.backgroundColor = bgColor
            cell.chromaPicker = colorPicker
            return cell
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let internalReach = Reachability()!
            internalReach.whenReachable = { reachable in
                DispatchQueue.main.async {
                    tableView.deselectRow(at: indexPath, animated: true)
                    let pickedTopic = self.favoriteTopics[indexPath.row]
                    self.selectedTopic = pickedTopic.topicId!
                    self.selectedTitle = pickedTopic.title!
                    self.selectedColor = UIColor(hex: pickedTopic.color!)
                    self.colorSwitched()
                    self.firebaseController.messageForPostID(postID: self.selectedTopic, userProfile: self.userProfile, baseView: self, messageForPostCompletionHandler: { (messageList) in
                        self.messageListForTransfer = messageList
                        print(self.messageListForTransfer)
                        self.performSegue(withIdentifier: "MessagesSegue", sender: self)
                    })
                }
            }
            internalReach.whenUnreachable = { _ in
                self.errorAlertController.displayAlert(title: "Connection Issue", message: "There seems to be an issue with your connection, please try again later!", view: self)
            }
            do {
                try internalReach.startNotifier()
            } catch {
                print("Unable to start notifier")
            }
            
        }
        
        if indexPath.section == 1 {
            tableView.deselectRow(at: indexPath, animated: true)
            colorPicker.adjustToColor(UIColor(hex: scoutColors[indexPath.row]["hex"]!))
            colorSwitched()
        }
    }
    
}

