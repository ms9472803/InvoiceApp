//
//  myInvoice.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/26.
//

import Foundation
import UIKit


// Extract these two structs into a separate file

// @objcMembers exposes all of the Swift class's methods and properties to Objective-C
// If you only need to expose a single property, use @objc instead

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

// Keep each variable in its proper type; only convert when rendering it in the UI
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
            if globalInvoiceArray.count == oldValue.count + 1 { // keep sorted on append
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
    
    // revise
    func printInfo() {
        print(number, date, storeName, totalPrice)
        for i in itemAndPrice {
            print(i.itemName, i.amount, i.price)
        }
        print("\n")
    }
    
    
    // Prize check: compute the highest prize this invoice can win in the given period per the official uniform invoice rules, returning the amount as a string ("0" if no win)
    func currentBonusCheck(_ currentBonusMonth: String) -> String {
        // currentBonusMonth is formatted as "2022, 05-06"
        let year = currentBonusMonth.prefix(4)
        let month = currentBonusMonth.suffix(5)
        // The invoice date is formatted as 2022-05-06; return early if the year/month doesn't match
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
    // Randomly generate an invoice
    // There is a struct named generator
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


// MARK: - Uniform Invoice Prize Rules

// Computes the prize amount per the Ministry of Finance uniform invoice prize tiers.
enum TaiwanInvoicePrize {
    static let special = 10_000_000  // Special prize: match all 8 digits
    static let grand   = 2_000_000   // Grand prize: match all 8 digits
    // First prize and other tiers: determined by how many trailing digits match
    // 8 digits = first prize 200k, 7 = second 40k, 6 = third 10k, 5 = fourth 4k, 4 = fifth 1k, 3 = sixth 200
    static let firstPrizeTiers: [Int: Int] = [8: 200_000, 7: 40_000, 6: 10_000, 5: 4_000, 4: 1_000, 3: 200]

    /// Computes the highest prize an invoice can win.
    /// - Parameters:
    ///   - invoiceNumber: invoice number (may include the leading two letters; the last 8 digits are taken automatically for comparison)
    ///   - firstPrizeNumbers: this period's first-prize numbers (may be multiple, each 8 digits)
    ///   - specialNumber: this period's special-prize number (8 digits, may be nil)
    ///   - grandNumber: this period's grand-prize number (8 digits, may be nil)
    /// - Returns: prize amount (TWD), or 0 if no win
    static func amount(invoiceNumber: String,
                       firstPrizeNumbers: [String],
                       specialNumber: String? = nil,
                       grandNumber: String? = nil) -> Int {
        let digits = String(invoiceNumber.suffix(8))
        guard digits.count == 8, digits.isInt else { return 0 }

        // Special / grand prize: must match all 8 digits
        if let s = specialNumber, !s.isEmpty, digits == String(s.suffix(8)) {
            return special
        }
        if let g = grandNumber, !g.isEmpty, digits == String(g.suffix(8)) {
            return grand
        }

        // First prize and other tiers (including the additional sixth prize): take the longest trailing-digit match
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
// Seed dummy data for now; later, fetch invoice data from the DB and put it into globalInvoiceArray
// Array holding all invoices, changed to a type property
/*var globalInvoiceArray: [Invoice] = [] {
    didSet {
        //print("globalInvoiceArray didSet")
        if globalInvoiceArray.count == oldValue.count + 1 { // keep sorted on append
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

// Shown in the "顯示發票" tableView, or which invoice is tapped during search; changed to a type property
//var invoiceShowCurrent = Invoice(number: "", date: "", storeName: "", itemAndPrice: [])

// Array shown in the "確認中獎" tableView
var selectedInvoiceArrayByBonus: [Invoice] = []
// Current prize-drawing month
var bonusTableViewHeader = ""

// First-prize numbers (each period may have multiple; matching the last 3~8 digits wins first through sixth prize)
var jackpotNumberArray: [String: [String]] = [ "2022, 05-06": ["20220518", "87654321"], "2022, 01-02": ["66220202"] ]
// Special-prize number (one per period; matching all 8 digits wins 10 million)
var specialPrizeNumberArray: [String: String] = [:]
// Grand-prize number (one per period; matching all 8 digits wins 2 million)
var grandPrizeNumberArray: [String: String] = [:]
// Strip off the leading two letters

// MARK: - Persisting winning numbers (stored in UserDefaults to survive restarts)

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

// MARK: - Fetching winning numbers from the Ministry of Finance open data

// The Ministry of Finance "uniform invoice winning numbers" open-data RSS, containing the special/grand/first-prize numbers for the most recent periods.
enum WinningNumberService {
    static let feedURLString = "https://invoice.etax.nat.gov.tw/invoice.xml"

    enum ServiceError: Error { case badURL, network, parse }

    struct Period {
        let key: String          // period, formatted "YYYY, MM-MM"
        let special: String?     // special prize (8 digits)
        let grand: String?       // grand prize (8 digits)
        let firstPrizes: [String] // first prizes (multiple 8-digit numbers)
    }

    /// Downloads and parses the latest winning numbers, updates global data, and persists it. The completion handler returns the number of periods updated.
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

    /// Parses the RSS XML and returns the winning numbers for each period. (Public to allow unit testing.)
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

    /// Converts a title (e.g. "115年 03~04月") into the period key "2026, 03-04".
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

    // MARK: Regex helpers

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

// Holds temporary items; currently one item is added at a time
var temporaryItemAndPrice: [Item] = []

// Available spending categories
let invoiceCategories = ["餐飲", "交通", "購物", "娛樂", "醫療", "其他"]


func transformDatePickerToString(_ datePicker: UIDatePicker) -> String {
    // Convert the datePicker to a YYYY-MM-DD formatted String
    let blankIndexAt = datePicker.date.description.firstIndex(of: " ")!
    let returnString = String(datePicker.date.description[..<blankIndexAt])
    return returnString
}

// Returns the current invoice period for a date (one period per two months), formatted "YYYY, MM-MM", e.g. "2026, 05-06"
func currentInvoicePeriod(_ date: Date = Date()) -> String {
    let calendar = Calendar.current
    let year = calendar.component(.year, from: date)
    let month = calendar.component(.month, from: date)
    let startMonth = ((month - 1) / 2) * 2 + 1   // 1,3,5,7,9,11
    let endMonth = startMonth + 1
    return String(format: "%d, %02d-%02d", year, startMonth, endMonth)
}

// Invoice number format check
func invoiceNumberFormatCheck(_ invoiceNumber: String) -> Bool{
    invoiceNumber.count == 10 && String(invoiceNumber.suffix(8)).isInt &&
    invoiceNumber.prefix(1) >= "A" && invoiceNumber.prefix(1) <= "Z" &&
    invoiceNumber.prefix(2).suffix(1) >= "A" && invoiceNumber.prefix(2).suffix(1) <= "Z"
}

// Check the format when adding a winning number
func bonusNumberFormatCheck(_ invoiceNumber: String) -> Bool {
    invoiceNumber.count == 8 && invoiceNumber.isInt
}

// Invoice date format check
func invoiceDateFormatCheck(_ invoiceDate: String) -> Bool {
    invoiceDate.count == 10 && String(invoiceDate.prefix(4)).isInt &&
    String(invoiceDate.prefix(7).suffix(2)).isInt && String(invoiceDate.suffix(2)).isInt
}

// Whether the invoice number is unique
func isUnique(_ invoiceNumber: String) -> Bool {
    for i in Invoice.globalInvoiceArray {
        if i.number == invoiceNumber {
            return false
        }
    }
    return true
}

// Keyword search using store name and items
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

// MARK: - CSV Export

// Exports invoice data into a CSV string for use by the "share / export" feature.
enum InvoiceCSVExporter {
    static func csv(from invoices: [Invoice]) -> String {
        // Handle fields containing commas, quotes, or newlines
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
        // Add a UTF-8 BOM so Excel displays Chinese correctly
        return "\u{FEFF}" + lines.joined(separator: "\n")
    }
}

// Group related functions together
