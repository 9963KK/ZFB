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
                                    selectedIngredient = ingredient
                                    showingEditSheet = true
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
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                                .animation(.easeInOut(duration: 0.9), value: showingEditSheet)
                        }
                    }
                    .onDisappear {
                        selectedIngredient = nil  // 清理选中的食材
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
    var onPress: () -> Void
    
    // 动画参数
    private let animationDuration: Double = 0.15  // 减少动画持续时间
    private let pressScale: Double = 0.98        // 调整缩放比例
    private let springDamping: Double = 0.5      // 减小阻尼系数，让动画更快
    private let springResponse: Double = 0.15    // 减小响应时间
    
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
                } else if let emoji = IngredientEmojiManager.shared.getEmoji(for: ingredient.name ?? "") {
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
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .scaleEffect(isPressed ? pressScale : 1.0)
        .animation(.spring(response: springResponse, dampingFraction: springDamping), value: isPressed)
        .onTapGesture {
            withAnimation {
                isPressed = true
                // 延长按下状态的时间
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                    withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
                        isPressed = false
                    }
                    // 等动画完全结束后再触发回调
                    DispatchQueue.main.asyncAfter(deadline: .now() + springResponse) {
                        onPress()
                    }
                }
            }
        }
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
