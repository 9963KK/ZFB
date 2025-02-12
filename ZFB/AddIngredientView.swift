import SwiftUI
import CoreData

struct AddIngredientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var quantity = "1"
    @State private var unit = ""
    @State private var category = "蔬菜"
    @State private var purchaseDate = Date()
    @State private var expiryDate = Date()
    @State private var notes = ""
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let categories = ["蔬菜", "水果", "肉类", "海鲜", "调味料", "其他"]
    private let dateRanges = [3, 5, 7, 14, 30, 60, 90]
    
    var body: some View {
        NavigationView {
            Form {
                // 基本信息
                Section(header: Text("基本信息")) {
                    TextField("名称", text: $name)
                    
                    // 类别选择
                    HStack {
                        Text("分类")
                        Spacer()
                        Picker("", selection: $category) {
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // 数量和单位
                    HStack {
                        Spacer()
                        if IngredientUnitManager.shared.supportsQuickAdjust(unit) {
                            Button(action: {
                                if let current = Double(quantity), current > 0 {
                                    quantity = String(current - 1)
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                            .disabled(Double(quantity) ?? 0 <= 1)
                        }
                        
                        if IngredientUnitManager.shared.supportsQuickAdjust(unit) {
                            Text(quantity)
                                .frame(minWidth: 40)
                                .multilineTextAlignment(.center)
                        } else {
                            TextField("", text: $quantity)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .frame(minWidth: 60, idealWidth: 80, maxWidth: 120)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        if IngredientUnitManager.shared.supportsQuickAdjust(unit) {
                            Button(action: {
                                if let current = Double(quantity) {
                                    quantity = String(current + 1)
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Picker("", selection: $unit) {
                            ForEach(IngredientUnitManager.shared.getUnitsForCategory(category), id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 80)
                    }
                }
                
                // 日期信息
                Section(header: Text("日期信息")) {
                    HStack {
                        Text("存入")
                        Spacer()
                        DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                    }
                    
                    HStack {
                        Text("过期")
                        Spacer()
                        DatePicker("", selection: $expiryDate, displayedComponents: .date)
                    }
                    
                    // 快捷日期选择
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(dateRanges, id: \.self) { days in
                                Button(action: {
                                    expiryDate = Calendar.current.date(byAdding: .day, value: days, to: purchaseDate) ?? Date()
                                }) {
                                    Text("\(days)天")
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // 备注
                Section(header: Text("备注")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                // 图片
                Section(header: Text("图片")) {
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        Text(inputImage == nil ? "选择图片" : "更换图片")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("添加食材")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveIngredient()
                    }
                }
            }
            .onChange(of: category) { newCategory in
                unit = IngredientUnitManager.shared.getDefaultUnitForCategory(newCategory)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage)
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveIngredient() {
        // 检查是否存在重复的食材名称
        let fetchRequest: NSFetchRequest<Ingredient> = Ingredient.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name ==[c] %@", name)
        
        do {
            let matchingIngredients = try viewContext.fetch(fetchRequest)
            if !matchingIngredients.isEmpty {
                showingAlert = true
                alertMessage = "已经存在相同名称的食材"
                return
            }
            
            let ingredient = Ingredient(context: viewContext)
            ingredient.name = name
            ingredient.category = category
            ingredient.quantity = Double(quantity) ?? 0
            ingredient.unit = unit
            ingredient.purchaseDate = purchaseDate
            ingredient.expiryDate = expiryDate
            ingredient.notes = notes
            
            if let inputImage = inputImage {
                ingredient.imageData = inputImage.jpegData(compressionQuality: 0.8)
            }
            
            do {
                try viewContext.save()
                dismiss()
            } catch {
                let nsError = error as NSError
                print("保存食材失败: \(nsError)")
            }
        } catch {
            print("检查重复食材失败: \(error)")
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
