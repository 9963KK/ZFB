import SwiftUI

struct DateSelectionView: View {
    @Binding var purchaseDate: Date
    @Binding var expiryDate: Date
    
    // 预设的保质期选项（天数）
    private let shelfLifeOptions = [
        3, 5, 7, 14, 30, 60, 90
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 日期选择行
            HStack(spacing: 8) {
                // 存入时间选择
                HStack(spacing: 4) {
                    Text("存入")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 32, alignment: .trailing)
                    DatePicker("", selection: $purchaseDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                
                Text("-")
                    .foregroundColor(.secondary)
                
                // 过期时间选择
                HStack(spacing: 4) {
                    Text("过期")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 32, alignment: .trailing)
                    DatePicker("", selection: $expiryDate, in: purchaseDate..., displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
            }
            
            // 快捷保质期选择行
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(shelfLifeOptions, id: \.self) { days in
                        Button(action: {
                            withAnimation {
                                expiryDate = Calendar.current.date(byAdding: .day, value: days, to: purchaseDate) ?? Date()
                            }
                        }) {
                            Text("\(days)天")
                                .font(.system(size: 12))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    isSelected(days: days) ?
                                    Color.blue.opacity(0.2) :
                                    Color.gray.opacity(0.1)
                                )
                                .foregroundColor(
                                    isSelected(days: days) ?
                                    .blue :
                                    .primary
                                )
                                .cornerRadius(6)
                        }
                    }
                }
            }
            .frame(height: 26)
        }
        .padding(.vertical, 8)
    }
    
    // 检查是否为当前选中的天数
    private func isSelected(days: Int) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: purchaseDate, to: expiryDate)
        return components.day == days
    }
}
