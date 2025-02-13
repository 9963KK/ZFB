import SwiftUI

struct IngredientCategoryCheckView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ingredient.name, ascending: true)],
        animation: .default)
    private var ingredients: FetchedResults<Ingredient>
    
    @Environment(\.dismiss) private var dismiss
    
    // 获取没有正确分类的食材
    private var uncategorizedIngredients: [Ingredient] {
        ingredients.filter { ingredient in
            guard let name = ingredient.name else { return false }
            return IngredientCategoryManager.shared.getCategory(for: name) == nil
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                if uncategorizedIngredients.isEmpty {
                    Text("所有食材都已正确分类")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    Section(header: Text("需要检查的食材")) {
                        ForEach(uncategorizedIngredients, id: \.objectID) { ingredient in
                            HStack {
                                Text(ingredient.name ?? "未命名")
                                Spacer()
                                Text("未分类")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Section {
                        Text("提示：这些食材没有对应的类别，建议：")
                        Text("1. 检查食材名称是否正确")
                        Text("2. 考虑添加新的类别")
                    }
                    .font(.footnote)
                    .foregroundColor(.gray)
                }
            }
            .navigationTitle("类别检查")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}
