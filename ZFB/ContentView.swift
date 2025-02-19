//
//  ContentView.swift
//  ZFB
//
//  Created by 陈杰豪 on 9/2/2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ingredient.name, ascending: true)],
        animation: .default)
    private var ingredients: FetchedResults<Ingredient>
    
    @State private var showingAddSheet = false
    @State private var selectedIngredient: Ingredient?
    @State private var showingEditSheet = false
    @State private var selectedTab = 0
    @State private var isLoading = true
    @State private var showingFilterSheet = false
    @State private var showingCategoryCheckSheet = false
    @State private var filter = IngredientFilter()
    @State private var draggedIngredient: Ingredient?
    @State private var ingredientOrder: [NSManagedObjectID] = []
    
    // 获取所有可用的分类
    private var categories: [String] {
        let allCategories = ingredients.compactMap { $0.category }
        return Array(Set(allCategories)).sorted()
    }
    
    // 筛选并排序后的食材
    private var sortedAndFilteredIngredients: [Ingredient] {
        let filtered = Array(ingredients).filter { ingredient in
            filter.filter([ingredient]).contains(ingredient)
        }
        
        if ingredientOrder.isEmpty {
            return filtered
        }
        
        // 根据自定义顺序排序
        return filtered.sorted { ingredient1, ingredient2 in
            guard let index1 = ingredientOrder.firstIndex(of: ingredient1.objectID),
                  let index2 = ingredientOrder.firstIndex(of: ingredient2.objectID) else {
                return false
            }
            return index1 < index2
        }
    }
    
    private func showIngredientEdit(_ ingredient: Ingredient) {
        viewContext.refresh(ingredient, mergeChanges: true)
        selectedIngredient = ingredient
        showingEditSheet = true
    }
    
    // 处理拖拽排序
    private func handleIngredientDrag(ingredient: Ingredient, dragOffset: CGSize) {
        let cardHeight: CGFloat = 120 // 估计的卡片高度
        guard let currentIndex = sortedAndFilteredIngredients.firstIndex(where: { $0.objectID == ingredient.objectID }) else { return }
        
        // 计算目标位置
        let targetIndex = currentIndex + Int(round(dragOffset.height / cardHeight))
        let safeTargetIndex = max(0, min(targetIndex, sortedAndFilteredIngredients.count - 1))
        
        if safeTargetIndex != currentIndex {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                // 更新顺序
                var newOrder = sortedAndFilteredIngredients.map { $0.objectID }
                let movedID = newOrder.remove(at: currentIndex)
                newOrder.insert(movedID, at: safeTargetIndex)
                ingredientOrder = newOrder
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 食材标签页
            NavigationView {
                ScrollView {
                    if isLoading {
                        ProgressView("加载中...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(sortedAndFilteredIngredients, id: \.objectID) { ingredient in
                                IngredientCard(
                                    ingredient: ingredient,
                                    onPress: {
                                        showIngredientEdit(ingredient)
                                    },
                                    onDragChanged: { offset in
                                        if draggedIngredient == nil {
                                            draggedIngredient = ingredient
                                        }
                                    },
                                    onDragEnded: { offset in
                                        if let draggedIngredient = draggedIngredient {
                                            handleIngredientDrag(
                                                ingredient: draggedIngredient,
                                                dragOffset: offset
                                            )
                                        }
                                        draggedIngredient = nil
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("我的食材")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button(action: { showingCategoryCheckSheet = true }) {
                                Label("检查类别", systemImage: "exclamationmark.triangle")
                            }
                            Button(action: { showingFilterSheet = true }) {
                                Label("筛选", systemImage: "line.3.horizontal.decrease.circle")
                            }
                            Button(action: { showingAddSheet = true }) {
                                Label("添加食材", systemImage: "plus")
                            }
                        }
                    }
                }
                .onAppear {
                    viewContext.refreshAllObjects()
                    // 初始化排序顺序
                    if ingredientOrder.isEmpty {
                        ingredientOrder = ingredients.map { $0.objectID }
                    }
                    isLoading = false
                }
                .sheet(isPresented: $showingAddSheet) {
                    AddIngredientView(isPresented: $showingAddSheet)
                }
                .sheet(isPresented: $showingEditSheet) {
                    Group {
                        if let ingredient = selectedIngredient {
                            EditIngredientView(ingredient: ingredient)
                                .environment(\.managedObjectContext, viewContext)
                        }
                    }
                }
                .sheet(isPresented: $showingFilterSheet) {
                    IngredientFilterView(filter: $filter, categories: categories)
                }
                .sheet(isPresented: $showingCategoryCheckSheet) {
                    IngredientCategoryCheckView()
                        .environment(\.managedObjectContext, viewContext)
                }
            }
            .tabItem {
                Label("食材", systemImage: "carrot")
            }
            .tag(0)
            
            // 食谱规划标签页
            NavigationView {
                RecipePlanningView()
            }
            .tabItem {
                Label("食谱", systemImage: "fork.knife")
            }
            .tag(1)
        }
    }
}

struct IngredientCard: View {
    @ObservedObject var ingredient: Ingredient
    @State private var isPressed = false
    @State private var isDragging = false
    @State private var pressStartTime: Date? = nil
    @State private var pressStartLocation: CGPoint? = nil
    @State private var dragOffset = CGSize.zero
    @State private var totalMovement: CGFloat = 0
    var onPress: () -> Void
    var onDragChanged: (CGSize) -> Void
    var onDragEnded: (CGSize) -> Void
    
    // 动画参数
    private let animationDuration: Double = 0.15
    private let pressScale: Double = 0.98
    private let dragScale: Double = 1.05
    private let springDamping: Double = 0.5
    private let springResponse: Double = 0.15
    
    // 手势参数
    private let longPressThreshold: TimeInterval = 0.5
    private let moveThreshold: CGFloat = 8  // 增加移动阈值，减少误触发
    private let tapThreshold: CGFloat = 3   // 减小点击阈值，提高点击精确度
    private let maxDragDistance: CGFloat = 100
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧圆形图标
            ZStack {
                Circle()
                    .fill(IngredientColorManager.getColor(for: ingredient.category).opacity(0.2))
                    .frame(width: 80, height: 80)
                
                if let imageData = ingredient.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else if let name = ingredient.name,
                          let emoji = IngredientEmojiManager.shared.getEmoji(for: name) {
                    Text(emoji)
                        .font(.system(size: 40))
                } else {
                    Text(IngredientIcon.getIcon(for: ingredient.category))
                        .font(.system(size: 40))
                }
            }
            
            // 右侧信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(ingredient.name ?? "未命名")
                        .font(.headline)
                    if ingredient.quantity == 0 {
                        Text("🈳")
                            .font(.system(size: 14))
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.5), value: ingredient.quantity == 0)
                    }
                }
                
                Text(ingredient.category ?? "未分类")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text(UnitFormatter.format(quantity: ingredient.quantity, unit: ingredient.unit ?? "个"))
                            .font(.system(size: 14, weight: .medium))
                        Text(ingredient.unit ?? "")
                            .font(.system(size: 12))
                    }
                    
                    Text(purchaseDaysText)
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    
                    Text(expiryDateText)
                        .font(.system(size: 12))
                        .foregroundColor(expiryDateColor)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .medium))
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: isDragging ? .black.opacity(0.15) : .black.opacity(0.1),
               radius: isDragging ? 8 : 5,
               x: 0,
               y: isDragging ? 4 : 2)
        .scaleEffect(isDragging ? dragScale : (isPressed ? pressScale : 1.0))
        .offset(dragOffset)
        .animation(.spring(response: springResponse, dampingFraction: springDamping), value: isPressed)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isDragging)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: dragOffset)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if pressStartTime == nil {
                        pressStartTime = Date()
                        pressStartLocation = value.location
                        withAnimation(.easeInOut(duration: animationDuration)) {
                            isPressed = true
                        }
                        totalMovement = 0
                    }
                    
                    let pressDuration = Date().timeIntervalSince(pressStartTime ?? Date())
                    
                    if let startLocation = pressStartLocation {
                        // 计算移动距离和方向
                        let verticalMovement = abs(value.location.y - startLocation.y)
                        let horizontalMovement = abs(value.location.x - startLocation.x)
                        let currentMovement = sqrt(
                            pow(value.location.x - startLocation.x, 2) +
                            pow(value.location.y - startLocation.y, 2)
                        )
                        totalMovement = currentMovement
                        
                        // 优先判断是否为滚动意图
                        if verticalMovement > moveThreshold && verticalMovement > horizontalMovement * 1.2 {
                            // 明显的垂直滑动意图，取消所有卡片操作
                            withAnimation(.easeInOut(duration: animationDuration)) {
                                isPressed = false
                                isDragging = false
                                dragOffset = .zero
                            }
                            pressStartTime = nil
                            pressStartLocation = nil
                            return
                        }
                        
                        // 处理其他手势意图
                        if currentMovement > moveThreshold {
                            withAnimation(.easeInOut(duration: animationDuration)) {
                                isPressed = false
                            }
                            
                            // 长按进入拖拽模式
                            if pressDuration >= longPressThreshold {
                                withAnimation {
                                    isDragging = true
                                    isPressed = false
                                }
                                
                                // 更新拖拽偏移，只允许垂直方向
                                let verticalOffset = value.translation.height
                                let limitedOffset = min(max(verticalOffset, -maxDragDistance), maxDragDistance)
                                dragOffset = CGSize(width: 0, height: limitedOffset)
                                onDragChanged(dragOffset)
                            }
                        }
                    }
                }
                .onEnded { value in
                    if isDragging {
                        // 结束拖拽
                        onDragEnded(dragOffset)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isDragging = false
                            dragOffset = .zero
                        }
                        
                        // 触觉反馈
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    } else {
                        withAnimation(.easeInOut(duration: animationDuration)) {
                            isPressed = false
                        }
                        
                        // 只有在移动距离小于点击阈值，且主要是水平移动时才触发点击事件
                        if totalMovement < tapThreshold {
                            onPress()
                        }
                    }
                    
                    // 重置状态
                    pressStartTime = nil
                    pressStartLocation = nil
                    totalMovement = 0
                }
        )
    }
    
    private var purchaseDaysText: String {
        guard let purchaseDate = ingredient.purchaseDate else { return "未记录购买日期" }
        let days = Calendar.current.dateComponents([.day], from: purchaseDate, to: Date()).day ?? 0
        return days == 0 ? "今天购买" : "已购买\(days)天"
    }
    
    private var expiryDateText: String {
        guard let expiryDate = ingredient.expiryDate else { return "无过期日期" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
        if days < 0 {
            return "已过期"
        } else if days == 0 {
            return "今天过期"
        } else {
            return "还剩\(days)天"
        }
    }
    
    private var expiryDateColor: Color {
        guard let expiryDate = ingredient.expiryDate else { return .secondary }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
        if days < 0 {
            return .red
        } else if days <= 3 {
            return .orange
        } else {
            return .green
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
