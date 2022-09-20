//
//  testViewController.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/17.
//

import UIKit
import SwiftUI


class TableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var monthOrDaySegmentedControl: UISegmentedControl!
    @IBOutlet weak var tableViewShowByMonthLabel: UILabel!
    @IBOutlet weak var backMonthButton: UIButton!
    @IBOutlet weak var forwardMonthButton: UIButton!
    @IBOutlet weak var tableViewDatePicker: UIDatePicker!
    
    
    var backMonthButtonTitle = "\u{2190}"
    var forwardMonthButtonTitle = "\u{2192}"
    var tableViewHeader = ""
    
    // 日模式顯示在"顯示發票"tableView上的array
    var currentDayInvoiceArray: [Invoice] = []
    
    // 月模式
    var currentFirstMonth = ""
    var currentSecondMonth = ""
    var currentFirstMonthInvoice: [Invoice] = []
    var currentSecondMonthInvoice: [Invoice] = []
    
    enum Mode {
        case dayMode
        case monthMode
    }
    var mode = Mode.monthMode
    
    /*enum CurrentMonth {
        case first
        case second
    }*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "顯示發票"
        tableView.register(UINib(nibName: "TotalConsumptionOfMonthTableViewCell", bundle: nil), forCellReuseIdentifier: "consumptionOfMonthCell")
        tableView.register(UINib(nibName: "MyCustomTableViewCell", bundle: nil), forCellReuseIdentifier: "customCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        monthOrDaySegmentedControl.selectedSegmentIndex = 1
        tableViewDatePicker.maximumDate = Date()
        backMonthButton.setTitle(backMonthButtonTitle, for: .normal)
        forwardMonthButton.setTitle(forwardMonthButtonTitle, for: .normal)

    }
    
    
    // 在view呈現前 刷新tableView
    override func viewWillAppear(_ animated: Bool) {
        arrayInit()
        monthModeSetting()
        tableView.reloadData()
    }

    
    func arrayInit() {
        currentFirstMonthInvoice = []
        currentSecondMonthInvoice = []
        currentDayInvoiceArray = []
    }
    
    func monthModeSetting() {
        
        mode = .monthMode
        monthOrDaySegmentedControl.selectedSegmentIndex = 1
        tableViewShowByMonthLabel.isHidden = false
        backMonthButton.isHidden = false
        forwardMonthButton.isHidden = false
        tableViewDatePicker.isHidden = true
        tableViewHeader = tableViewShowByMonthLabel.text ?? ""
        
        let year = tableViewHeader.prefix(4)
        currentFirstMonth = String(tableViewHeader.suffix(5).prefix(2))
        currentSecondMonth = String(tableViewHeader.suffix(5).suffix(2))

        currentFirstMonthInvoice = Invoice.globalInvoiceArray.filter { $0.date.prefix(4) == year && $0.date.prefix(7).suffix(2) == currentFirstMonth }
        currentSecondMonthInvoice = Invoice.globalInvoiceArray.filter { $0.date.prefix(4) == year && $0.date.prefix(7).suffix(2) == currentSecondMonth}
    }
    
    func dayModeSetting() {
        mode = .dayMode
        tableViewShowByMonthLabel.isHidden = true
        backMonthButton.isHidden = true
        forwardMonthButton.isHidden = true
        tableViewDatePicker.isHidden = false
        
        tableViewHeader = transformDatePickerToString(tableViewDatePicker)
        currentDayInvoiceArray = Invoice.globalInvoiceArray.filter { $0.date.description == tableViewHeader }
    }
    
    // 處理UITableView外觀
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("按下發票")
        // 取消cell的選取狀態
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.row == 0 {
            return
        }
        
        // 設定選取的發票index, 讓invoiceInfoView呈現出來
        let invoiceIndex = indexPath.row - 1
        
        switch mode {
        case .dayMode:
            Invoice.invoiceShowCurrent = currentDayInvoiceArray[invoiceIndex]
        case .monthMode:
            if indexPath.section == 0 {
                Invoice.invoiceShowCurrent = currentFirstMonthInvoice[invoiceIndex]
            } else {
                Invoice.invoiceShowCurrent = currentSecondMonthInvoice[invoiceIndex]
            }
        }
    
        self.navigationController?.pushViewController(InvoiceInfoViewController(), animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        switch mode {
        case .dayMode:
            return 1
        case .monthMode:
            return 2
        }
    }
    
    // 每一組有幾個 cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch mode {
        case .dayMode:
            return currentDayInvoiceArray.count + 1
        case .monthMode:
            if section == 0 {
                return currentFirstMonthInvoice.count + 1
            } else {
                return currentSecondMonthInvoice.count + 1
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 { // 第一個 row 顯示總金額
            let cell = tableView.dequeueReusableCell(withIdentifier: "consumptionOfMonthCell", for: indexPath) as? TotalConsumptionOfMonthTableViewCell
            var sum = 0
            cell?.backgroundColor = .yellow
            switch mode {
            case .dayMode:
                cell?.monthLabel.text = " 總消費"
                sum = currentDayInvoiceArray.reduce(0) { total, invoice in
                    return total + (Int(invoice.totalPrice) ?? 0)
                }
            case .monthMode:
                if indexPath.section == 0 {
                    cell?.monthLabel.text = currentFirstMonth + " 總消費"
                    sum = currentFirstMonthInvoice.reduce(0) { total, invoice in
                        return total + (Int(invoice.totalPrice) ?? 0)
                    }
                    
                } else {
                    cell?.monthLabel.text = currentSecondMonth + " 總消費"
                    sum = currentSecondMonthInvoice.reduce(0) { total, invoice in
                        return total + (Int(invoice.totalPrice) ?? 0)
                    }
                }
            }
            
            cell?.consumptionlabel.text = "$" + String(sum)
            return cell!
        } else {
            // 取得 tableView 目前使用的 cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "customCell", for: indexPath) as? MyCustomTableViewCell
            // 第一個cell為總月份消費, 所以index - 1
            let invoiceIndex = indexPath.row - 1
            var invoice = Invoice();
            
            
            switch mode {
            case .dayMode:
                invoice = currentDayInvoiceArray[invoiceIndex]
            case .monthMode:
                if indexPath.section == 0 {
                    invoice = currentFirstMonthInvoice[invoiceIndex]
                } else {
                    invoice = currentSecondMonthInvoice[invoiceIndex]
                }
            }
            cell?.numberLabel.text = invoice.number
            cell?.dateLabel.text = String(invoice.date.suffix(2))
            cell?.totalPriceLabel.text = "$" + invoice.totalPrice
            cell?.storeLabel.text = invoice.storeName
            
            if (cell?.storeLabel.text ?? "").isEmpty {
                cell?.storeLabel.text = "(無店名)"
            }
            return cell!
        }

    }
    
    
    /* 往左滑刪除發票 */
    func tableView(_ tableView: UITableView,
    trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.row == 0 {
            return nil;
        }
        let deleteAction = UIContextualAction(style: .destructive, title: "刪除") { (action, view, completionHandler) in
            print("刪除")
            // 刪除global和selected裡面的invoice
            let deleteInvoice: Invoice
            let invoiceIndex = indexPath.row - 1
            
            switch self.mode {
            case .dayMode:
                deleteInvoice = self.currentDayInvoiceArray[invoiceIndex]
                self.currentDayInvoiceArray.remove(at: invoiceIndex)
            case .monthMode:
                if indexPath.section == 0 {
                    deleteInvoice = self.currentFirstMonthInvoice[invoiceIndex]
                    self.currentFirstMonthInvoice.remove(at: invoiceIndex)
                } else {
                    deleteInvoice = self.currentSecondMonthInvoice[invoiceIndex]
                    self.currentSecondMonthInvoice.remove(at: invoiceIndex)
                }
            }
            
            let invoiceDB = MyDatabase()
            invoiceDB.removeInvoiceFromDB(deleteInvoice.number)
            Invoice.globalInvoiceArray = Invoice.globalInvoiceArray.filter {$0.number != deleteInvoice.number}
            
            tableView.reloadData()
            completionHandler(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    // 顯示tableView header
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch mode {
        case .dayMode:
            return ""
        case .monthMode:
            var sectionHeader = ""
            if section == 0 {
                sectionHeader = String(tableViewHeader.prefix(8))
            } else {
                sectionHeader = String(tableViewHeader.prefix(5)) + " " + String(tableViewHeader.suffix(2))
            }
            return sectionHeader
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    // 更改日月模式, 改tableViewHeader, 設定要在tableView顯示的array
    @IBAction func dayOrMonthChange(_ sender: UISegmentedControl) {
        print("dayMonthChange")
        arrayInit()
        switch mode {
        case .dayMode:
            monthModeSetting()
        case .monthMode:
            dayModeSetting()
        }
        
        tableView.reloadData()
    }
    
    // 日期模式選取日期
    @IBAction func changeSelectedDate(_ sender: UIDatePicker) {
        print("選取日期")
        arrayInit()
        dayModeSetting()
        tableView.reloadData()
    }
    
    // 月份模式 按鈕選取往前往後
    // function行數減短一點, 把一些功能抽成function, 這樣比較知道在幹嘛
    @IBAction func selectedMonth(_ sender: UIButton) {
        arrayInit()
        let curSelectedMonth = tableViewHeader.suffix(5)
        let curSelectedYear = tableViewHeader.prefix(4)
        
        
        if let buttonTitle = sender.currentTitle {
            switch buttonTitle {
            // 往左按鈕 月份往前
            case backMonthButtonTitle:
                let backCircularSelectedMonth = ["01-02": "11-12", "03-04": "01-02", "05-06": "03-04", "07-08": "05-06", "09-10": "07-08", "11-12": "09-10"]
   
                    var updateYear = String(curSelectedYear)
                    if curSelectedMonth == "01-02" {
                        var intUpdateYear = Int(updateYear) ?? 0
                        intUpdateYear -= 1
                        updateYear = String(intUpdateYear)
                    }
                    
                tableViewShowByMonthLabel.text = "\(updateYear), " + (backCircularSelectedMonth[String(curSelectedMonth)] ?? "")
                

            // 往右按鈕 月份往後
            case forwardMonthButtonTitle:
                let forwardCircularSelectedMonth = ["01-02": "03-04", "03-04": "05-06", "05-06": "07-08", "07-08": "09-10", "09-10": "11-12", "11-12":  "01-02"]
                
                    var updateYear = String(curSelectedYear)
                    if curSelectedMonth == "11-12" {
                        var intUpdateYear = Int(updateYear) ?? 0
                        intUpdateYear += 1
                        updateYear = String(intUpdateYear)
                    }
                    
                tableViewShowByMonthLabel.text = "\(updateYear), " + (forwardCircularSelectedMonth[String(curSelectedMonth)] ?? "")
                
            default:
                print("title not match")
            }
        }
        
        monthModeSetting()
        tableView.reloadData()
    }
    
    
}


