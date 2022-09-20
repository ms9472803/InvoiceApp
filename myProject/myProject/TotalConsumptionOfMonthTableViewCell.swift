//
//  TotalConsumptionOfMonthTableViewCell.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/26.
//

import UIKit

@objc class TotalConsumptionOfMonthTableViewCell: UITableViewCell {

    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var consumptionlabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
