//
//  BobusViewController.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/20.
//

import UIKit

class BonusViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var bonusTableView: UITableView!
    @IBOutlet weak var bonusMonthLabel: UILabel!
    
    @IBOutlet weak var backMonthButton: UIButton!
    @IBOutlet weak var forwardMonthButton: UIButton!
    @IBOutlet weak var bonusNumberTextField: UITextField!
    @IBOutlet weak var bonusNumberTextView: UITextView!
    var backMonthButtonTitle = "\u{2190}"
    var forwardMonthButtonTitle = "\u{2192}"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        bonusTableView.register(UINib(nibName: "MyCustomTableViewCell", bundle: nil), forCellReuseIdentifier: "customCell")
        bonusTableView.delegate = self
        bonusTableView.dataSource = self
        bonusTableView.separatorStyle = .none
        
        bonusTableViewHeader = bonusMonthLabel.text!
        
        backMonthButton.setTitle(backMonthButtonTitle, for: .normal)
        forwardMonthButton.setTitle(forwardMonthButtonTitle, for: .normal)
        bonusNumberTextField.clearButtonMode = .always
        bonusNumberTextView.isEditable = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //selectedInvoiceArrayByBonus = []
        
        /*for invoice in globalInvoiceArray {
            if invoice.currentBonusCheck(bonusTableViewHeader) != "0" {
                selectedInvoiceArrayByBonus.append(invoice)
            }
        }*/
        
        refreshBonusNumberDisplay()

        bonusTableView.reloadData()
    }

    // 把本期各獎別的中獎號碼整理顯示在 textView 上
    private func refreshBonusNumberDisplay() {
        var text = ""
        if let special = specialPrizeNumberArray[bonusTableViewHeader] {
            text += "特別獎: \(special.suffix(8))\n"
        }
        if let grand = grandPrizeNumberArray[bonusTableViewHeader] {
            text += "特獎: \(grand.suffix(8))\n"
        }
        if let firstPrizes = jackpotNumberArray[bonusTableViewHeader] {
            for number in firstPrizes {
                text += "頭獎: \(number.suffix(8))\n"
            }
        }
        bonusNumberTextView.text = text
    }
    
    /*/* 顯示tableView header */
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        bonusTableViewHeader
    }*/
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("按下發票")
        
        // 取消cell的選取狀態
        bonusTableView.deselectRow(at: indexPath, animated: false)
        
        
        Invoice.invoiceShowCurrent = selectedInvoiceArrayByBonus[indexPath.row]
        self.navigationController?.pushViewController(InvoiceInfoViewController(), animated: true)
        /*
        // 設定選取的發票index, 讓invoiceInfoView呈現出來
        invoiceIndex = indexPath.row
        print(invoiceIndex)
        //goInvoiceInfo()*/
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if selectedInvoiceArrayByBonus.isEmpty {
            bonusTableView.setEmptyMessage("按下「確認中獎」以列出本期中獎發票")
        } else {
            bonusTableView.setEmptyMessage(nil)
        }
        return selectedInvoiceArrayByBonus.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "customCell", for: indexPath) as? MyCustomTableViewCell
        
        cell?.numberLabel.text = selectedInvoiceArrayByBonus[indexPath.row].number
        cell?.dateLabel.text = selectedInvoiceArrayByBonus[indexPath.row].date
        cell?.totalPriceLabel.text = "獎金: " + selectedInvoiceArrayByBonus[indexPath.row].currentBonusCheck(bonusTableViewHeader)
        cell?.storeLabel.text = selectedInvoiceArrayByBonus[indexPath.row].storeName
        if selectedInvoiceArrayByBonus[indexPath.row].storeName.isEmpty {
            cell?.storeLabel.text = "(無店名)"
        }
        
        
        return cell!
    }
    
    
    
    @IBAction func selectedMonth(_ sender: UIButton) {
        selectedInvoiceArrayByBonus = []
        bonusTableView.reloadData()
        
        bonusNumberTextField.text = ""
        let curSelectedMonth = bonusMonthLabel.text?.suffix(5)
        let curSelectedYear = bonusMonthLabel.text?.prefix(4)
        if let title = sender.currentTitle {
            switch title {
            // 往左按鈕 月份往前
            case backMonthButtonTitle:
                let backCircularSelectedMonth = ["01-02": "11-12", "03-04": "01-02", "05-06": "03-04", "07-08": "05-06", "09-10": "07-08", "11-12": "09-10"]
                if let month = curSelectedMonth, let year = curSelectedYear {
                    var updateYear = String(year)
                    if month == "01-02" {
                        var intUpdateYear = Int(updateYear) ?? 0
                        intUpdateYear -= 1
                        updateYear = String(intUpdateYear)
                    }
                    
                    bonusMonthLabel.text = "\(updateYear), " + backCircularSelectedMonth[String(month)]!
                }

            // 往右按鈕 月份往後
            case forwardMonthButtonTitle:
                let forwardCircularSelectedMonth = ["01-02": "03-04", "03-04": "05-06", "05-06": "07-08", "07-08": "09-10", "09-10": "11-12", "11-12":  "01-02"]
                if let month = curSelectedMonth, let year = curSelectedYear {
                    var updateYear = String(year)
                    if month == "11-12" {
                        var intUpdateYear = Int(updateYear) ?? 0
                        intUpdateYear += 1
                        updateYear = String(intUpdateYear)
                    }
                    
                    bonusMonthLabel.text = "\(updateYear), " + forwardCircularSelectedMonth[String(month)]!
                }
            default:
                print("title not match")
            }
        }
        
        bonusTableViewHeader = bonusMonthLabel.text!

        refreshBonusNumberDisplay()
    }
    
    
    private enum PrizeCategory {
        case special  // 特別獎
        case grand    // 特獎
        case first    // 頭獎（含各獎別）
    }

    @IBAction func addBonusNumber(_ sender: UIButton) {
        print("新增中獎號碼")
        let bonusNumber = bonusNumberTextField.text ?? ""

        /* 檢查發票號碼格式（8 位數字） */
        guard bonusNumberFormatCheck(bonusNumber) else {
            showSimpleAlert(title: "儲存失敗", message: "中獎號碼需為 8 位數字")
            return
        }
        /* 檢查是否已存在於任一獎別 */
        guard !isBonusNumberTaken(bonusNumber) else {
            showSimpleAlert(title: "新增失敗", message: "號碼已存在")
            return
        }

        // 讓使用者選擇此號碼的獎別
        let sheet = UIAlertController(title: "選擇獎別", message: "請選擇此中獎號碼的獎別", preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "特別獎（1000萬）", style: .default) { _ in self.store(bonusNumber, as: .special) })
        sheet.addAction(UIAlertAction(title: "特獎（200萬）", style: .default) { _ in self.store(bonusNumber, as: .grand) })
        sheet.addAction(UIAlertAction(title: "頭獎（含各獎別）", style: .default) { _ in self.store(bonusNumber, as: .first) })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        // iPad 需要 anchor，否則會 crash
        sheet.popoverPresentationController?.sourceView = sender
        sheet.popoverPresentationController?.sourceRect = sender.bounds
        present(sheet, animated: true)
    }

    private func isBonusNumberTaken(_ number: String) -> Bool {
        if specialPrizeNumberArray[bonusTableViewHeader] == number { return true }
        if grandPrizeNumberArray[bonusTableViewHeader] == number { return true }
        if jackpotNumberArray[bonusTableViewHeader]?.contains(number) == true { return true }
        return false
    }

    private func store(_ number: String, as category: PrizeCategory) {
        switch category {
        case .special:
            specialPrizeNumberArray[bonusTableViewHeader] = number
        case .grand:
            grandPrizeNumberArray[bonusTableViewHeader] = number
        case .first:
            jackpotNumberArray[bonusTableViewHeader, default: []].append(number)
        }
        bonusNumberTextField.text = ""
        refreshBonusNumberDisplay()
        showSimpleAlert(title: "新增成功", message: nil)
    }

    private func showSimpleAlert(title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }
    
    @IBAction func checkBonus(_ sender: UIButton) {
        selectedInvoiceArrayByBonus = []
        for invoice in Invoice.globalInvoiceArray {
            if invoice.currentBonusCheck(bonusTableViewHeader) != "0" {
                selectedInvoiceArrayByBonus.append(invoice)
            }
        }
        bonusTableView.reloadData()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

