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
    
    // 获取所有可用的分类
    private var categories: [String] {
        let allCategories = ingredients.compactMap { $0.category }
        return Array(Set(allCategories)).sorted()
    }
    
    // 筛选后的食材
    private var filteredIngredients: [Ingredient] {
        Array(ingredients).filter { ingredient in
            filter.filter([ingredient]).contains(ingredient)
        }
    }
    
    private func showIngredientEdit(_ ingredient: Ingredient) {
        // 确保数据已经加载
        viewContext.refresh(ingredient, mergeChanges: true)
        selectedIngredient = ingredient
        showingEditSheet = true
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
                            ForEach(filteredIngredients, id: \.objectID) { ingredient in
                                IngredientCard(ingredient: ingredient) {
                                    showIngredientEdit(ingredient)
                                }
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
    var onPress: () -> Void
    
    // 动画参数
    private let animationDuration: Double = 0.15
    private let pressScale: Double = 0.98
    private let dragScale: Double = 1.05
    private let springDamping: Double = 0.5
    private let springResponse: Double = 0.15
    
    // 长按参数
    private let longPressThreshold: TimeInterval = 1.2
    private let moveThreshold: CGFloat = 30
    
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
                        // 更新拖拽偏移
                        dragOffset = CGSize(
                            width: value.translation.width,
                            height: value.translation.height
                        )
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
                        // 结束拖拽
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
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
                                onPress()
                            }
                        }
                    }
                    
                    // 重置状态
                    pressStartTime = nil
                    pressStartLocation = nil
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
