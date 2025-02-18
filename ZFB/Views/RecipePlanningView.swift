import SwiftUI

// 食谱数据模型
struct Recipe: Identifiable {
    let id = UUID()
    let name: String
    let time: String
    let servings: String
    let difficulty: String
    let tags: [String]
}

// 食谱卡片组件
struct RecipeCard: View {
    let recipe: Recipe
    let onTap: () -> Void
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: (CGSize) -> Void
    @State private var isPressed = false
    @State private var isDragging = false
    @State private var pressStartTime: Date? = nil
    @State private var pressStartLocation: CGPoint? = nil
    @State private var dragOffset = CGSize.zero
    
    // 动画参数
    private let animationDuration: Double = 0.15
    private let pressScale: Double = 0.98
    private let dragScale: Double = 1.05
    private let springDamping: Double = 0.5
    private let springResponse: Double = 0.15
    
    // 长按参数
    private let longPressThreshold: TimeInterval = 0.5
    private let moveThreshold: CGFloat = 30
    
    // 添加最大拖拽距离限制
    private let maxDragDistance: CGFloat = 100
    
    // 计算难度星级
    private var difficultyStars: String {
        switch recipe.difficulty {
        case "简单": return "⭐️"
        case "中等": return "⭐️⭐️"
        case "困难": return "⭐️⭐️⭐️"
        default: return "⭐️"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 食谱名称
            Text(recipe.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            // 基本信息
            HStack(spacing: 16) {
                Label(recipe.time, systemImage: "clock")
                Label(recipe.servings, systemImage: "person.2")
                HStack(spacing: 4) {
                    Text(difficultyStars)
                        .font(.caption)
                    Text(recipe.difficulty)
                        .font(.subheadline)
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            // 标签
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(recipe.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemGray6))
                .shadow(color: isDragging ? .black.opacity(0.15) : .black.opacity(0.05),
                       radius: isDragging ? 8 : 2,
                       x: 0,
                       y: isDragging ? 4 : 1)
        )
        .scaleEffect(isDragging ? dragScale : (isPressed ? pressScale : 1.0))
        .offset(dragOffset)
        .animation(.spring(response: springResponse, dampingFraction: springDamping), value: isPressed)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isDragging)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: dragOffset)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if pressStartTime == nil {
                        // 开始按压
                        pressStartTime = Date()
                        pressStartLocation = value.location
                        withAnimation(.easeInOut(duration: animationDuration)) {
                            isPressed = true
                        }
                    }
                    
                    let pressDuration = Date().timeIntervalSince(pressStartTime ?? Date())
                    
                    if pressDuration >= longPressThreshold {
                        // 长按时间达到阈值，进入拖拽模式
                        withAnimation {
                            isDragging = true
                            isPressed = false
                        }
                        // 更新拖拽偏移，只允许垂直方向
                        let verticalOffset = value.translation.height
                        // 限制最大拖拽距离
                        let limitedOffset = min(max(verticalOffset, -maxDragDistance), maxDragDistance)
                        dragOffset = CGSize(
                            width: 0, // 锁定水平方向
                            height: limitedOffset
                        )
                        // 通知父视图拖拽状态变化
                        onDragChanged(dragOffset)
                    } else if let startLocation = pressStartLocation {
                        // 计算移动距离
                        let moveDistance = sqrt(
                            pow(value.location.x - startLocation.x, 2) +
                            pow(value.location.y - startLocation.y, 2)
                        )
                        
                        // 如果移动距离超过阈值，取消按压状态
                        if moveDistance > moveThreshold {
                            withAnimation(.easeInOut(duration: animationDuration)) {
                                isPressed = false
                            }
                        }
                    }
                }
                .onEnded { value in
                    if isDragging {
                        // 结束拖拽，添加速度感知
                        let velocity = value.velocity.height
                        let animationDuration = abs(velocity) > 1000 ? 0.2 : 0.4
                        
                        // 通知父视图拖拽结束
                        onDragEnded(dragOffset)
                        
                        withAnimation(.spring(response: animationDuration, dampingFraction: 0.7)) {
                            isDragging = false
                            dragOffset = .zero
                        }
                        
                        // 添加触觉反馈
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    } else if let startTime = pressStartTime,
                              let startLocation = pressStartLocation {
                        let pressDuration = Date().timeIntervalSince(startTime)
                        let moveDistance = sqrt(
                            pow(value.location.x - startLocation.x, 2) +
                            pow(value.location.y - startLocation.y, 2)
                        )
                        
                        withAnimation(.easeInOut(duration: animationDuration)) {
                            isPressed = false
                        }
                        
                        // 只有在移动距离小于阈值时才触发点击事件
                        if moveDistance < moveThreshold {
                            if pressDuration < longPressThreshold {
                                // 短按
                                onTap()
                            }
                        }
                    }
                    
                    // 重置状态
                    pressStartTime = nil
                    pressStartLocation = nil
                }
        )
    }
}

