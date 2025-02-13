import SwiftUI

struct RecipePlanningView: View {
    // MARK: - Properties
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @State private var showingAddRecipe = false
    @State private var selectedMealTime = 0
    @State private var showingFilters = false
    @State private var calendarHeight: CGFloat = 300
    @State private var scrollOffset: CGFloat = 0
    @State private var isCalendarVisible = true
    @State private var showingDetail = false
    @State private var selectedRecipe: (name: String, time: String, servings: String, difficulty: String, tags: [String])?
    
    private let mealTimes = ["早餐", "午餐", "晚餐"]
    private let calendar = Calendar.current
    
    // 模拟不同餐点的食谱数据
    private var recipesForSelectedMeal: [(name: String, time: String, servings: String, difficulty: String, tags: [String])] {
        switch selectedMealTime {
        case 0: // 早餐
            return [
                ("皮蛋瘦肉粥", "30分钟", "2人份", "简单", ["粥类", "热门"]),
                ("三明治", "15分钟", "2人份", "简单", ["面包", "快手"]),
                ("煎饺", "20分钟", "3人份", "简单", ["家常菜", "热门"])
            ]
        case 1: // 午餐
            return [
                ("红烧排骨", "45分钟", "4人份", "中等", ["家常菜", "热门", "肉类"]),
                ("清炒小白菜", "20分钟", "4人份", "简单", ["素菜", "快手"]),
                ("番茄炒蛋", "15分钟", "3人份", "简单", ["家常菜", "快手"])
            ]
        case 2: // 晚餐
            return [
                ("水煮鱼", "40分钟", "4人份", "困难", ["川菜", "热门", "海鲜"]),
                ("宫保鸡丁", "35分钟", "4人份", "中等", ["川菜", "热门", "肉类"]),
                ("蒜蓉炒菜心", "15分钟", "4人份", "简单", ["素菜", "快手"])
            ]
        default:
            return []
        }
    }
    
    // MARK: - Helper Methods
    private func getIngredientsForRecipe(_ name: String) -> [String] {
        switch name {
        case "红烧排骨":
            return [
                "排骨 500g",
                "生抽 2勺",
                "老抽 1勺",
                "料酒 2勺",
                "姜片 3片",
                "葱段 2根",
                "八角 1个",
                "盐 适量",
                "糖 1勺"
            ]
        case "清炒小白菜":
            return [
                "小白菜 300g",
                "蒜末 2勺",
                "盐 适量",
                "油 适量"
            ]
        case "番茄炒蛋":
            return [
                "番茄 2个",
                "鸡蛋 3个",
                "葱花 适量",
                "盐 适量",
                "油 适量"
            ]
        default:
            return ["食材准备中..."]
        }
    }
    
    private func getStepsForRecipe(_ name: String) -> [String] {
        switch name {
        case "红烧排骨":
            return [
                "排骨切段，冷水下锅焯烫，去除血水",
                "锅中放油，爆香姜片和葱段",
                "加入排骨翻炒上色",
                "加入生抽、老抽、料酒、八角",
                "加入适量热水，大火烧开后转小火炖煮30分钟",
                "调入盐和糖，收汁即可"
            ]
        case "清炒小白菜":
            return [
                "小白菜洗净切段",
                "锅中放油，爆香蒜末",
                "加入小白菜快速翻炒",
                "加盐调味即可"
            ]
        case "番茄炒蛋":
            return [
                "番茄切块，鸡蛋打散",
                "锅中放油，倒入蛋液炒散",
                "加入番茄翻炒",
                "加盐调味，撒上葱花即可"
            ]
        default:
            return ["步骤准备中..."]
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // 日历视图
            if isCalendarVisible {
                VStack {
                    DatePicker(
                        "选择日期",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                }
                .frame(height: max(0, calendarHeight - scrollOffset))
                .clipped()
            }
            
            // 餐点时间选择
            Picker("用餐时间", selection: $selectedMealTime) {
                ForEach(0..<mealTimes.count, id: \.self) { index in
                    Text(mealTimes[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color(UIColor.systemBackground))
            
            // 食谱列表
            ScrollView {
                GeometryReader { geometry in
                    Color.clear.preference(key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scroll")).minY)
                }
                .frame(height: 0)
                
                LazyVStack(spacing: 12) {
                    ForEach(recipesForSelectedMeal, id: \.name) { recipe in
                        RecipePlanningCell(
                            name: recipe.name,
                            time: recipe.time,
                            servings: recipe.servings,
                            difficulty: recipe.difficulty,
                            tags: recipe.tags,
                            onTap: {
                                selectedRecipe = recipe
                                showingDetail = true
                            }
                        )
                    }
                }
                .padding()
                .id(selectedMealTime)
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                let newOffset = -offset
                if newOffset > 0 {
                    withAnimation {
                        isCalendarVisible = false
                    }
                } else if newOffset < -20 {
                    withAnimation {
                        isCalendarVisible = true
                    }
                }
            }
        }
        .navigationTitle("食谱规划")
        .navigationBarItems(
            trailing: HStack {
                Button(action: {
                    withAnimation {
                        isCalendarVisible.toggle()
                    }
                }) {
                    Image(systemName: isCalendarVisible ? "calendar.badge.minus" : "calendar.badge.plus")
                }
            }
        )
        .sheet(isPresented: $showingDetail) {
            Group {
                if let recipe = selectedRecipe {
                    RecipeDetailView(
                        recipeName: recipe.name,
                        difficulty: recipe.difficulty == "简单" ? 1 : recipe.difficulty == "中等" ? 3 : 5,
                        cookingTime: Int(recipe.time.replacingOccurrences(of: "分钟", with: "")) ?? 0,
                        ingredients: getIngredientsForRecipe(recipe.name),
                        steps: getStepsForRecipe(recipe.name)
                    )
                }
            }
            .onDisappear {
                selectedRecipe = nil  // 清理选中的食谱
            }
        }
    }
}

// MARK: - RecipePlanningCell
struct RecipePlanningCell: View {
    let name: String
    let time: String
    let servings: String
    let difficulty: String
    let tags: [String]
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 第一行：标题
            Text(name)
                .font(.title3)
                .fontWeight(.medium)
            
            // 第二行：时间和难度
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                    Text(time)
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .foregroundColor(.gray)
                    Text(servings)
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                
                HStack(spacing: 2) {
                    Text(difficulty == "简单" ? "⭐️" : difficulty == "中等" ? "⭐️⭐️" : "⭐️⭐️⭐️")
                    Text(difficulty)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
            }
            
            // 第三行：标签
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(15)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.15, dampingFraction: 0.5), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                    onTap()
                }
        )
    }
}

// MARK: - ScrollOffsetPreferenceKey
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Recipe Model
struct Recipe {
    let name: String
    let difficulty: Int
    let cookingTime: Int
}

// MARK: - Preview
struct RecipePlanningView_Previews: PreviewProvider {
    static var previews: some View {
        RecipePlanningView()
    }
}
