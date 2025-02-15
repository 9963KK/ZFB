import SwiftUI

// 自定义卡片视图组件
struct DateCard: View {
    let title: String
    let content: AnyView
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: .systemGray6))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
    }
}

// 快捷日期选择组件
struct ShelfLifeOptionsView: View {
    let purchaseDate: Date
    @Binding var expiryDate: Date
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    // 预设的保质期选项（天数）
    private let shelfLifeOptions = [
        3, 5, 7, 14, 30, 60, 90
    ]
    
    // 计算合适的字体大小
    private var buttonFontSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 12
        case .medium:
            return 13
        case .large:
            return 14
        default:
            return 12
        }
    }
    
    // 计算合适的按钮高度
    private var buttonHeight: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return 26
        case .medium:
            return 30
        case .large:
            return 34
        default:
            return 30
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("快捷选择")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(shelfLifeOptions, id: \.self) { days in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                expiryDate = Calendar.current.date(byAdding: .day, value: days, to: purchaseDate) ?? Date()
                            }
                        }) {
                            Text("\(days)天")
                                .font(.system(size: buttonFontSize, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isSelected(days: days) ?
                                            Color.blue.opacity(0.2) :
                                            Color(uiColor: .systemGray5))
                                )
                                .foregroundColor(isSelected(days: days) ? .blue : .primary)
                        }
                        .buttonStyle(
                            ScaleButtonStyle(
                                scaleAmount: 0.95,
                                duration: 0.1
                            )
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(height: buttonHeight)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: .systemGray6))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
    
    // 检查是否为当前选中的天数
    private func isSelected(days: Int) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: purchaseDate, to: expiryDate)
        return components.day == days
    }
}

// 自定义按钮样式
struct ScaleButtonStyle: ButtonStyle {
    let scaleAmount: CGFloat
    let duration: Double
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1)
            .animation(.easeInOut(duration: duration), value: configuration.isPressed)
    }
}

// 主视图
struct DateSelectionView: View {
    @Binding var purchaseDate: Date
    @Binding var expiryDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 存入日期选择
            DateCard(
                title: "存入日期",
                content: AnyView(
                    DatePicker("", selection: $purchaseDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                )
            )
            
            // 过期日期选择
            DateCard(
                title: "过期日期",
                content: AnyView(
                    DatePicker("", selection: $expiryDate, in: purchaseDate..., displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                )
            )
            
            // 分隔线
            Divider()
                .padding(.vertical, 8)
            
            // 快捷选择视图
            ShelfLifeOptionsView(purchaseDate: purchaseDate, expiryDate: $expiryDate)
        }
        .padding(.vertical, 8)
    }
}

// 预览提供者
struct DateSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DateSelectionView(
                purchaseDate: .constant(Date()),
                expiryDate: .constant(Date().addingTimeInterval(7*24*60*60))
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .preferredColorScheme(.light)
            
            DateSelectionView(
                purchaseDate: .constant(Date()),
                expiryDate: .constant(Date().addingTimeInterval(7*24*60*60))
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .preferredColorScheme(.dark)
        }
    }
}
