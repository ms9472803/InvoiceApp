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

    /// Whether data has finished loading from local storage. Used by the UI to decide whether to keep showing the loading screen.
    static private(set) var isReady = false

    // MARK: - Core Data stack

    // Build the data model in code, avoiding the hassle of adding a separate .xcdatamodeld file to the project.
    // Two entities: InvoiceEntity (invoice) and ItemEntity (line item), linked by a one-to-many relationship.
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

        // One-to-many: an invoice has multiple line items
        let itemsRelationship = NSRelationshipDescription()
        itemsRelationship.name = "items"
        itemsRelationship.destinationEntity = itemEntity
        itemsRelationship.minCount = 0
        itemsRelationship.maxCount = 0 // 0 means to-many
        itemsRelationship.deleteRule = .cascadeDeleteRule
        itemsRelationship.isOptional = true

        // Inverse relationship: a line item belongs to one invoice
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

    // The whole app shares a single persistent container (SQLite file).
    private static let container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "InvoiceModel", managedObjectModel: MyDatabase.managedObjectModel)
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data 載入失敗: \(error.localizedDescription)")
            }
        }
        // When merging background writes with main-thread reads, the newer data wins
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return container
    }()

    private var context: NSManagedObjectContext { MyDatabase.container.viewContext }

    // MARK: - Public API (keeps the same interface as the original Firebase version)

    /// Writes all invoices currently in globalInvoiceArray to the local database.
    func upLoadToDB() {
        for invoice in Invoice.globalInvoiceArray {
            addInvoiceToDB(invoice)
        }
    }

    /// Adds (or updates) an invoice. Uses the invoice number as the unique key, overwriting if it already exists.
    func addInvoiceToDB(_ invoice: Invoice) {
        // upsert: delete any existing record with the same number first, then write the new one
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

    /// Deletes the invoice with the given invoice number.
    func removeInvoiceFromDB(_ invoiceNumber: String) {
        deleteInvoiceObjects(numbered: invoiceNumber)
        saveContext()
    }

    /// Reads all invoices from the local database into globalInvoiceArray and notifies the UI to update.
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

        // Sort by date (consistent with the original oldest-to-newest presentation)
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
