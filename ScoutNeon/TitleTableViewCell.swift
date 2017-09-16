//
//  TitleTableViewCell.swift
//  ScoutNeon
//
//  Created by Manraaj Nijjar on 9/13/17.
//  Copyright © 2017 Manraaj Nijjar. All rights reserved.
//

import UIKit

class TitleTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var starButton: UIButton!
    
    let coreDataController = CoreDataController.sharedInstance()
    
    var topicId = ""
    var topicColor = ""
    var userProfile: Profile!
    var topicTitle = ""

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func starButtonPressed(_ sender: Any) {
        
        if coreDataController.checkIfTopicFavorited(userProfile: userProfile, topicId: topicId) {
            print("Deleted")
            coreDataController.deleteFavoriteTopic(userProfile: userProfile, topicId: topicId)
            starButton.imageView?.image = UIImage(named: "BlackStar")
            
        } else {
            print("Saved")
            starButton.imageView?.image = UIImage(named: "YellowStar")
            coreDataController.createFavoriteTopic(userProfile: userProfile, topicId: topicId, topicTitle: topicTitle, topicColor: topicColor)
            CoreDataController.saveContext()
        }
        
        
    }
    

}
