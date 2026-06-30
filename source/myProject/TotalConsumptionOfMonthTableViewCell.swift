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
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .systemBlue
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true

        monthLabel.font = .systemFont(ofSize: 16, weight: .bold)
        monthLabel.textColor = .white
        consumptionlabel.font = .systemFont(ofSize: 18, weight: .bold)
        consumptionlabel.textColor = .white
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds.inset(by: UIEdgeInsets(top: 6, left: 16, bottom: 4, right: 16))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
