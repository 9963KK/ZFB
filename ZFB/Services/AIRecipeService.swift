import Foundation
import CoreData
import SwiftUI
import Security

// 错误类型定义
enum AIServiceError: LocalizedError {
    case noIngredients
    case apiKeyMissing
    case networkError(Error)
    case invalidResponse
}

// AI 食谱推荐服务
class AIRecipeService {
    static let shared = AIRecipeService()
    
    // MARK: - 配置
    private struct Config {
        static let baseURL = "https://api.siliconflow.cn/v1"
        static let timeout: TimeInterval = 30
        static let maxRetries = 3
        static let cacheTimeout: TimeInterval = 3600 // 1小时
        static let apiKey = "sk-ortmefpwfkwrjcxelwirsqbzgplxsjgmaekqzcpcwjnomybu"
        static let model = "deepseek-ai/DeepSeek-R1-Distill-Llama-70B"
        static let temperature: Double = 0.6
    }
    
    private var apiKey: String {
        // 优先从钥匙串获取
        if let keyFromKeychain = KeychainManager.shared.getAPIKey() {
            return keyFromKeychain
        }
        // 如果钥匙串中没有，则使用配置中的密钥并保存到钥匙串
        KeychainManager.shared.saveAPIKey(Config.apiKey)
        return Config.apiKey
    }
    
    private let cache = NSCache<NSString, NSString>()
    private init() {
        cache.countLimit = 100
    }
    
    // MARK: - 数据结构
    struct IngredientData: Codable, Identifiable {
        let id: UUID
        let name: String
        let category: String
        let quantity: Double
        let unit: String
        let expiryDate: Date?
        
        init(from ingredient: NSManagedObject) {
            self.id = UUID()
            self.name = ingredient.value(forKey: "name") as? String ?? ""
            self.category = ingredient.value(forKey: "category") as? String ?? ""
            self.quantity = ingredient.value(forKey: "quantity") as? Double ?? 0
            self.unit = ingredient.value(forKey: "unit") as? String ?? ""
            self.expiryDate = ingredient.value(forKey: "expiryDate") as? Date
        }
    }
    
    struct RecipeRecommendation: Codable, Identifiable {
        let id: UUID
        var name: String
        var calories: Int
        var nutrition: Nutrition
        var ingredients: [IngredientAmount]
        var steps: [String]
        var expirationPriority: Bool
        
        struct Nutrition: Codable {
            var protein: Int
            var carb: Int
            var fat: Int
        }
        
        struct IngredientAmount: Codable {
            var name: String
            var amount: Double
            var unit: String
        }
    }
    
    // MARK: - AI 通信结构
    private struct AIRequestData: Codable {
        let model: String = Config.model
        let messages: [Message]
        let temperature: Double = Config.temperature
        
        struct Message: Codable {
            let role: String
            let content: String
        }
    }
    
    private struct AIResponseData: Codable {
        let choices: [Choice]
        
        struct Choice: Codable {
            let message: Message
            
            struct Message: Codable {
                let content: String
            }
        }
    }
    
    // MARK: - 钥匙串管理
    class KeychainManager {
        static let shared = KeychainManager()
        private let apiKeyIdentifier = "com.zfb.apikey.stepfun"
        
        private init() {}
        
        func saveAPIKey(_ key: String) {
            guard let data = key.data(using: .utf8) else { return }
            var query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: apiKeyIdentifier,
                kSecValueData: data
            ]
            
            // 先删除已存在的密钥
            SecItemDelete(query as CFDictionary)
            
            // 保存新密钥
            let status = SecItemAdd(query as CFDictionary, nil)
            guard status == errSecSuccess else {
                print("保存API密钥到钥匙串失败: \(status)")
                return
            }
        }
        
        func getAPIKey() -> String? {
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: apiKeyIdentifier,
                kSecReturnData: kCFBooleanTrue!,
                kSecMatchLimit: kSecMatchLimitOne
            ]
            
            var dataTypeRef: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
            
            guard status == errSecSuccess,
                  let data = dataTypeRef as? Data,
                  let key = String(data: data, encoding: .utf8) else {
                return nil
            }
            
