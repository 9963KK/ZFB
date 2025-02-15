import SwiftUI
import CoreData

struct AddIngredientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var category = "蔬菜"
    @State private var quantity = "1"
    @State private var unit = "个"
    @State private var purchaseDate = Date()
    @State private var expiryDate = Date()
    @State private var notes = ""
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingCategoryMismatchAlert = false
    @State private var suggestedCategory: String?
    @State private var showingCategoryPicker = false
    @FocusState private var isNameFieldFocused: Bool
    
    // 整数单位列表
    private let integerUnits = ["个", "颗", "把", "包"]
    
    // 判断是否为整数单位
    private var isIntegerUnit: Bool {
        integerUnits.contains(unit)
    }
    
    // 当前数量
    private var currentQuantity: Double {
        Double(quantity.replacingOccurrences(of: ",", with: "")) ?? 0
    }
    
    // 格式化数量
    private func formatQuantity(_ value: Double) {
        quantity = String(format: "%.0f", value)
    }
    
    let commonUnits = ["个", "颗", "把", "包", "克", "千克", "升", "毫升"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    HStack(spacing: 12) {
                        TextField("名称", text: $name)
                            .onChange(of: name) { newName in
                                // 当输入内容变化时，不做检查
                            }
                            .onSubmit {
                                checkCategory()
                            }
                            .focused($isNameFieldFocused)
                            .submitLabel(.done)
                        
                        HStack(spacing: 4) {
                            Text("分类")
                                .foregroundColor(.secondary)
                            Picker("", selection: $category) {
                                ForEach(IngredientCategoryManager.shared.categories, id: \.self) { cat in
                                    Text("\(IngredientIcon.getIcon(for: cat)) \(cat)")
                                        .tag(cat)
                                        .lineLimit(1)
                                        .fixedSize()
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .labelsHidden()
                        }
                        .frame(width: 150)
                    }
                    .onChange(of: isNameFieldFocused) { isFocused in
                        if !isFocused && !name.isEmpty {
                            // 当输入框失去焦点且内容不为空时检查类别
                            checkCategory()
                        }
                    }
                    
                    HStack {
                        if isIntegerUnit {
                            Button(action: {
                                let newValue = max(0, currentQuantity - 1)
                                formatQuantity(newValue)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.blue)
                                    .imageScale(.large)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        
                        TextField("数量", text: $quantity)
                            .keyboardType(.decimalPad)
                            .frame(minWidth: 50)
                            .multilineTextAlignment(.center)
                        
                        if isIntegerUnit {
                            Button(action: {
                                let newValue = currentQuantity + 1
                                formatQuantity(newValue)
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                    .imageScale(.large)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        
                        Picker("单位", selection: $unit) {
                            ForEach(commonUnits, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .onChange(of: unit) { newUnit in
                            // 当单位改变时，重新格式化数量
                            if let value = Double(quantity) {
                                quantity = UnitFormatter.format(quantity: value, unit: newUnit)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section(header: Text("日期信息")) {
                    DateSelectionView(purchaseDate: $purchaseDate, expiryDate: $expiryDate)
                }
                
                Section(header: Text("备注")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Section(header: Text("图片")) {
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            Text(inputImage == nil ? "选择图片" : "更换图片")
                            Spacer()
                            if inputImage != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
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
                    .disabled(name.isEmpty || category.isEmpty || quantity.isEmpty || unit.isEmpty)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage)
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .alert("食材类别不匹配", isPresented: $showingCategoryMismatchAlert) {
                Button("更新为\(suggestedCategory ?? "")") {
                    if let newCategory = suggestedCategory {
                        category = newCategory
                    }
                }
                Button("保持现有类别", role: .cancel) {}
            } message: {
                if suggestedCategory == "其他" {
                    Text("这是一个新的食材类别，建议将其标记为待分类。是否将\"\(name)\"设置为\"其他\"类别？")
                } else {
                    Text("检测到\"\(name)\"可能属于\"\(suggestedCategory ?? "")\"类别，是否要更新？")
                }
            }
        }
    }
    
    private func saveIngredient() {
        let fetchRequest: NSFetchRequest<Ingredient> = Ingredient.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let duplicates = try viewContext.fetch(fetchRequest)
            if !duplicates.isEmpty {
                alertMessage = "该食材已存在"
                showingAlert = true
                name = ""
                category = "蔬菜"
                return
            }
            
            let newIngredient = Ingredient(context: viewContext)
            newIngredient.name = name
            newIngredient.category = category
            newIngredient.quantity = Double(quantity) ?? 0
            newIngredient.unit = unit
            newIngredient.purchaseDate = purchaseDate
            newIngredient.expiryDate = expiryDate
            newIngredient.notes = notes
            
            if let imageData = inputImage?.jpegData(compressionQuality: 0.8) {
                newIngredient.imageData = imageData
            }
            
            try viewContext.save()
            dismiss()
        } catch {
            alertMessage = "保存失败: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func checkCategory() {
        if !name.isEmpty {
            let suggestedCat = IngredientCategoryManager.shared.getCategory(for: name)
            if suggestedCat == "其他" {
                // 如果是新的食材（被归类为"其他"），显示提示
                suggestedCategory = "其他"
                showingCategoryMismatchAlert = true
            } else if suggestedCat != category {
                // 如果有建议的其他分类，显示建议
                suggestedCategory = suggestedCat
                showingCategoryMismatchAlert = true
            }
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
