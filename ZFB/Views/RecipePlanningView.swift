import SwiftUI

struct RecipePlanningView: View {
    // MARK: - Properties
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @State private var showingAddRecipe = false
    @State private var selectedMealTime = 0
    @State private var showingFilters = false
    @State private var calendarHeight: CGFloat = 300 // 日历的默认高度
    @State private var scrollOffset: CGFloat = 0
    @State private var isCalendarVisible = true
    
    private let mealTimes = ["早餐", "午餐", "晚餐", "小食"]
    private let calendar = Calendar.current
    
    // MARK: - Body
    var body: some View {
        NavigationView {
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
                    // 获取滚动偏移量
                    GeometryReader { geometry in
                        Color.clear.preference(key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY)
                    }
                    .frame(height: 0)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(0..<10) { _ in
                            RecipePlanningCell()
                        }
                    }
                    .padding()
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                    // 处理滚动偏移量
                    let newOffset = -offset
                    if newOffset > 0 {
                        withAnimation {
                            isCalendarVisible = false
                        }
                    } else if newOffset < -20 { // 添加一些缓冲区，使其更容易显示日历
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
                    Button(action: {
                        // 分享功能
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            )
        }
    }
}

// MARK: - ScrollOffsetPreferenceKey
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - RecipePlanningCell
struct RecipePlanningCell: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("红烧排骨")
                    .font(.headline)
                Spacer()
                Text("4人份")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Label("45分钟", systemImage: "clock")
                Spacer()
                Label("中等难度", systemImage: "star.fill")
            }
            .font(.caption)
            .foregroundColor(.gray)
            
            // 标签
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(["家常菜", "热门", "肉类"], id: \.self) { tag in
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
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview
struct RecipePlanningView_Previews: PreviewProvider {
    static var previews: some View {
        RecipePlanningView()
    }
}
