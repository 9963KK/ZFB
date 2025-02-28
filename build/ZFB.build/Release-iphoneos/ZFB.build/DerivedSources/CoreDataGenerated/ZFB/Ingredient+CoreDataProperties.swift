//
//  Ingredient+CoreDataProperties.swift
//  
//
//  Created by 陈杰豪 on 25/2/2025.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Ingredient {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Ingredient> {
        return NSFetchRequest<Ingredient>(entityName: "Ingredient")
    }

    @NSManaged public var category: String?
    @NSManaged public var expiryDate: Date?
    @NSManaged public var imageData: Data?
    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var purchaseDate: Date?
    @NSManaged public var quantity: Double
    @NSManaged public var sortOrder: Int16
    @NSManaged public var unit: String?

}

extension Ingredient : Identifiable {

}
