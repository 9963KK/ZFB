import Foundation

enum UnitType: String {
    case count = "个" // 计数单位
    case piece = "颗" // 计数单位
    case bundle = "把" // 计数单位
    case package = "包" // 包装单位
    case weight = "克" // 重量单位
    case kilogram = "千克" // 千克
    case volume = "毫升" // 体积单位
    case liter = "升" // 升
    
    var needsDecimal: Bool {
        switch self {
        case .count, .piece, .bundle, .package:
            return false
        case .weight, .kilogram, .volume, .liter:
            return true
        }
    }
    
    var decimalPlaces: Int {
        switch self {
        case .count, .piece, .bundle, .package:
            return 0
        case .weight, .volume:
            return 0
        case .kilogram, .liter:
            return 2
        }
    }
}

struct UnitFormatter {
    static func format(quantity: Double, unit: String) -> String {
        let unitType = UnitType(rawValue: unit) ?? .count
        
        if unitType.needsDecimal {
            return String(format: "%.\(unitType.decimalPlaces)f", quantity)
        } else {
            return String(format: "%.0f", quantity)
        }
    }
}
