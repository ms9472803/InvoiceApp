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
        bonusTableView.backgroundColor = .systemGroupedBackground

        // 初始期別依當下日期決定，而非 storyboard 固定值
        bonusMonthLabel.text = currentInvoicePeriod()
        bonusTableViewHeader = bonusMonthLabel.text!
        
        backMonthButton.setTitle(backMonthButtonTitle, for: .normal)
        forwardMonthButton.setTitle(forwardMonthButtonTitle, for: .normal)
        // Winning numbers now come from the network; hide the manual input field
        bonusNumberTextField.isHidden = true
        bonusNumberTextView.isEditable = false
        bonusNumberTextView.font = .systemFont(ofSize: 15)
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
    
    
    // 中獎號碼改由財政部開放資料取得，使用者不再自行新增。
    // 沿用 storyboard 既有的 addBonusNumber: 連線，改為「更新中獎號碼」動作。
    @IBAction func addBonusNumber(_ sender: UIButton) {
        sender.isEnabled = false
        WinningNumberService.update { [weak self] result in
            sender.isEnabled = true
            switch result {
            case .success(let count):
                self?.refreshBonusNumberDisplay()
                self?.bonusTableView.reloadData()
                self?.showSimpleAlert(title: "已更新中獎號碼", message: "已從財政部取得 \(count) 期開獎號碼")
            case .failure:
                self?.showSimpleAlert(title: "更新失敗", message: "無法連線取得中獎號碼，請稍後再試。")
            }
        }
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

