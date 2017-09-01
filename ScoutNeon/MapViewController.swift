//
//  MapViewController.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 8/27/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mainMapView: MKMapView!
    @IBOutlet weak var scoutButton: UIButton!
    
    let coreDataController = CoreDataController.sharedInstance()
    
    let operationQueue = DispatchQueue(label: "com.appcoda.myqueue")
    
    var userIDForProfile: String!
    var userProfile = Profile()


    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        coreDataController.getUserProfile(userID: userIDForProfile!) { (success, profile) in
            if success {
                self.userProfile = profile!
            } else {
                print("login as guest")
            }
        }
        scoutButton.frame = CGRect(x: 320, y: 200, width: 100, height: 100)
        scoutButton.layer.masksToBounds = true
        scoutButton.layer.cornerRadius = scoutButton.bounds.size.width / 2
        scoutButton.backgroundColor = UIColor(hex: userProfile.color!)
        
        let button2 = UIButton()
        button2.frame = CGRect(x: self.view.center.x - 50, y: 0, width: 100, height: 100)
        button2.layer.borderWidth = 2
        button2.layer.cornerRadius = 50
        button2.setTitle("button", for: [])
        button2.backgroundColor = UIColor.blue
        
        self.view.addSubview(button2)
        /*
        let hello = ColorPinAnnotation()
        hello.coordinate = CLLocationCoordinate2D(latitude: 40, longitude: -73)
        hello.pinTintColor = .red
        mainMapView.addAnnotation(hello) */
    }
    
    @IBAction func scoutButtonPressed(_ sender: Any) {
    }
    

    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "myAnnotation") as? MKPinAnnotationView
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myAnnotation")
        } else {
            annotationView?.annotation = annotation
        }
        
        if let annotation = annotation as? ColorPinAnnotation {
            annotationView?.pinTintColor = annotation.pinTintColor
        }
        
        return annotationView
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

