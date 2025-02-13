import SwiftUI

struct RecipeDetailView: View {
    // MARK: - Properties
    let recipeName: String
    let difficulty: Int // 1-5表示难度
    let cookingTime: Int // 以分钟为单位
    let ingredients: [String] // 临时使用字符串数组，后续会替换为Ingredient类型
    let steps: [String]
    @State private var isFavorite = false
    @State private var isPressed = false
    
    // 动画参数
    private let pressScale: CGFloat = 0.97
    private let springDamping: Double = 0.6
    private let springResponse: Double = 0.3
    
    // 计算难度显示
    private var difficultyText: String {
        switch difficulty {
        case 1: return "简单"
        case 3: return "中等"
        case 5: return "困难"
        default: return "中等"
        }
    }
    
    private var difficultyStars: String {
        switch difficulty {
        case 1: return "⭐️"
        case 3: return "⭐️⭐️"
        case 5: return "⭐️⭐️⭐️"
        default: return "⭐️⭐️"
        }
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 顶部图片（暂时使用占位图）
                Image(systemName: "fork.knife.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                
                VStack(alignment: .leading, spacing: 20) {
                    // 基本信息
                    HStack {
                        Text(recipeName)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: { isFavorite.toggle() }) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(isFavorite ? .red : .gray)
                        }
                    }
                    
                    // 难度和时间
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .foregroundColor(.gray)
                            Text("\(cookingTime) 分钟")
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        
                        HStack(spacing: 2) {
                            Text(difficultyStars)
                            Text(difficultyText)
                                .foregroundColor(.gray)
                                .font(.subheadline)
                        }
                    }
                    
                    // 所需食材
                    VStack(alignment: .leading, spacing: 12) {
                        Text("所需食材")
                            .font(.headline)
                        
                        ForEach(ingredients, id: \.self) { ingredient in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 8))
                                Text(ingredient)
                                Spacer()
                                // 后续可以添加食材库存状态指示
                            }
                        }
                    }
                    
                    // 烹饪步骤
                    VStack(alignment: .leading, spacing: 16) {
                        Text("烹饪步骤")
                            .font(.headline)
                        
                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(Color.blue))
                                
                                Text(step)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .scaleEffect(isPressed ? pressScale : 1.0)
        .animation(.spring(response: springResponse, dampingFraction: springDamping), value: isPressed)
        .onTapGesture {
            withAnimation {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
                        isPressed = false
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // 分享功能
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
}

// MARK: - Preview
struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RecipeDetailView(
                recipeName: "红烧肉",
                difficulty: 3,
                cookingTime: 60,
                ingredients: ["五花肉 500g", "生抽 2勺", "老抽 1勺", "料酒 2勺", "葱姜蒜适量"],
                steps: [
                    "将五花肉切成大小均匀的块。",
                    "锅中加入适量油，将肉块煎至表面金黄。",
                    "加入葱姜蒜爆香，然后加入生抽、老抽调色。",
                    "加入适量热水，大火烧开后转小火炖煮约45分钟。",
                    "调入盐和鸡精，收汁即可。"
                ]
            )
        }
    }
}