//
//  MyExtension.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/26.
//

import Foundation
import UIKit


// extension獨立一個file
// check a String is Int or not
extension String {
    var isInt: Bool {
        return Int(self) != nil
    }
}

extension UITableView {
    // 當清單沒有資料時，顯示置中的提示訊息；傳 nil 則清除提示。
    func setEmptyMessage(_ message: String?) {
        guard let message = message else {
            backgroundView = nil
            return
        }
        let label = UILabel()
        label.text = message
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        backgroundView = label
    }
}
