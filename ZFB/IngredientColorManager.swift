import SwiftUI

struct IngredientColorManager {
    static func getColor(for category: String?) -> Color {
        guard let category = category else { return .gray }
        
        // 提取主要类别（例如从"猪肉"中提取"肉类"）
        let mainCategory = IngredientCategoryManager.shared.getMainCategory(for: category)
        
        switch mainCategory {
        case "肉类":
            return .pink
        case "蛋类":
            return .yellow
        case "水果":
            return .orange
        case "蔬菜":
            return .green
        case "海鲜":
            return .blue
        case "主食":
            return .brown
        case "乳制品":
            return .cyan
        case "调味料":
            return .purple
        case "坚果":
            return .orange
        case "零食":
            return .red
        case "饮料":
            return .blue
        default:
            return .gray
        }
    }
}
