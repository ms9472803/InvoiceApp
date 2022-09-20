//
//  myInvoice.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/26.
//

import Foundation
import UIKit


//兩個結構抽出來放到另一個檔案

// @objcMembers 把swift類的全部方法和屬性給 Objective-C 訪問和呼叫
// 如果只是要部分開放單一屬性，則使用@objc即可

@objcMembers class Item: NSObject {
    var itemName: String = ""
    var amount: String = ""
    var price: String = ""
    
    init(itemName: String, amount: String, price: String) {
        self.itemName = itemName
        self.amount = amount
        self.price = price
    }
    
}

// 變數該是什麼type就要是什麼type, 要畫在UI上再轉
@objcMembers class Invoice: NSObject {
    var number: String = ""
    var date: String = ""
    var storeName: String = ""
    var itemAndPrice: [Item] = []
    
    static var invoiceShowCurrent = Invoice()
    static var globalInvoiceArray: [Invoice] = [] {
        didSet {
            //print("globalInvoiceArray didSet")
            if globalInvoiceArray.count == oldValue.count + 1 { //append的時候保持排序
                for i in stride(from: globalInvoiceArray.count - 1, to: 0, by: -1) {
                    if globalInvoiceArray[i].date < globalInvoiceArray[i-1].date {
                        let temp = globalInvoiceArray[i]
                        globalInvoiceArray[i] = globalInvoiceArray[i-1]
                        globalInvoiceArray[i-1] = temp
                    }
                }
            }
        }
    }
    
    
    override init() {}
    
    init(number: String, date: String, storeName: String, itemAndPrice: [Item]) {
        self.number = number
        self.date = date
        self.storeName = storeName
        self.itemAndPrice = itemAndPrice
    }
    
    var totalPrice: String {
        get {
            var sum = 0
            for i in itemAndPrice {
                let price = Int(i.price) ?? 0
                sum += price
            }
            return String(sum)
        }
    }
    
    static func == (lhs: Invoice, rhs: Invoice) -> Bool {
        lhs.number == rhs.number
    }
    
    func transformToInfo() -> String {
        var invoiceInfo: String = "號碼: \(number)\n日期: \(date)\n"
        invoiceInfo += "商店: \(storeName)\n品項:\n"
        for item in itemAndPrice {
            invoiceInfo += "\(item.itemName) \(item.amount) $\(item.price)\n"
        }
        return invoiceInfo
    }
    
    // 改
    func printInfo() {
        print(number, date, storeName, totalPrice)
        for i in itemAndPrice {
            print(i.itemName, i.amount, i.price)
        }
        print("\n")
    }
    
    
    // 兌獎
    func currentBonusCheck(_ currentBonusMonth: String) -> String {
        // 優化 看能不能更快
        // bonus前兩個一樣 其中一個可以拿掉, 用加減去看對應中獎金額
        let bonus = ["0", "200", "1000", "4000", "10000", "40000", "200000"]
        let invoiceLen = 8
        
        // currentBonusMonth format is 2022, 05-06
        let year = currentBonusMonth.prefix(4)
        let month = currentBonusMonth.suffix(5)
        // 如果這張發票是當前顯示的bonus月份, date format is 2022-05-06
        
        // 不符合年月先return
        if (date.prefix(4) != year) || ( (date.prefix(7).suffix(2) != month.prefix(2)) && (date.prefix(7).suffix(2) != month.suffix(2)) ) {
            return "0"
        }
        
        // 可以用guard let判斷
        

        // 看是否中獎
        if let currentJackpotNumberArray = jackpotNumberArray[currentBonusMonth] {
            var maxBonus = "0"
            for jackpotNumber in currentJackpotNumberArray {
                for i in stride(from: invoiceLen, to: 1, by: -1) {
                    if self.number.suffix(i) == jackpotNumber.suffix(i) {
                        //print(i)
                        if Int(bonus[i-2])! > Int(maxBonus)! {
                            maxBonus = bonus[i-2]
                        }
                        break
                    }
                }
            }
            return maxBonus
        }
        
        return "0"
    }
    
    static func removeGlobalInvoiceElement(_ index: Int) {
        globalInvoiceArray.remove(at: index)
    }
    
}

