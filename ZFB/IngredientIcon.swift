import Foundation

struct IngredientIcon {
    static let categoryIcons: [String: String] = [
        "蔬菜": "🥬",
        "水果": "🍎",
        "肉类": "🥩",
        "海鲜": "🦐",
        "调味料": "🧂",
        "其他": "🥘"
    ]
    
    static func getIcon(for category: String?) -> String {
        guard let category = category else { return "🥘" }
        return categoryIcons[category] ?? "🥘"
    }
    
    // 获取所有支持的分类
    static var categories: [String] {
        return Array(categoryIcons.keys).sorted()
    }
    
    // 获取分类和图标的组合显示文本
    static func getCategoryWithIcon(for category: String) -> String {
        return "\(categoryIcons[category] ?? "🥘") \(category)"
    }
}