// 日历日期单元格
struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let hasRecipe: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // 日期数字
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
            
            // 食谱指示点
            if hasRecipe {
                Circle()
                    .fill(isSelected ? .white : .blue)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(width: 36, height: 36)
        .background(
            Circle()
                .fill(isSelected ? Color.blue : Color.clear)
        )
        .overlay(
            Circle()
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// 自定义日历视图
struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    
    private let calendar = Calendar.current
    private let daysInWeek = ["日", "一", "二", "三", "四", "五", "六"]
    @State private var currentMonth: Date = Date()
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }
    
    private var weeks: [[Date]] {
        let interval = calendar.dateInterval(of: .month, for: currentMonth)!
        let firstDay = interval.start
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let daysToAdd = firstWeekday - 1
        
        let firstDateOfGrid = calendar.date(byAdding: .day, value: -daysToAdd, to: firstDay)!
        
        var weeks: [[Date]] = []
        var currentWeek: [Date] = []
        
        // 生成6周的日期
        for dayOffset in 0..<42 {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: firstDateOfGrid)!
            currentWeek.append(date)
            
            if currentWeek.count == 7 {
                weeks.append(currentWeek)
                currentWeek = []
            }
        }
        
        return weeks
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 月份导航栏
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                
                Text(monthFormatter.string(from: currentMonth))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // 星期标题行
            HStack {
                ForEach(daysInWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            
            // 日期网格
            VStack(spacing: 8) {
                ForEach(weeks, id: \.self) { week in
                    HStack(spacing: 0) {
                        ForEach(week, id: \.self) { date in
                            CalendarDayCell(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                hasRecipe: hasRecipeForDate(date)
                            )
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedDate = date
                                    onDateSelected(date)
                                }
                            }
                            .opacity(calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) ? 1 : 0.3)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.vertical)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
    
    private func previousMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
        }
    }
    
    private func nextMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
        }
    }
    
    // 判断某一天是否有食谱
    private func hasRecipeForDate(_ date: Date) -> Bool {
        // TODO: 实现判断逻辑
        return false
    }
}

struct RecipePlanningView: View {
    // MARK: - Properties
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @State private var showingAddRecipe = false
    @State private var selectedMealTime = 0
    @State private var showingFilters = false
    @State private var isCalendarVisible = true
    @State private var selectedRecipe: Recipe?
    @State private var recipes: [[Recipe]] = [
        // 早餐
        [
            Recipe(name: "皮蛋瘦肉粥", time: "30分钟", servings: "2人份", difficulty: "简单", tags: ["粥类", "热门"]),
            Recipe(name: "三明治", time: "15分钟", servings: "2人份", difficulty: "简单", tags: ["面包", "快手"]),
            Recipe(name: "煎饺", time: "20分钟", servings: "3人份", difficulty: "简单", tags: ["家常菜", "热门"])
        ],
        // 午餐
        [
            Recipe(name: "红烧排骨", time: "45分钟", servings: "4人份", difficulty: "中等", tags: ["家常菜", "热门", "肉类"]),
            Recipe(name: "清炒小白菜", time: "20分钟", servings: "4人份", difficulty: "简单", tags: ["素菜", "快手"]),
            Recipe(name: "番茄炒蛋", time: "15分钟", servings: "3人份", difficulty: "简单", tags: ["家常菜", "快手"])
        ],
        // 晚餐
        [
            Recipe(name: "水煮鱼", time: "40分钟", servings: "4人份", difficulty: "困难", tags: ["川菜", "热门", "海鲜"]),
            Recipe(name: "宫保鸡丁", time: "35分钟", servings: "4人份", difficulty: "中等", tags: ["川菜", "热门", "肉类"]),
            Recipe(name: "蒜蓉炒菜心", time: "15分钟", servings: "4人份", difficulty: "简单", tags: ["素菜", "快手"])
        ]
    ]
    // 添加 recipeOrders 数组来存储每个时段的食谱顺序
    @State private var recipeOrders: [[UUID]] = Array(repeating: [], count: 3)
    @State private var draggedRecipe: Recipe?
    @State private var draggedMealTime: Int?
    
