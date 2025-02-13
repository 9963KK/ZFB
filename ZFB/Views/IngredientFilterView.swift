import SwiftUI

struct IngredientFilterView: View {
    @Binding var filter: IngredientFilter
    let categories: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // 分类筛选
                Section(header: Text("按分类筛选")) {
                    Picker("选择分类", selection: Binding(
                        get: { filter.selectedCategory ?? "全部" },
                        set: { filter.selectedCategory = $0 == "全部" ? nil : $0 }
                    )) {
                        Text("全部").tag("全部")
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                // 时间范围筛选
                Section(header: Text("按时间筛选")) {
                    Picker("时间范围", selection: $filter.selectedTimeRange) {
                        ForEach(IngredientFilter.TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                }
            }
            .navigationTitle("筛选")
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
