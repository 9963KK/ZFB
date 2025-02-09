import Foundation

class IngredientCategoryManager {
    static let shared = IngredientCategoryManager()
    
    private init() {}
    
    // 食材分类映射
    private let categoryMap: [String: String] = [
        // 蔬菜类
        "白菜": "蔬菜", "萝卜": "蔬菜", "青菜": "蔬菜", "韭菜": "蔬菜",
        "茄子": "蔬菜", "黄瓜": "蔬菜", "西红柿": "蔬菜", "土豆": "蔬菜",
        "胡萝卜": "蔬菜", "芹菜": "蔬菜", "生菜": "蔬菜", "菠菜": "蔬菜",
        
        // 水果类
        "苹果": "水果", "香蕉": "水果", "橙子": "水果", "梨": "水果",
        "葡萄": "水果", "西瓜": "水果", "草莓": "水果", "桃子": "水果",
        
        // 肉类
        "猪肉": "肉类", "牛肉": "肉类", "羊肉": "肉类", "鸡肉": "肉类",
        "鸭肉": "肉类", "五花肉": "肉类", "里脊": "肉类",
        
        // 海鲜类
        "鱼": "海鲜", "虾": "海鲜", "蟹": "海鲜", "贝类": "海鲜",
        "海带": "海鲜", "鱿鱼": "海鲜",
        
        // 调味料
        "盐": "调味料", "糖": "调味料", "酱油": "调味料", "醋": "调味料",
        "料酒": "调味料", "蒜": "调味料", "姜": "调味料", "辣椒": "调味料"
    ]
    
    // 获取食材的分类
    func getCategory(for ingredient: String) -> String? {
        return categoryMap[ingredient]
    }
    
    // 获取主要类别
    func getMainCategory(for category: String) -> String {
        // 如果本身就是主类别，直接返回
        let mainCategories = ["蔬菜", "水果", "肉类", "海鲜", "调味料", "其他"]
        if mainCategories.contains(category) {
            return category
        }
        
        // 否则尝试从映射中获取
        return categoryMap[category] ?? "其他"
    }
}