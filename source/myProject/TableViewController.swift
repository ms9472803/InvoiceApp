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
    
    // Array shown in the "顯示發票" tableView in day mode
    var currentDayInvoiceArray: [Invoice] = []

    // Month mode
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(exportInvoicesCSV))
        tableView.register(UINib(nibName: "TotalConsumptionOfMonthTableViewCell", bundle: nil), forCellReuseIdentifier: "consumptionOfMonthCell")
        tableView.register(UINib(nibName: "MyCustomTableViewCell", bundle: nil), forCellReuseIdentifier: "customCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemGroupedBackground
        monthOrDaySegmentedControl.selectedSegmentIndex = 1
        // Initial period is determined by the current date rather than a fixed storyboard value
        tableViewShowByMonthLabel.text = currentInvoicePeriod()
        tableViewDatePicker.maximumDate = Date()
        backMonthButton.setTitle(backMonthButtonTitle, for: .normal)
        forwardMonthButton.setTitle(forwardMonthButtonTitle, for: .normal)

    }
    
    
    // Export all invoices as CSV and open the share sheet
    @objc func exportInvoicesCSV() {
        let invoices = Invoice.globalInvoiceArray
        guard !invoices.isEmpty else {
            let alert = UIAlertController(title: "沒有可匯出的發票", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "確定", style: .default))
            present(alert, animated: true)
            return
        }

        let csv = InvoiceCSVExporter.csv(from: invoices)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("invoices.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("匯出 CSV 失敗: \(error.localizedDescription)")
            return
        }

        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        // iPad requires an anchor, otherwise it will crash
        activityVC.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(activityVC, animated: true)
    }

    // Refresh the tableView before the view appears
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
    
    // Handle UITableView appearance
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("按下發票")
        // Deselect the cell
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.row == 0 {
            return
        }
        
        // Set the selected invoice index so invoiceInfoView can be displayed
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
    
    // Number of cells in each section
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
        if indexPath.row == 0 { // The first row shows the total amount
            let cell = tableView.dequeueReusableCell(withIdentifier: "consumptionOfMonthCell", for: indexPath) as? TotalConsumptionOfMonthTableViewCell
            var sum = 0
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
            // Get the cell currently used by the tableView
            let cell = tableView.dequeueReusableCell(withIdentifier: "customCell", for: indexPath) as? MyCustomTableViewCell
            // The first cell is the monthly total consumption, so index - 1
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
    
    
    /* Swipe left to delete an invoice */
    func tableView(_ tableView: UITableView,
    trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.row == 0 {
            return nil;
        }
        let deleteAction = UIContextualAction(style: .destructive, title: "刪除") { (action, view, completionHandler) in
            print("刪除")
            // Delete the invoice from both global and selected arrays
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
    
    // Display the tableView header
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

    // Switch between day/month mode, update tableViewHeader, and set the array to display in the tableView
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
    
    // Select a date in day mode
    @IBAction func changeSelectedDate(_ sender: UIDatePicker) {
        print("選取日期")
        arrayInit()
        dayModeSetting()
        tableView.reloadData()
    }
    
    // Month mode: buttons to move forward/backward
    // Shorten the function by extracting some logic into helper functions, making it easier to follow
    @IBAction func selectedMonth(_ sender: UIButton) {
        arrayInit()
        let curSelectedMonth = tableViewHeader.suffix(5)
        let curSelectedYear = tableViewHeader.prefix(4)
        
        
        if let buttonTitle = sender.currentTitle {
            switch buttonTitle {
            // Left button: go to the previous months
            case backMonthButtonTitle:
                let backCircularSelectedMonth = ["01-02": "11-12", "03-04": "01-02", "05-06": "03-04", "07-08": "05-06", "09-10": "07-08", "11-12": "09-10"]
   
                    var updateYear = String(curSelectedYear)
                    if curSelectedMonth == "01-02" {
                        var intUpdateYear = Int(updateYear) ?? 0
                        intUpdateYear -= 1
                        updateYear = String(intUpdateYear)
                    }
                    
                tableViewShowByMonthLabel.text = "\(updateYear), " + (backCircularSelectedMonth[String(curSelectedMonth)] ?? "")
                

            // Right button: go to the next months
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