    private let mealTimes = ["早餐", "午餐", "晚餐"]
    private let calendar = Calendar.current
    
    // 初始化 recipeOrders
    private func initializeRecipeOrders() {
        // 为每个时段创建对应的顺序数组
        for mealTimeIndex in 0..<recipes.count {
            recipeOrders[mealTimeIndex] = recipes[mealTimeIndex].map { $0.id }
        }
    }
    
    // 处理拖拽排序
    private func handleRecipeDrag(recipe: Recipe, dragOffset: CGSize, mealTimeIndex: Int) {
        // 确保索引有效
        guard mealTimeIndex >= 0 && mealTimeIndex < recipes.count,
              let currentIndex = recipes[mealTimeIndex].firstIndex(where: { $0.id == recipe.id }) else { return }
        
        // 计算目标位置
        let cardHeight: CGFloat = 120 // 估计的卡片高度
        let targetIndex = currentIndex + Int(round(dragOffset.height / cardHeight))
        let safeTargetIndex = max(0, min(targetIndex, recipes[mealTimeIndex].count - 1))
        
        if safeTargetIndex != currentIndex {
            // 使用 withAnimation 包装整个移动过程
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                var updatedRecipes = recipes
                let recipe = updatedRecipes[mealTimeIndex].remove(at: currentIndex)
                updatedRecipes[mealTimeIndex].insert(recipe, at: safeTargetIndex)
                recipes = updatedRecipes
                
                // 同步更新 recipeOrders
                var updatedRecipeOrders = recipeOrders
                let recipeId = recipe.id
                updatedRecipeOrders[mealTimeIndex].remove(at: currentIndex)
                updatedRecipeOrders[mealTimeIndex].insert(recipeId, at: safeTargetIndex)
                recipeOrders = updatedRecipeOrders
            }
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
                CustomCalendarView(selectedDate: $selectedDate) { date in
                    print("选择日期: \(date)")
                }
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // 餐点时间选择
            Picker("用餐时间", selection: $selectedMealTime) {
                ForEach(0..<mealTimes.count, id: \.self) { index in
                    Text(mealTimes[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // 食谱列表
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(recipeOrders[selectedMealTime], id: \.self) { recipeId in
                        if let recipe = recipes[selectedMealTime].first(where: { $0.id == recipeId }) {
                            RecipeCard(
                                recipe: recipe,
                                onTap: {
                                    selectedRecipe = recipe
                                },
                                onDragChanged: { offset in
                                    if draggedRecipe == nil {
                                        draggedRecipe = recipe
                                        draggedMealTime = selectedMealTime
                                    }
                                },
                                onDragEnded: { offset in
                                    if let draggedRecipe = draggedRecipe,
                                       let draggedMealTime = draggedMealTime {
                                        handleRecipeDrag(
                                            recipe: draggedRecipe,
                                            dragOffset: offset,
                                            mealTimeIndex: draggedMealTime
                                        )
                                    }
                                    draggedRecipe = nil
                                    draggedMealTime = nil
                                }
                            )
                            .frame(maxWidth: min(UIScreen.main.bounds.width - 48, 500))  // 限制最大宽度
                        }
                    }
                }
                .padding(.vertical)
            }
            .padding(.horizontal, 18)  // 增加水平边距
        }
        .navigationTitle("食谱规划")
        .navigationBarItems(
            trailing: HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isCalendarVisible.toggle()
                    }
                }) {
                    Image(systemName: isCalendarVisible ? "calendar.badge.minus" : "calendar.badge.plus")
                }
            }
        )
        .sheet(item: $selectedRecipe) { recipe in
            RecipeDetailView(recipe: recipe)
        }
        .onAppear {
            initializeRecipeOrders()
        }
    }
}

// MARK: - Preview
struct RecipePlanningView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RecipePlanningView()
        }
    }
}
