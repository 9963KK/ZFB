import Foundation

// MARK: - 参数传输数据结构
struct WorkflowParams: Codable {
    // 固定的需求说明
    let requirements: String = """
        基本要求：
        - 食材使用优先级：
            * 最高优先级：剩余保质期≤3天的食材（必须优先使用）
            * 次高优先级：剩余保质期4-7天的食材
            * 常规使用：保质期充足的食材
        
        - 营养均衡要求：
            * 蛋白质占比：20-35%（必须严格遵守）
            * 碳水化合物：40-60%（推荐范围）
            * 脂肪：15-30%（建议控制）
            * 确保每餐营养素搭配合理
        
        - 食谱多样性：
            * 严格避免重复最近6天的食谱
            * 同一食材避免连续使用超过2天
            * 确保主料、配料搭配合理
        
        - 烹饪要求：
            * 快手菜：烹饪时间≤20分钟，步骤简单
            * 营养大餐：注重营养搭配，适合2-4人食用
            * 省时锅：一锅完成，适合3-6人食用，减少清洗
        
        - 用料规范：
            * 主料用量符合份量要求
            * 调味料需精确计量
            * 注意食材间的比例平衡
        """
    
    // 食谱类型
    var recipeType: [RecipeType]
    var amount: Int   // 每种类型的食谱数量
    
    // 历史记录
    var history: [HistoryRecord]
    
    // 食材库存
    var store: [StoreItem]
    
    // JSON 格式要求
    let JSON_REQUIREMENTS: String = """
        1. 食材用量规则：
           - 所有食材必须标注具体数量，禁止使用"适量"、"少许"等模糊词
           - 主料用量需符合份量要求（如4人份）
           - 调味料需标注具体克数或毫升数
           - 遵循常见用量习惯（如：盐1-2克，酱油5-10毫升）
           - 特殊调味料也需标注具体用量（如：八角1个，花椒2克）
        """
    
    // JSON 示例
    let JSON_EXAMPLE: RecipeExample = RecipeExample()
}

// MARK: - 辅助数据结构
struct RecipeType: Codable {
    var name: String
    var info: String
}

struct HistoryRecord: Codable {
    var date: String
    var name: String
}

struct StoreItem: Codable {
    var category: String
    var food: String
    var amount: Amount
    var days_left: Int
}

struct Amount: Codable {
    var num: Double
    var unit: String
}

struct RecipeExample: Codable {
    var recipes: [RecipeData] = [
        RecipeData(
            name: "红烧排骨",
            type: "营养大餐",
            cooking_time: "45分钟",
            servings: "4人份",
            calories: 650,
            nutrition: Nutrition(protein: 35, carb: 40, fat: 25),
            ingredients: [
                RecipeIngredient(name: "排骨", amount: 500, unit: "克"),
                RecipeIngredient(name: "生抽", amount: 15, unit: "毫升"),
                RecipeIngredient(name: "老抽", amount: 5, unit: "毫升"),
                RecipeIngredient(name: "料酒", amount: 10, unit: "毫升"),
                RecipeIngredient(name: "盐", amount: 2, unit: "克")
            ],
            steps: [
                "排骨切段，冷水下锅焯烫去血水",
                "锅中放油，爆香姜片和葱段",
                "加入排骨翻炒上色",
                "加入生抽、老抽、料酒调味",
                "加入适量热水，大火烧开后转小火炖煮30分钟",
                "调入盐和糖，收汁即可"
            ],
            expiration_priority: true,
            tips: "1. 焯水时加入几片姜片去腥 2. 炖煮时间要足够长，确保排骨软烂"
        )
    ]
}

struct RecipeData: Codable {
    var name: String
    var type: String
    var cooking_time: String
    var servings: String
    var calories: Int
    var nutrition: Nutrition
    var ingredients: [RecipeIngredient]
    var steps: [String]
    var expiration_priority: Bool
    var tips: String
}

struct Nutrition: Codable {
    var protein: Int  // 蛋白质占比
    var carb: Int     // 碳水占比
    var fat: Int      // 脂肪占比
}

struct RecipeIngredient: Codable {
    var name: String
    var amount: Double
    var unit: String
}

// MARK: - 工作流请求数据结构
struct WorkflowRequestData: Codable {
    let parameters: WorkflowParams
    let workflow_id: String
    let is_async: Bool
    
    init(parameters: WorkflowParams, workflow_id: String, is_async: Bool = false) {
        self.parameters = parameters
        self.workflow_id = workflow_id
        self.is_async = is_async
    }
}

// MARK: - 工作流响应数据结构
struct WorkflowResponse: Codable {
    let workflow_id: String
    let result: String?
    let error: String?
}

// MARK: - 编码键
extension WorkflowParams {
    private enum CodingKeys: String, CodingKey {
        case requirements = "Requirements"
        case recipeType = "RecipeType"
        case amount = "Amount"
        case history = "History"
        case store = "Store"
    }
}

extension RecipeType {
    private enum CodingKeys: String, CodingKey {
        case name = "Name"
        case info = "Info"
    }
}

extension HistoryRecord {
    private enum CodingKeys: String, CodingKey {
        case date = "Date"
        case name = "Name"
    }
}

extension StoreItem {
    private enum CodingKeys: String, CodingKey {
        case category = "Category"
        case food = "Food"
        case amount = "amount"
        case days_left = "days_left"
    }
} 