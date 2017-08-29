//
//  ColorApiController.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 8/16/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import Foundation
import UIKit

class ColorApiController {
    func getColorNameByHex(selectColor : UIColor, completionHandlerForColor: @escaping (_ results: AnyObject?, _ error: NSError?) -> Void){
        //http://www.thecolorapi.com/id?hex=0047AB&format=json
        
        let searchUrl = "http://www.thecolorapi.com/id?hex=\(selectColor.hexCode)&format=json"
        let request = URLRequest(url: URL(string: searchUrl)!)
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) { data, response, error in
            
            guard error == nil else {
                //DisplayErrorFunction()
                return
            }
            //Uncasts the data optional
            guard let data = data else {
                return
            }
            //Process the results of the data so it can be accessed like normal JSON data
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: { (results, error) in
                if error != nil {
                    completionHandlerForColor(nil, error)
                }
                if error == nil {
                    completionHandlerForColor(results, nil)
                }
            })
            
        }
        task.resume()

    }
    
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult, nil)
    }
}
