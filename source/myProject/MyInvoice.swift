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
    var category: String = "其他"

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
    
    init(number: String, date: String, storeName: String, itemAndPrice: [Item], category: String = "其他") {
        self.number = number
        self.date = date
        self.storeName = storeName
        self.itemAndPrice = itemAndPrice
        self.category = category
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
    
    
    // 兌獎：依官方統一發票對獎規則計算此發票在指定期別可中的最高獎金，回傳金額字串（未中為 "0"）
    func currentBonusCheck(_ currentBonusMonth: String) -> String {
        // currentBonusMonth 格式為 "2022, 05-06"
        let year = currentBonusMonth.prefix(4)
        let month = currentBonusMonth.suffix(5)
        // 發票日期格式為 2022-05-06，年月不符先 return
        if (date.prefix(4) != year) || ( (date.prefix(7).suffix(2) != month.prefix(2)) && (date.prefix(7).suffix(2) != month.suffix(2)) ) {
            return "0"
        }

        let amount = TaiwanInvoicePrize.amount(
            invoiceNumber: number,
            firstPrizeNumbers: jackpotNumberArray[currentBonusMonth] ?? [],
            specialNumber: specialPrizeNumberArray[currentBonusMonth],
            grandNumber: grandPrizeNumberArray[currentBonusMonth]
        )
        return String(amount)
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


// MARK: - 統一發票對獎規則

// 依財政部統一發票獎別規則計算獎金。
enum TaiwanInvoicePrize {
    static let special = 10_000_000  // 特別獎：對中 8 碼
    static let grand   = 2_000_000   // 特獎：對中 8 碼
    // 頭獎及各獎別：依對中末幾碼決定
    // 8碼=頭獎 20萬, 7碼=二獎 4萬, 6碼=三獎 1萬, 5碼=四獎 4千, 4碼=五獎 1千, 3碼=六獎 2百
    static let firstPrizeTiers: [Int: Int] = [8: 200_000, 7: 40_000, 6: 10_000, 5: 4_000, 4: 1_000, 3: 200]

    /// 計算一張發票可中的最高獎金。
    /// - Parameters:
    ///   - invoiceNumber: 發票號碼（可含前兩碼英文，會自動取末 8 碼數字比對）
    ///   - firstPrizeNumbers: 該期頭獎號碼（可多組，各 8 碼）
    ///   - specialNumber: 該期特別獎號碼（8 碼，可為 nil）
    ///   - grandNumber: 該期特獎號碼（8 碼，可為 nil）
    /// - Returns: 中獎金額（新台幣），未中獎為 0
    static func amount(invoiceNumber: String,
                       firstPrizeNumbers: [String],
                       specialNumber: String? = nil,
                       grandNumber: String? = nil) -> Int {
        let digits = String(invoiceNumber.suffix(8))
        guard digits.count == 8, digits.isInt else { return 0 }

        // 特別獎 / 特獎：需對中全部 8 碼
        if let s = specialNumber, !s.isEmpty, digits == String(s.suffix(8)) {
            return special
        }
        if let g = grandNumber, !g.isEmpty, digits == String(g.suffix(8)) {
            return grand
        }

        // 頭獎及各獎別（含增開六獎）：取對中末碼數最長者
        var best = 0
        for number in firstPrizeNumbers {
            let winning = String(number.suffix(8))
            for matchLength in stride(from: 8, through: 3, by: -1) where digits.count >= matchLength && winning.count >= matchLength {
                if digits.suffix(matchLength) == winning.suffix(matchLength) {
                    best = max(best, firstPrizeTiers[matchLength] ?? 0)
                    break
                }
            }
        }
        return best
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

// 頭獎號碼（每期可有多組，對中末 3~8 碼可得頭獎到六獎）
var jackpotNumberArray: [String: [String]] = [ "2022, 05-06": ["20220518", "87654321"], "2022, 01-02": ["66220202"] ]
// 特別獎號碼（每期一組，對中 8 碼得 1000 萬）
var specialPrizeNumberArray: [String: String] = [:]
// 特獎號碼（每期一組，對中 8 碼得 200 萬）
var grandPrizeNumberArray: [String: String] = [:]
// 把前兩個英文字拿掉

// MARK: - 中獎號碼持久化（存於 UserDefaults，避免重啟後遺失）

private let winningNumbersDefaultsKey = "winningNumbers.v1"

private struct WinningNumbersStore: Codable {
    var jackpot: [String: [String]]
    var special: [String: String]
    var grand: [String: String]
}

func saveWinningNumbers() {
    let store = WinningNumbersStore(jackpot: jackpotNumberArray,
                                    special: specialPrizeNumberArray,
                                    grand: grandPrizeNumberArray)
    if let data = try? JSONEncoder().encode(store) {
        UserDefaults.standard.set(data, forKey: winningNumbersDefaultsKey)
    }
}

func loadWinningNumbers() {
    guard let data = UserDefaults.standard.data(forKey: winningNumbersDefaultsKey),
          let store = try? JSONDecoder().decode(WinningNumbersStore.self, from: data) else {
        return
    }
    jackpotNumberArray = store.jackpot
    specialPrizeNumberArray = store.special
    grandPrizeNumberArray = store.grand
}

// MARK: - 從財政部開放資料取得中獎號碼

// 財政部「統一發票中獎號碼」開放資料 RSS，包含最近數期的特別獎/特獎/頭獎號碼。
enum WinningNumberService {
    static let feedURLString = "https://invoice.etax.nat.gov.tw/invoice.xml"

    enum ServiceError: Error { case badURL, network, parse }

    struct Period {
        let key: String          // 期別，格式 "YYYY, MM-MM"
        let special: String?     // 特別獎（8 碼）
        let grand: String?       // 特獎（8 碼）
        let firstPrizes: [String] // 頭獎（多組 8 碼）
    }

    /// 下載並解析最新中獎號碼，更新全域資料並持久化。完成回呼回傳更新的期數。
    static func update(completion: @escaping (Result<Int, Error>) -> Void) {
        guard let url = URL(string: feedURLString) else {
            DispatchQueue.main.async { completion(.failure(ServiceError.badURL)) }
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                if error != nil {
                    completion(.failure(ServiceError.network)); return
                }
                guard let data = data, let xml = String(data: data, encoding: .utf8) else {
                    completion(.failure(ServiceError.parse)); return
                }
                let periods = parse(xml)
                guard !periods.isEmpty else {
                    completion(.failure(ServiceError.parse)); return
                }
                apply(periods)
                saveWinningNumbers()
                completion(.success(periods.count))
            }
        }.resume()
    }

    /// 解析 RSS XML，回傳各期中獎號碼。（公開以便單元測試）
    static func parse(_ xml: String) -> [Period] {
        var periods: [Period] = []
        for item in matches(in: xml, pattern: "<item>(.*?)</item>", dotAll: true).map({ $0[1] }) {
            guard let title = firstGroup(item, "<title><!\\[CDATA\\[(.*?)\\]\\]></title>", dotAll: true),
                  let desc = firstGroup(item, "<description><!\\[CDATA\\[(.*?)\\]\\]></description>", dotAll: true),
                  let key = periodKey(fromTitle: title) else { continue }

            let special = firstGroup(desc, "特別獎：(\\d{8})")
            let grand = firstGroup(desc, "特獎：(\\d{8})")
            var firstPrizes: [String] = []
            if let section = firstGroup(desc, "頭獎：([\\d、,]+)") {
                firstPrizes = matches(in: section, pattern: "(\\d{8})").map { $0[1] }
            }
            periods.append(Period(key: key, special: special, grand: grand, firstPrizes: firstPrizes))
        }
        return periods
    }

    /// 把標題（如「115年 03~04月」）轉成期別 key「2026, 03-04」。
    static func periodKey(fromTitle title: String) -> String? {
        guard let rocString = firstGroup(title, "(\\d+)年"), let roc = Int(rocString) else { return nil }
        guard let monthGroups = matches(in: title, pattern: "(\\d{1,2})\\s*[~～\\-]\\s*(\\d{1,2})\\s*月").first else { return nil }
        let adYear = roc + 1911
        let m1 = String(format: "%02d", Int(monthGroups[1]) ?? 0)
        let m2 = String(format: "%02d", Int(monthGroups[2]) ?? 0)
        return "\(adYear), \(m1)-\(m2)"
    }

    private static func apply(_ periods: [Period]) {
        for period in periods {
            if let special = period.special { specialPrizeNumberArray[period.key] = special }
            if let grand = period.grand { grandPrizeNumberArray[period.key] = grand }
            if !period.firstPrizes.isEmpty { jackpotNumberArray[period.key] = period.firstPrizes }
        }
    }

    // MARK: Regex 小工具

    private static func matches(in text: String, pattern: String, dotAll: Bool = false) -> [[String]] {
        var options: NSRegularExpression.Options = []
        if dotAll { options.insert(.dotMatchesLineSeparators) }
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return [] }
        let nsText = text as NSString
        return regex.matches(in: text, range: NSRange(location: 0, length: nsText.length)).map { match in
            (0..<match.numberOfRanges).map { index in
                let range = match.range(at: index)
                return range.location == NSNotFound ? "" : nsText.substring(with: range)
            }
        }
    }

    private static func firstGroup(_ text: String, _ pattern: String, dotAll: Bool = false) -> String? {
        guard let groups = matches(in: text, pattern: pattern, dotAll: dotAll).first, groups.count > 1 else { return nil }
        return groups[1]
    }
}

// 存放暫時的品項, 目前一次新增一個item
var temporaryItemAndPrice: [Item] = []

// 可選的消費分類
let invoiceCategories = ["餐飲", "交通", "購物", "娛樂", "醫療", "其他"]


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

// MARK: - CSV 匯出

// 把發票資料匯出成 CSV 字串，供「分享 / 匯出」功能使用。
enum InvoiceCSVExporter {
    static func csv(from invoices: [Invoice]) -> String {
        // 處理含有逗號、引號、換行的欄位
        func escape(_ field: String) -> String {
            if field.contains(",") || field.contains("\"") || field.contains("\n") {
                return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
            }
            return field
        }

        var lines = ["發票號碼,日期,店名,品項,數量,金額"]
        for invoice in invoices {
            if invoice.itemAndPrice.isEmpty {
                let row = [invoice.number, invoice.date, invoice.storeName, "", "", ""]
                lines.append(row.map(escape).joined(separator: ","))
            } else {
                for item in invoice.itemAndPrice {
                    let row = [invoice.number, invoice.date, invoice.storeName, item.itemName, item.amount, item.price]
                    lines.append(row.map(escape).joined(separator: ","))
                }
            }
        }
        // 加上 UTF-8 BOM，讓 Excel 正確顯示中文
        return "\u{FEFF}" + lines.joined(separator: "\n")
    }
}

// 把有相關功能的function放在一起
