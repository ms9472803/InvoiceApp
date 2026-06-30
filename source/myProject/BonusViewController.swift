//
//  BobusViewController.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/20.
//

import UIKit

class BonusViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{

    // UI built programmatically (no storyboard)
    private let bonusTableView = UITableView(frame: .zero, style: .plain)
    private let bonusMonthLabel = UILabel()
    private let backMonthButton = UIButton(type: .system)
    private let forwardMonthButton = UIButton(type: .system)
    private let bonusNumberTextView = UITextView()
    var backMonthButtonTitle = "\u{2190}"
    var forwardMonthButtonTitle = "\u{2192}"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "確認中獎"

        // Determine the initial period from the current date instead of a fixed storyboard value
        bonusMonthLabel.text = currentInvoicePeriod()
        bonusMonthLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        bonusMonthLabel.textAlignment = .center
        bonusTableViewHeader = bonusMonthLabel.text!

        backMonthButton.setTitle(backMonthButtonTitle, for: .normal)
        forwardMonthButton.setTitle(forwardMonthButtonTitle, for: .normal)
        backMonthButton.titleLabel?.font = .systemFont(ofSize: 22)
        forwardMonthButton.titleLabel?.font = .systemFont(ofSize: 22)
        backMonthButton.addTarget(self, action: #selector(selectedMonth(_:)), for: .touchUpInside)
        forwardMonthButton.addTarget(self, action: #selector(selectedMonth(_:)), for: .touchUpInside)

        let updateButton = actionButton("更新中獎號碼", action: #selector(addBonusNumber(_:)))
        let checkButton = actionButton("兌獎", action: #selector(checkBonus(_:)))

        let titleLabel = UILabel()
        titleLabel.text = "本期中獎號碼"
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = .secondaryLabel

        bonusNumberTextView.isEditable = false
        bonusNumberTextView.font = .systemFont(ofSize: 15)
        bonusNumberTextView.backgroundColor = .secondarySystemBackground
        bonusNumberTextView.layer.cornerRadius = 10
        bonusNumberTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        bonusTableView.register(UINib(nibName: "MyCustomTableViewCell", bundle: nil), forCellReuseIdentifier: "customCell")
        bonusTableView.delegate = self
        bonusTableView.dataSource = self
        bonusTableView.separatorStyle = .none
        bonusTableView.backgroundColor = .systemGroupedBackground

        let monthRow = UIStackView(arrangedSubviews: [backMonthButton, bonusMonthLabel, forwardMonthButton])
        monthRow.axis = .horizontal
        monthRow.distribution = .equalSpacing
        monthRow.alignment = .center

        let actionRow = UIStackView(arrangedSubviews: [updateButton, checkButton])
        actionRow.axis = .horizontal
        actionRow.spacing = 12
        actionRow.distribution = .fillEqually

        let topStack = UIStackView(arrangedSubviews: [monthRow, actionRow, titleLabel, bonusNumberTextView])
        topStack.axis = .vertical
        topStack.spacing = 12
        topStack.translatesAutoresizingMaskIntoConstraints = false
        bonusTableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(topStack)
        view.addSubview(bonusTableView)
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            topStack.topAnchor.constraint(equalTo: guide.topAnchor, constant: 12),
            topStack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            topStack.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            monthRow.leadingAnchor.constraint(equalTo: topStack.leadingAnchor),
            monthRow.trailingAnchor.constraint(equalTo: topStack.trailingAnchor),
            bonusNumberTextView.heightAnchor.constraint(equalToConstant: 130),

            bonusTableView.topAnchor.constraint(equalTo: topStack.bottomAnchor, constant: 12),
            bonusTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bonusTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bonusTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func actionButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
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

    // Format and display this period's winning numbers for each prize tier in the textView
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
    
    /*/* Display the tableView header */
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        bonusTableViewHeader
    }*/
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("按下發票")

        // Clear the cell's selected state
        bonusTableView.deselectRow(at: indexPath, animated: false)
        
        
        Invoice.invoiceShowCurrent = selectedInvoiceArrayByBonus[indexPath.row]
        self.navigationController?.pushViewController(InvoiceInfoViewController(), animated: true)
        /*
        // Set the selected invoice index so invoiceInfoView can display it
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

        let curSelectedMonth = bonusMonthLabel.text?.suffix(5)
        let curSelectedYear = bonusMonthLabel.text?.prefix(4)
        if let title = sender.currentTitle {
            switch title {
            // Left button: move to the previous period
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

            // Right button: move to the next period
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
    
    
    // Winning numbers now come from the Ministry of Finance open data, so the user no longer adds them manually.
    // Reuse the storyboard's existing addBonusNumber: connection, repurposed as an "update winning numbers" action.
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

