//
//  ConsumptionAnalysisViewController.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/25.
//  Reimplemented with native Swift Charts (no third-party dependency).
//

import UIKit
import SwiftUI
import Charts
import UserNotifications

// MARK: - Data model

/// 單一月份的消費資料，供 Swift Charts 繪圖使用。
struct MonthlyConsumption: Identifiable {
    let id = UUID()
    let monthIndex: Int      // 0 = Jan ... 11 = Dec
    let monthLabel: String   // "Jan" ... "Dec"
    let amount: Int
}

/// 單一分類的消費資料。
struct CategoryConsumption: Identifiable {
    let id = UUID()
    let category: String
    let amount: Int
}

/// 把 `Invoice.globalInvoiceArray` 依年份彙總成每月消費金額。
enum ConsumptionStats {
    static let monthCodes = ["01", "02", "03", "04", "05", "06",
                             "07", "08", "09", "10", "11", "12"]
    static let monthLabels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                              "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    /// 計算指定年份每個月的消費總額。
    static func monthlyConsumption(for year: String) -> [MonthlyConsumption] {
        var sums = Array(repeating: 0, count: 12)
        for invoice in Invoice.globalInvoiceArray where invoice.date.prefix(4) == year {
            let monthCode = String(invoice.date.prefix(7).suffix(2))
            if let index = monthCodes.firstIndex(of: monthCode) {
                sums[index] += Int(invoice.totalPrice) ?? 0
            }
        }
        return (0..<12).map { MonthlyConsumption(monthIndex: $0, monthLabel: monthLabels[$0], amount: sums[$0]) }
    }

    /// 計算指定年份各分類的消費總額（僅回傳有消費的分類，由高到低）。
    static func categoryConsumption(for year: String) -> [CategoryConsumption] {
        var sums: [String: Int] = [:]
        for invoice in Invoice.globalInvoiceArray where invoice.date.prefix(4) == year {
            let category = invoice.category.isEmpty ? "其他" : invoice.category
            sums[category, default: 0] += Int(invoice.totalPrice) ?? 0
        }
        return sums.filter { $0.value > 0 }
            .map { CategoryConsumption(category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    /// 從現有發票資料推導出可選的年份清單（永遠包含當年）。
    static func availableYears() -> [String] {
        var years = Set(Invoice.globalInvoiceArray.map { String($0.date.prefix(4)) })
        years = years.filter { $0.count == 4 && Int($0) != nil }
        let currentYear = Calendar.current.component(.year, from: Date())
        years.insert(String(currentYear))
        return years.sorted(by: >)
    }
}

// MARK: - View model

@available(iOS 16.0, *)
final class ConsumptionViewModel: ObservableObject {
    @Published var year: String
    @Published var data: [MonthlyConsumption] = []
    @Published var categoryData: [CategoryConsumption] = []
    @Published var years: [String] = []

    var total: Int { data.reduce(0) { $0 + $1.amount } }

    init() {
        let current = String(Calendar.current.component(.year, from: Date()))
        self.year = current
        reload()
    }

    func reload() {
        years = ConsumptionStats.availableYears()
        if !years.contains(year) { year = years.first ?? year }
        data = ConsumptionStats.monthlyConsumption(for: year)
        categoryData = ConsumptionStats.categoryConsumption(for: year)
    }
}

// MARK: - SwiftUI chart

@available(iOS 16.0, *)
struct ConsumptionAnalysisView: View {
    @ObservedObject var model: ConsumptionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("年份")
                    .font(.headline)
                Picker("年份", selection: $model.year) {
                    ForEach(model.years, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                Spacer()
                VStack(alignment: .trailing) {
                    Text("支出總和")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(model.total)")
                        .font(.title2.bold())
                }
            }
            .padding(.horizontal)

            if model.total == 0 {
                Spacer()
                Text("這一年沒有發票資料")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("每月支出")
                            .font(.headline)
                        Chart(model.data) { item in
                            BarMark(
                                x: .value("月份", item.monthLabel),
                                y: .value("金額", item.amount)
                            )
                            .foregroundStyle(by: .value("月份", item.monthLabel))
                            .cornerRadius(4)
                        }
                        .chartLegend(.hidden)
                        .frame(height: 260)

                        Text("分類占比")
                            .font(.headline)
                        Chart(model.categoryData) { item in
                            BarMark(
                                x: .value("金額", item.amount),
                                y: .value("分類", item.category)
                            )
                            .foregroundStyle(by: .value("分類", item.category))
                            .annotation(position: .trailing) {
                                Text("$\(item.amount)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .chartLegend(.hidden)
                        .frame(height: CGFloat(max(1, model.categoryData.count)) * 44 + 20)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.top)
        .onChange(of: model.year) { _ in model.reload() }
        .onAppear { model.reload() }
    }
}

// MARK: - Hosting view controller

class ConsumptionAnalysisViewController: UIViewController {

    private var viewModel: AnyObject?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "消費分析"
        view.backgroundColor = .systemBackground

        // 開獎提醒設定入口
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "bell"),
            style: .plain,
            target: self,
            action: #selector(toggleDrawReminder)
        )

        if #available(iOS 16.0, *) {
            let model = ConsumptionViewModel()
            viewModel = model
            let host = UIHostingController(rootView: ConsumptionAnalysisView(model: model))
            addChild(host)
            host.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(host.view)
            NSLayoutConstraint.activate([
                host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            host.didMove(toParent: self)

            // 資料庫非同步載入完成後，重新整理圖表。
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("DatabaseReady"),
                object: nil,
                queue: .main
            ) { [weak model] _ in
                model?.reload()
            }
        } else {
            let label = UILabel()
            label.text = "消費分析需要 iOS 16 以上版本"
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 16.0, *), let model = viewModel as? ConsumptionViewModel {
            model.reload()
        }
    }

    @objc private func toggleDrawReminder() {
        DrawReminder.requestAndSchedule { [weak self] granted in
            let title = granted ? "已開啟開獎提醒" : "無法開啟通知"
            let message = granted
                ? "將於每期開獎日（每單月 25 日）上午提醒你對獎。"
                : "請至「設定」開啟本 App 的通知權限。"
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "確定", style: .default))
            self?.present(alert, animated: true)
        }
    }
}

// MARK: - 開獎提醒

// 統一發票每期於次月 25 日開獎（即每單月 25 日）。以本機通知於開獎日提醒對獎。
enum DrawReminder {
    static let drawMonths = [1, 3, 5, 7, 9, 11]
    static let identifierPrefix = "invoiceDrawReminder-"

    static func requestAndSchedule(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted { schedule() }
            DispatchQueue.main.async { completion(granted) }
        }
    }

    static func schedule() {
        let center = UNUserNotificationCenter.current()
        let identifiers = drawMonths.map { identifierPrefix + String($0) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        for month in drawMonths {
            var dateComponents = DateComponents()
            dateComponents.month = month
            dateComponents.day = 25
            dateComponents.hour = 10
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let content = UNMutableNotificationContent()
            content.title = "統一發票開獎日"
            content.body = "今天是開獎日，記得打開 App 對獎！"
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: identifierPrefix + String(month),
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }
}