class InvoiceGenerator: NSObject {
    // 隨機產生一張發票
    // 有一個struct 是 generator
    static func invoiceRandomGenerator() -> Invoice {
        func randomInvoiceNumber() -> String {
            let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            let digits = "0123456789"
            return String((0..<2).map{ _ in letters.randomElement()! }) + String((0..<8).map{ _ in digits.randomElement()! })
        }
        
        func randomInvoiceDate() -> String {
            let month = ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
            let numberOfDay = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
            let day = ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31"]
            
            let invoiceMonth = Int.random(in: 0..<12)
            return String(Int.random(in: 2022...2022)) + "-" + month[Int.random(in: 4..<6)] + "-" + day[Int.random(in: 0..<numberOfDay[invoiceMonth])]
        }
        
        func randomInvoiceStore() -> String {
            let store = ["McDonald", "KFC", "NOVA", "G", "A", "B", "C", "D"]
            return store[Int.random(in: 0..<store.count)] + "公司"
        }
        
        func randomInvoiceItem(_ count: Int) -> [Item] {
            let item = ["computer", "monitor", "speaker", "mouse", "keyboard"]
            let price = ["20000", "5000", "3000", "1000", "2000"]
            
            var retItem: [Item] = []
            for _ in 0..<count {
              let index = Int.random(in: 0..<item.count)
                retItem.append(Item(itemName: item[index], amount: String(Int.random(in: 1...5)), price: price[index]))
            }
            
            return retItem
        }
        
        let invoice = Invoice(number: randomInvoiceNumber(), date: randomInvoiceDate(), storeName: randomInvoiceStore(), itemAndPrice: randomInvoiceItem(Int.random(in: 1...5)) )
        
        return invoice
    }
}


/*
let defaultItem1 = Item(itemName: "computer", amount: "1", price: "20000")
let defaultItem2 = Item(itemName: "monitor", amount: "2", price: "5000")
let defaultInvoice1 = Invoice(number: "AA20220518", date: "2022-05-18", storeName: "Synology", itemAndPrice: [defaultItem1, defaultItem2])
let defaultInvoice2 = Invoice(number: "AB20320518", date: "2022-05-17", storeName: "Synology", itemAndPrice: [defaultItem1, defaultItem2])
let defaultInvoice3 = Invoice(number: "AA20220317", date: "2022-03-17", storeName: "Synology", itemAndPrice: [defaultItem1, defaultItem2])*/
// 先塞假資料,之後要先從DB抓發票資料下來放在globalInvoiceArray裡面
// 存放所有發票的array, 改成type property
/*var globalInvoiceArray: [Invoice] = [] {
    didSet {
        //print("globalInvoiceArray didSet")
        if globalInvoiceArray.count == oldValue.count + 1 { //append的時候保持排序
            for i in stride(from: globalInvoiceArray.count - 1, to: 0, by: -1) {
                if globalInvoiceArray[i].date < globalInvoiceArray[i-1].date {
                    let temp = globalInvoiceArray[i]
                    globalInvoiceArray[i] = globalInvoiceArray[i-1]
                    globalInvoiceArray[i-1] = temp
                }
            }
        }
    }
}*/

// 顯示在"顯示發票"tableView或搜尋時點擊看哪個發票, 改成type property
//var invoiceShowCurrent = Invoice(number: "", date: "", storeName: "", itemAndPrice: [])

// 顯示在"確認中獎"tableView上的array
var selectedInvoiceArrayByBonus: [Invoice] = []
// 當前中獎月份
var bonusTableViewHeader = ""

// 頭獎號碼
var jackpotNumberArray: [String: [String]] = [ "2022, 05-06": ["20220518", "87654321"], "2022, 01-02": ["66220202"] ]
// 把前兩個英文字拿掉

// 存放暫時的品項, 目前一次新增一個item
var temporaryItemAndPrice: [Item] = []


func transformDatePickerToString(_ datePicker: UIDatePicker) -> String {
    // 把datePicker轉為YYYY-MM-DD格式的String
    let blankIndexAt = datePicker.date.description.firstIndex(of: " ")!
    let returnString = String(datePicker.date.description[..<blankIndexAt])
    return returnString
}

// 發票號碼格式檢查
func invoiceNumberFormatCheck(_ invoiceNumber: String) -> Bool{
    invoiceNumber.count == 10 && String(invoiceNumber.suffix(8)).isInt &&
    invoiceNumber.prefix(1) >= "A" && invoiceNumber.prefix(1) <= "Z" &&
    invoiceNumber.prefix(2).suffix(1) >= "A" && invoiceNumber.prefix(2).suffix(1) <= "Z"
}

// 新增中獎號碼時, 檢查格式
func bonusNumberFormatCheck(_ invoiceNumber: String) -> Bool {
    invoiceNumber.count == 8 && invoiceNumber.isInt
}

// 發票日期格式檢查
func invoiceDateFormatCheck(_ invoiceDate: String) -> Bool {
    invoiceDate.count == 10 && String(invoiceDate.prefix(4)).isInt &&
    String(invoiceDate.prefix(7).suffix(2)).isInt && String(invoiceDate.suffix(2)).isInt
}

//發票號碼是否唯一
func isUnique(_ invoiceNumber: String) -> Bool {
    for i in Invoice.globalInvoiceArray {
        if i.number == invoiceNumber {
            return false
        }
    }
    return true
}

// 利用店名與品項做關鍵字搜尋
func keywordSearch(_ keyword: String = "") -> [Invoice] {
    print("keyword search")
    let retInvoice = Invoice.globalInvoiceArray.filter { invoice in
        if invoice.storeName.contains(keyword) {
            return true
        }
        let items = invoice.itemAndPrice.filter { item in
            item.itemName.contains(keyword)
        }
        return !items.isEmpty
    }
    
    return retInvoice
}

// 把有相關功能的function放在一起