            return key
        }
        
        func deleteAPIKey() {
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: apiKeyIdentifier
            ]
            
            SecItemDelete(query as CFDictionary)
        }
    }
    
    // MARK: - 核心方法
    func prepareIngredientData(from context: NSManagedObjectContext) async -> [IngredientData] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Ingredient")
        // 添加排序
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "expiryDate", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ]
        
        do {
            let ingredients = try context.fetch(fetchRequest)
            return ingredients.map { IngredientData(from: $0) }
        } catch {
            print("获取食材数据失败: \(error)")
            return []
        }
    }
    
    private func generatePrompt(ingredients: [IngredientData], mealHistory: [String]) -> String {
        var prompt = """
        # 中英双语指令模板
        [ZH] 你是一个专业营养师，请根据以下信息生成定制化食谱：

        1. 当前库存食材：
        """
        
        // 按类别分组食材
        let groupedIngredients = Dictionary(grouping: ingredients) { $0.category }
        for (category, items) in groupedIngredients {
            prompt += "\n\(category)："
            prompt += items.map { ingredient in
                let expiryMark = isNearExpiry(date: ingredient.expiryDate) ? "❗️" : ""
                let expiryInfo = ingredient.expiryDate.map { formatExpiryDate($0) } ?? "无保质期"
                return "\(ingredient.name)\(expiryMark)(\(expiryInfo))-\(ingredient.quantity)\(ingredient.unit)"
            }.joined(separator: ", ")
        }
        
        // 添加用户近期饮食记录
        prompt += "\n\n2. 用户近期饮食：\n"
        for (index, meal) in mealHistory.enumerated() {
            let date = Calendar.current.date(byAdding: .day, value: -index, to: Date()) ?? Date()
            let dateString = formatDate(date)
            prompt += "  • \(dateString): \(meal)\n"
        }
        
        // 添加特殊要求
        prompt += """
        
        3. 特殊要求：
           - 优先消耗临近过期食材（剩余保质期<3天的标记为❗️）
           - 营养均衡（蛋白质占比20-35%）
           - 避免重复最近6天的食谱
           - 每种类型提供2道食谱选择
           - 需要包含以下三种类型：
             a. 快手菜（烹饪时间≤20分钟）
             b. 营养大餐（营养均衡，适合2-4人）
             c. 省时锅（一锅出，适合3-6人）

        [EN] As a professional nutritionist, generate recipes with:
        1. Current ingredients: \(ingredients.map { "\($0.name)" }.joined(separator: ", "))
        2. Last meals: \(mealHistory.joined(separator: ", "))
        3. Requirements:
           - Prioritize ingredients expiring in <3 days (marked with ❗️)
           - Balanced nutrition (protein 20-35%)
           - No repetition in last meals
           - Provide 2 recipes for each type
           - Include three types:
             a. Quick meals (cooking time ≤20 mins)
             b. Nutritious meals (balanced, serves 2-4)
             c. One-pot meals (serves 3-6)

        # 输出格式要求
        请严格按照以下 JSON 格式输出：
        {
          "recipes": [
            {
              "name": "食谱名称",
              "type": "快手菜/营养大餐/省时锅",
              "cooking_time": "20分钟",
              "servings": "4人份",
              "calories": 500,
              "nutrition": {
                "protein": 30,
                "carb": 45,
                "fat": 20
              },
              "ingredients": [
                {
                  "name": "食材名称",
                  "amount": 2,
                  "unit": "单位"
                }
              ],
              "steps": ["步骤1", "步骤2"],
              "expiration_priority": true,
              "tips": "可选的烹饪建议和技巧"
            }
          ]
        }
        """
        
        return prompt
    }
    
    // MARK: - 网络请求
    func requestRecipeRecommendation(with ingredients: [IngredientData], mealHistory: [String] = []) async throws -> [RecipeRecommendation] {
        // 检查缓存
        let cacheKey = (ingredients.map { $0.id.uuidString } + mealHistory).joined(separator: "_") as NSString
        if let cachedResult = cache.object(forKey: cacheKey) {
            if let stringData = (cachedResult as String).data(using: .utf8) {
                return try JSONDecoder().decode([RecipeRecommendation].self, from: stringData)
            }
        }
        
        guard !apiKey.isEmpty else {
            throw AIServiceError.apiKeyMissing
        }
        
        guard let url = URL(string: Config.baseURL) else {
            throw URLError(.badURL)
        }
        
        let prompt = generatePrompt(ingredients: ingredients, mealHistory: mealHistory)
        let messages = [AIRequestData.Message(role: "user", content: prompt)]
        let requestData = AIRequestData(messages: messages)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = Config.timeout
        request.httpBody = try JSONEncoder().encode(requestData)
        
        // 重试逻辑
        var lastError: Error?
        for attempt in 1...Config.maxRetries {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw AIServiceError.invalidResponse
                }
                
                let aiResponse = try JSONDecoder().decode(AIResponseData.self, from: data)
                if let content = aiResponse.choices.first?.message.content {
                    // 缓存结果
                    cache.setObject(content as NSString, forKey: cacheKey)
                    return try parseRecipeRecommendations(from: content)
                }
                throw AIServiceError.invalidResponse
            } catch {
                lastError = error
                if attempt < Config.maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 1_000_000_000))
                    continue
                }
            }
        }
        
        throw lastError ?? AIServiceError.networkError(URLError(.unknown))
    }
    
    // MARK: - 辅助方法
    private func parseRecipeRecommendations(from jsonString: String) throws -> [RecipeRecommendation] {
        struct Response: Codable {
            let recipes: [RecipeRecommendation]
        }
        
        let jsonData = Data(jsonString.utf8)
        let response = try JSONDecoder().decode(Response.self, from: jsonData)
        return response.recipes
    }
    
    private func isNearExpiry(date: Date?) -> Bool {
        guard let date = date else { return false }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return days <= 3 && days >= 0
    }
    
    private func formatExpiryDate(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return "\(days)天"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

// MARK: - 错误处理
extension AIServiceError {
    var recoverySuggestion: String {
        switch self {
        case .noIngredients:
            return "请先添加一些食材"
        case .apiKeyMissing:
            return "请在设置中配置 API 密钥"
        case .networkError(let error):
            return "请检查网络连接并重试：\(error.localizedDescription)"
        case .invalidResponse:
            return "服务器返回的数据格式不正确，请稍后重试"
        }
    }
}

// MARK: - 预览支持
#if DEBUG
extension RecipeRecommendation {
    static var preview: RecipeRecommendation {
        RecipeRecommendation(
            id: UUID(),
            name: "番茄炒蛋",
            calories: 300,
            nutrition: Nutrition(protein: 25, carb: 45, fat: 30),
            ingredients: [
                IngredientAmount(name: "鸡蛋", amount: 2, unit: "个"),
                IngredientAmount(name: "番茄", amount: 1, unit: "个")
            ],
            steps: [
                "打散鸡蛋",
                "切番茄",
                "热油炒蛋",
                "加入番茄翻炒",
                "加盐调味即可"
            ],
            expirationPriority: true
        )
    }
}
#endif