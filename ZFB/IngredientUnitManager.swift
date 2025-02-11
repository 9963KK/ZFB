import Foundation

struct IngredientUnitManager {
    static let shared = IngredientUnitManager()
    
    // 定义各类食材可用的单位
    private let categoryUnits: [String: [String]] = [
        "蔬菜": ["个", "颗", "把", "克", "千克"],
        "水果": ["个", "颗", "克", "千克"],
        "肉类": ["克", "千克"],
        "海鲜": ["只", "条", "克", "千克"],
        "调味料": ["克", "千克", "毫升", "升"],
        "其他": ["个", "包", "克", "千克", "毫升", "升"]
    ]
    
    // 获取指定类别可用的单位
    func getUnitsForCategory(_ category: String) -> [String] {
        return categoryUnits[category] ?? ["个", "克", "千克"] // 默认单位
    }
    
    // 检查单位是否适用于指定类别
    func isUnitValidForCategory(_ unit: String, category: String) -> Bool {
        return getUnitsForCategory(category).contains(unit)
    }
    
    // 获取指定类别的默认单位
    func getDefaultUnitForCategory(_ category: String) -> String {
        switch category {
        case "蔬菜", "水果":
            return "个"
        case "肉类", "海鲜":
            return "克"
        case "调味料":
            return "克"
        default:
            return "个"
        }
    }
}
