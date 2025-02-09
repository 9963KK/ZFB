//
//  Persistence.swift
//  ZFB
//
//  Created by 陈杰豪 on 9/2/2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // 创建示例数据
        let sampleIngredient = Ingredient(context: viewContext)
        sampleIngredient.name = "胡萝卜"
        sampleIngredient.category = "蔬菜"
        sampleIngredient.quantity = 500
        sampleIngredient.unit = "克"
        sampleIngredient.purchaseDate = Date()
        sampleIngredient.expiryDate = Date().addingTimeInterval(7*24*60*60) // 7天后过期
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "ZFB")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
