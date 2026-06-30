//
//  MyDatabase.swift
//  myProject
//
//  Created by Ryan Chen on 2022/5/26.
//  Reworked to use Apple's built-in Core Data instead of Firebase.
//

import Foundation
import CoreData

@objcMembers class MyDatabase: NSObject {

    static let databaseReadyNotification = NSNotification.Name("DatabaseReady")

    /// 資料是否已經從本機讀取完成。供 UI 判斷是否仍需顯示 loading 畫面。
    static private(set) var isReady = false

    // MARK: - Core Data stack

    // 以程式碼建立資料模型，免去額外加入 .xcdatamodeld 檔到專案的麻煩。
    // 兩個 entity：InvoiceEntity（發票）與 ItemEntity（品項），以一對多關聯連結。
    private static let managedObjectModel: NSManagedObjectModel = {
        let model = NSManagedObjectModel()

        let invoiceEntity = NSEntityDescription()
        invoiceEntity.name = "InvoiceEntity"
        invoiceEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let itemEntity = NSEntityDescription()
        itemEntity.name = "ItemEntity"
        itemEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        func stringAttribute(_ name: String) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = .stringAttributeType
            attribute.isOptional = true
            return attribute
        }

        // 一對多：一張發票有多個品項
        let itemsRelationship = NSRelationshipDescription()
        itemsRelationship.name = "items"
        itemsRelationship.destinationEntity = itemEntity
        itemsRelationship.minCount = 0
        itemsRelationship.maxCount = 0 // 0 代表 to-many
        itemsRelationship.deleteRule = .cascadeDeleteRule
        itemsRelationship.isOptional = true

        // 反向關聯：一個品項屬於一張發票
        let invoiceRelationship = NSRelationshipDescription()
        invoiceRelationship.name = "invoice"
        invoiceRelationship.destinationEntity = invoiceEntity
        invoiceRelationship.minCount = 0
        invoiceRelationship.maxCount = 1
        invoiceRelationship.deleteRule = .nullifyDeleteRule
        invoiceRelationship.isOptional = true

        itemsRelationship.inverseRelationship = invoiceRelationship
        invoiceRelationship.inverseRelationship = itemsRelationship

        invoiceEntity.properties = [
            stringAttribute("number"),
            stringAttribute("date"),
            stringAttribute("storeName"),
            stringAttribute("category"),
            itemsRelationship
        ]
        itemEntity.properties = [
            stringAttribute("itemName"),
            stringAttribute("amount"),
            stringAttribute("price"),
            invoiceRelationship
        ]

        model.entities = [invoiceEntity, itemEntity]
        return model
    }()

    // 整個 App 共用同一個 persistent container（SQLite 檔案）。
    private static let container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "InvoiceModel", managedObjectModel: MyDatabase.managedObjectModel)
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data 載入失敗: \(error.localizedDescription)")
            }
        }
        // 後台寫入與主執行緒讀取合併時，以新資料為準
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return container
    }()

    private var context: NSManagedObjectContext { MyDatabase.container.viewContext }

    // MARK: - Public API（維持與原本 Firebase 版本相同的介面）

    /// 把目前 globalInvoiceArray 內的發票全部寫入本機資料庫。
    func upLoadToDB() {
        for invoice in Invoice.globalInvoiceArray {
            addInvoiceToDB(invoice)
        }
    }

    /// 新增（或更新）一張發票。以發票號碼做為唯一鍵，存在則覆蓋。
    func addInvoiceToDB(_ invoice: Invoice) {
        // upsert：先刪掉同號碼的舊資料，再寫入新的
        deleteInvoiceObjects(numbered: invoice.number)

        let invoiceObject = NSEntityDescription.insertNewObject(forEntityName: "InvoiceEntity", into: context)
        invoiceObject.setValue(invoice.number, forKey: "number")
        invoiceObject.setValue(invoice.date, forKey: "date")
        invoiceObject.setValue(invoice.storeName, forKey: "storeName")
        invoiceObject.setValue(invoice.category, forKey: "category")

        let itemsSet = invoiceObject.mutableSetValue(forKey: "items")
        for item in invoice.itemAndPrice {
            let itemObject = NSEntityDescription.insertNewObject(forEntityName: "ItemEntity", into: context)
            itemObject.setValue(item.itemName, forKey: "itemName")
            itemObject.setValue(item.amount, forKey: "amount")
            itemObject.setValue(item.price, forKey: "price")
            itemsSet.add(itemObject)
        }

        saveContext()
    }

    /// 刪除指定發票號碼的發票。
    func removeInvoiceFromDB(_ invoiceNumber: String) {
        deleteInvoiceObjects(numbered: invoiceNumber)
        saveContext()
    }

    /// 從本機資料庫讀出所有發票，放進 globalInvoiceArray，並通知 UI 更新。
    func readFromDB() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "InvoiceEntity")
        var invoices: [Invoice] = []

        do {
            let results = try context.fetch(request)
            for object in results {
                let number = object.value(forKey: "number") as? String ?? ""
                let date = object.value(forKey: "date") as? String ?? ""
                let storeName = object.value(forKey: "storeName") as? String ?? ""
                let category = object.value(forKey: "category") as? String ?? "其他"

                var items: [Item] = []
                if let itemObjects = object.value(forKey: "items") as? Set<NSManagedObject> {
                    for itemObject in itemObjects {
                        items.append(Item(
                            itemName: itemObject.value(forKey: "itemName") as? String ?? "",
                            amount: itemObject.value(forKey: "amount") as? String ?? "",
                            price: itemObject.value(forKey: "price") as? String ?? ""
                        ))
                    }
                }
                invoices.append(Invoice(number: number, date: date, storeName: storeName, itemAndPrice: items, category: category))
            }
        } catch {
            print("讀取發票失敗: \(error.localizedDescription)")
        }

        // 依日期排序（與原本由舊到新的呈現一致）
        Invoice.globalInvoiceArray = invoices.sorted { $0.date < $1.date }

        MyDatabase.isReady = true
        NotificationCenter.default.post(name: MyDatabase.databaseReadyNotification, object: nil)
    }

    // MARK: - Helpers

    private func deleteInvoiceObjects(numbered invoiceNumber: String) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "InvoiceEntity")
        request.predicate = NSPredicate(format: "number == %@", invoiceNumber)
        do {
            let results = try context.fetch(request)
            for object in results {
                context.delete(object)
            }
        } catch {
            print("刪除發票失敗: \(error.localizedDescription)")
        }
    }

    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("儲存失敗: \(error.localizedDescription)")
        }
    }
}
