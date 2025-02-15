import Foundation

struct IngredientIcon {
    static let categoryIcons: [String: String] = [
        // 主要类别
        "主食": "🍚",
        "面食": "🍜",
        "米饭": "🍚",
        "面包": "🍞",
        
        // 蔬菜类
        "蔬菜": "🥬",
        "叶菜类": "🥬",
        "根茎类": "🥕",
        "菌菇类": "🍄",
        "豆类": "🫘",
        "瓜果类": "🥒",
        
        // 水果类
        "水果": "🍎",
        "浆果类": "🫐",
        "柑橘类": "🍊",
        "瓜类": "🍈",
        "热带水果": "🥭",
        
        // 肉类
        "肉类": "🥩",
        "猪肉": "🥓",
        "牛肉": "🥩",
        "羊肉": "🍖",
        "禽肉": "🍗",
        
        // 海鲜类
        "海鲜": "🦐",
        "鱼类": "🐟",
        "贝类": "🦪",
        "虾蟹": "🦀",
        
        // 调味料
        "调味料": "🧂",
        "香辛料": "🌶️",
        "酱料": "🫙",
        "油类": "🫗",
        
        // 蛋类
        "蛋类": "🥚",
        "鸡蛋": "🥚",
        "鸭蛋": "🥚",
        "咸蛋": "🥚",
        
        // 乳制品
        "乳制品": "🥛",
        "奶酪": "🧀",
        "黄油": "🧈",
        
        // 豆制品
        "豆制品": "🧊",
        
        // 干货
        "干货": "🥜",
        "坚果": "🥜",
        "干菜": "🥬",
        "菌菇干货": "🍄",
        
        // 零食
        "零食": "🍪",
        "饼干": "🍪",
        "糖果": "🍬",
        "巧克力": "🍫",
        
        // 饮品
        "饮品": "🥤",
        "茶": "🫖",
        "咖啡": "☕️",
        "果汁": "🧃",
        "酒类": "🍶",
        
        // 其他
        "其他": "🥘"
    ]
    
    static func getIcon(for category: String?) -> String {
        guard let category = category else { return "🥘" }
        // 先尝试精确匹配
        if let icon = categoryIcons[category] {
            return icon
        }
        // 如果没有精确匹配，尝试查找包含关系
        for (key, icon) in categoryIcons {
            if category.contains(key) || key.contains(category) {
                return icon
            }
        }
        return "🥘"
    }
    
    // 获取所有支持的分类
    static var categories: [String] {
        return Array(categoryIcons.keys).sorted()
    }
    
    // 获取分类和图标的组合显示文本
    static func getCategoryWithIcon(for category: String) -> String {
        return "\(getIcon(for: category)) \(category)"
    }
    
    // 获取主要分类（用于分组显示）
    static var mainCategories: [String] {
        return [
            "主食", "蔬菜", "水果", "肉类", "海鲜",
            "调味料", "蛋类", "乳制品", "豆制品",
            "干货", "零食", "饮品", "其他"
        ]
    }
    
    // 获取子分类
    static func getSubcategories(for mainCategory: String) -> [String] {
        return categoryIcons.keys.filter { $0 != mainCategory && ($0.contains(mainCategory) || mainCategory.contains($0)) }
    }
}
