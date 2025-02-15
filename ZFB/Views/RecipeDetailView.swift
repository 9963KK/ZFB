import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @State private var isFavorite = false
    
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
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 顶部图片
                    ZStack(alignment: .bottomTrailing) {
                        Image(recipe.name)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [.clear, .black.opacity(0.3)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            // 如果没有对应图片，使用默认图片
                            .onAppear {
                                if UIImage(named: recipe.name) == nil {
                                    print("使用默认图片")
                                }
                            }
                        
                        // 收藏按钮
                        Button(action: { isFavorite.toggle() }) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundColor(isFavorite ? .red : .white)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                )
                        }
                        .padding([.bottom, .trailing], 16)
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // 基本信息
                        VStack(alignment: .leading, spacing: 12) {
                            Text(recipe.name)
                                .font(.title)
                                .fontWeight(.bold)
                            
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
                        }
                        
                        // 标签
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recipe.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        
                        Divider()
                        
                        // 食材列表
                        VStack(alignment: .leading, spacing: 12) {
                            Text("食材")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(getIngredientsForRecipe(recipe.name), id: \.self) { ingredient in
                                    HStack(spacing: 8) {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 6))
                                            .foregroundColor(.blue)
                                        Text(ingredient)
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        // 步骤
                        VStack(alignment: .leading, spacing: 12) {
                            Text("步骤")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(Array(getStepsForRecipe(recipe.name).enumerated()), id: \.offset) { index, step in
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("\(index + 1)")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(width: 24, height: 24)
                                            .background(Circle().fill(Color.blue))
                                        
                                        Text(step)
                                            .font(.subheadline)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // 获取食谱食材
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
    
    // 获取食谱步骤
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
}

struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeDetailView(
            recipe: Recipe(
                name: "红烧排骨",
                time: "45分钟",
                servings: "4人份",
                difficulty: "中等",
                tags: ["家常菜", "热门", "肉类"]
            )
        )
    }
}