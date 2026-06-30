//
//  HomePageViewController.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/16.
//

import UIKit
import AVFoundation

class HomePageViewController: UIViewController {

    // UI built programmatically (no storyboard)
    private let invoiceNumberTextField = UITextField()
    private let invoiceDateTextField = UITextField()
    private let invoiceStoreTextField = UITextField()
    private let itemAndPriceTextView = UITextView()
    private let invoiceTotalPriceLabel = UILabel()

    private let datePicker = UIDatePicker()
    private var loadingDBView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "新增發票"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "camera"),
            style: .plain,
            target: self,
            action: #selector(openCamera)
        )

        setupForm()
        setupDatePicker()
        setupLoadingOverlay()

        // Core Data reads synchronously, so it is usually ready by app launch; if already ready, dismiss the loading screen right away
        if MyDatabase.isReady {
            dbReady()
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(dbReady), name: MyDatabase.databaseReadyNotification, object: nil)
            // Safety net: prevent the screen from getting stuck on loading due to any unexpected issue
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.dbReady()
            }
        }
    }

    // MARK: - UI setup

    private func setupForm() {
        invoiceNumberTextField.borderStyle = .roundedRect
        invoiceNumberTextField.placeholder = "AB12345678"
        invoiceNumberTextField.clearButtonMode = .always
        invoiceNumberTextField.autocapitalizationType = .allCharacters

        invoiceDateTextField.borderStyle = .roundedRect
        invoiceDateTextField.placeholder = "選擇日期"

        invoiceStoreTextField.borderStyle = .roundedRect
        invoiceStoreTextField.placeholder = "可留空"
        invoiceStoreTextField.clearButtonMode = .always

        invoiceTotalPriceLabel.text = "$0"
        invoiceTotalPriceLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        invoiceTotalPriceLabel.textAlignment = .right

        itemAndPriceTextView.isEditable = false
        itemAndPriceTextView.text = "(可留空)"
        itemAndPriceTextView.backgroundColor = .secondarySystemBackground
        itemAndPriceTextView.layer.cornerRadius = 10
        itemAndPriceTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        itemAndPriceTextView.font = .systemFont(ofSize: 15)

        let addItemButton = UIButton(type: .system)
        addItemButton.setTitle("＋ 新增品項", for: .normal)
        addItemButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        addItemButton.addTarget(self, action: #selector(addItemAndPrice), for: .touchUpInside)

        let formStack = UIStackView(arrangedSubviews: [
            labeledRow("發票號碼", invoiceNumberTextField),
            labeledRow("發票日期", invoiceDateTextField),
            labeledRow("店名", invoiceStoreTextField),
            labeledRow("總金額", invoiceTotalPriceLabel),
            addItemButton
        ])
        formStack.axis = .vertical
        formStack.spacing = 14
        formStack.translatesAutoresizingMaskIntoConstraints = false

        let saveButton = filledButton("儲存發票", action: #selector(storeInvoice))
        let resetButton = filledButton("Reset", action: #selector(touchResetButton))
        let buttonStack = UIStackView(arrangedSubviews: [saveButton, resetButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 16
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        itemAndPriceTextView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(formStack)
        view.addSubview(itemAndPriceTextView)
        view.addSubview(buttonStack)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            formStack.topAnchor.constraint(equalTo: guide.topAnchor, constant: 24),
            formStack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            formStack.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),

            itemAndPriceTextView.topAnchor.constraint(equalTo: formStack.bottomAnchor, constant: 16),
            itemAndPriceTextView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            itemAndPriceTextView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            itemAndPriceTextView.bottomAnchor.constraint(equalTo: buttonStack.topAnchor, constant: -24),

            buttonStack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 40),
            buttonStack.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -40),
            buttonStack.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -24),
            buttonStack.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func labeledRow(_ title: String, _ field: UIView) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 17)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.widthAnchor.constraint(equalToConstant: 90).isActive = true
        let row = UIStackView(arrangedSubviews: [label, field])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        return row
    }

    private func filledButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func setupDatePicker() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePresser))
        toolbar.setItems([doneBtn], animated: true)

        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        invoiceDateTextField.inputView = datePicker
        invoiceDateTextField.inputAccessoryView = toolbar
    }

    private func setupLoadingOverlay() {
        let loading = UIView()
        loading.backgroundColor = .systemBackground
        loading.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loading)
        NSLayoutConstraint.activate([
            loading.topAnchor.constraint(equalTo: view.topAnchor),
            loading.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loading.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loading.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        loadingDBView = loading

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        loading.addSubview(spinner)

        let loadingLabel = UILabel()
        loadingLabel.text = "載入中…"
        loadingLabel.font = .systemFont(ofSize: 16)
        loadingLabel.textColor = .secondaryLabel
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loading.addSubview(loadingLabel)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: loading.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: loading.centerYAnchor, constant: -20),
            loadingLabel.centerXAnchor.constraint(equalTo: loading.centerXAnchor),
            loadingLabel.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 16)
        ])
    }

    // MARK: - Actions

    @objc func donePresser() {
        invoiceDateTextField.text = transformDatePickerToString(datePicker)
        view.endEditing(true)
    }

    @objc func dbReady() {
        loadingDBView?.isHidden = true
        NotificationCenter.default.removeObserver(self, name: MyDatabase.databaseReadyNotification, object: nil)
    }

    @objc func touchResetButton() {
        // The reset button clears all fields in one tap
        invoiceNumberTextField.text = ""
        invoiceDateTextField.text = ""
        invoiceStoreTextField.text = ""
        itemAndPriceTextView.text = "(可留空)"
        invoiceTotalPriceLabel.text = "$0"
    }

    // Runs when the save-invoice button is tapped
    @objc func storeInvoice(_ sender: UIButton) {
        let invoiceNumber = invoiceNumberTextField.text ?? ""

        /* Check the invoice number format */
        guard invoiceNumberFormatCheck(invoiceNumber) else {
            showSimpleAlert(title: "儲存失敗", message: "發票號碼格式不符合")
            return
        }
        guard isUnique(invoiceNumber) else {
            showSimpleAlert(title: "儲存失敗", message: "發票號碼已存在")
            return
        }

        // Save only after a spending category has been chosen
        let sheet = UIAlertController(title: "選擇消費分類", message: nil, preferredStyle: .actionSheet)
        for category in invoiceCategories {
            sheet.addAction(UIAlertAction(title: category, style: .default) { _ in
                self.saveInvoice(category: category)
            })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        sheet.popoverPresentationController?.sourceView = sender
        sheet.popoverPresentationController?.sourceRect = sender.bounds
        present(sheet, animated: true)
    }

    private func saveInvoice(category: String) {
        let addInvoice = Invoice(number: invoiceNumberTextField.text ?? "",
                                 date: invoiceDateTextField.text ?? "",
                                 storeName: invoiceStoreTextField.text ?? "",
                                 itemAndPrice: temporaryItemAndPrice,
                                 category: category)
        Invoice.globalInvoiceArray.append(addInvoice)
        MyDatabase().addInvoiceToDB(addInvoice)

        // Clear all fields
        invoiceNumberTextField.text = ""
        invoiceDateTextField.text = ""
        invoiceStoreTextField.text = ""
        itemAndPriceTextView.text = "(可留空)"
        invoiceTotalPriceLabel.text = "$0"
        // temporaryItemAndPrice is temporary and must be cleared after saving
        temporaryItemAndPrice = []

        showSimpleAlert(title: "儲存成功", message: "分類：\(category)")
    }

    private func showSimpleAlert(title: String, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "確定", style: .default))
        present(alertController, animated: true)
    }

    // Runs when the add-item button is tapped
    @objc func addItemAndPrice(_ sender: UIButton) {
        let alertController = UIAlertController(title: "新增品項數量金額", message: "請輸入資訊", preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField { textField in textField.placeholder = "品項" }
        alertController.addTextField { textField in textField.placeholder = "數量" }
        alertController.addTextField { textField in textField.placeholder = "金額" }

        alertController.addAction(UIAlertAction(title: "取消", style: UIAlertAction.Style.cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "確定", style: UIAlertAction.Style.default) { action in
            // Actions to perform after Confirm is tapped
            let itemString = alertController.textFields?[0].text ?? ""
            let amountString = alertController.textFields?[1].text ?? ""
            let priceString = alertController.textFields?[2].text ?? ""

            // Validate that the price is legal (Int && >=0)
            if let priceInt = Int(priceString), let amountInt = Int(amountString), priceInt >= 0, amountInt > 0 {
                temporaryItemAndPrice.append(Item(itemName: itemString, amount: amountString, price: priceString))
                // "itemAndPriceTextView" in closure requires explicit use of "self"
                if self.itemAndPriceTextView.text == "(可留空)" {
                    self.itemAndPriceTextView.text = ""
                }
                self.itemAndPriceTextView.text += "品項: \(itemString) $\(priceString) x\(amountString)\n"

                var sum = 0
                for tempItem in temporaryItemAndPrice {
                    sum += Int(tempItem.price) ?? 0
                }
                self.invoiceTotalPriceLabel.text = "$" + String(sum)
            }
        })
        present(alertController, animated: true, completion: nil)
    }

    // The camera is only available when built and run on a device
    @objc func openCamera(_ sender: Any) {
        let vc = QRCodeScannerViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}
