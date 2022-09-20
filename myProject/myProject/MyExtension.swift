//
//  MyExtension.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/26.
//

import Foundation


// extension獨立一個file
// check a String is Int or not
extension String {
    var isInt: Bool {
        return Int(self) != nil
    }
}
