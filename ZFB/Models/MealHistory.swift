import Foundation
import CoreData

@objc(MealHistory)
public class MealHistory: NSManagedObject {
    @NSManaged public var datetime: Date?
    @NSManaged public var meal: String?
    @NSManaged public var recipeName: String?
} 