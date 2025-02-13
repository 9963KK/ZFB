import Foundation

struct IngredientFilter {
    // 食材分类筛选
    var selectedCategory: String?
    
    // 时间范围筛选
    enum TimeRange: String, CaseIterable {
        case all = "全部"
        case recentlyBought = "最近购买"
        case nearExpiry = "临近过期"
        
        var days: Int? {
            switch self {
            case .recentlyBought: return 7  // 一周内购买
            case .nearExpiry: return 3      // 3天内过期
            case .all: return nil
            }
        }
    }
    var selectedTimeRange: TimeRange = .all
    
    // 过滤食材
    func filter(_ ingredients: [Ingredient]) -> [Ingredient] {
        var filtered = ingredients
        
        // 按分类筛选
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // 按时间范围筛选
        if let days = selectedTimeRange.days {
            let calendar = Calendar.current
            let now = Date()
            
            switch selectedTimeRange {
            case .recentlyBought:
                // 筛选最近7天购买的食材
                filtered = filtered.filter {
                    guard let purchaseDate = $0.purchaseDate else { return false }
                    let daysSincePurchase = calendar.dateComponents([.day], from: purchaseDate, to: now).day ?? 0
                    return daysSincePurchase <= days
                }
                
            case .nearExpiry:
                // 筛选3天内过期的食材
                filtered = filtered.filter {
                    guard let expiryDate = $0.expiryDate else { return false }
                    let daysUntilExpiry = calendar.dateComponents([.day], from: now, to: expiryDate).day ?? 0
                    return daysUntilExpiry <= days && daysUntilExpiry >= 0
                }
                
            case .all:
                break
            }
        }
        
        return filtered
    }
}
