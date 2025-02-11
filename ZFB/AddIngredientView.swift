import SwiftUI
import CoreData

struct AddIngredientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var quantity = "1"  // 默认值为1
    @State private var unit = ""
    @State private var category = "蔬菜"  // 默认类别
    @State private var purchaseDate = Date()
    @State private var expiryDate = Date()
    @State private var notes = ""
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var showingDuplicateAlert = false
    
    private let categories = ["蔬菜", "水果", "肉类", "海鲜", "调味料", "其他"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("名称", text: $name)
                        .onChange(of: name) { newValue in
                            // 当名称改变时，尝试自动设置分类
                            if let suggestedCategory = IngredientCategoryManager.shared.getCategory(for: newValue) {
                                category = suggestedCategory
                            }
                        }
                    
                    // 数量编辑器
                    HStack {
                        Text("数量")
                        Spacer()
                        
                        if IngredientUnitManager.shared.supportsQuickAdjust(unit) {
                            // 快捷加减按钮
                            Button(action: {
                                if let current = Double(quantity), current > 0 {
                                    quantity = String(current - 1)
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                            .disabled(Double(quantity) ?? 0 <= 1)
                            
                            Text(quantity)
                                .frame(minWidth: 40)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                if let current = Double(quantity) {
                                    quantity = String(current + 1)
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        } else {
                            // 数字输入框
                            TextField("", text: $quantity)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 80)
                        }
                        
                        // 单位选择器
                        Picker("单位", selection: $unit) {
                            ForEach(IngredientUnitManager.shared.getUnitsForCategory(category), id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .frame(width: 80)
                    }
                    
                    // 类别选择
                    Picker("类别", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .onChange(of: category) { newCategory in
                        // 当类别改变时，设置该类别的默认单位
                        unit = IngredientUnitManager.shared.getDefaultUnitForCategory(newCategory)
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
                            Text("选择图片")
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
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Button("保存") {
                    saveIngredient()
                }
                .disabled(name.isEmpty || category.isEmpty || quantity.isEmpty || unit.isEmpty)
            )
            .alert(isPresented: $showingDuplicateAlert) {
                Alert(title: Text("食材重复"), message: Text("已经存在相同名称的食材"), dismissButton: .default(Text("确定")))
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $inputImage)
        }
    }
    
    private func saveIngredient() {
        // 检查是否存在重复的食材名称
        let fetchRequest: NSFetchRequest<Ingredient> = Ingredient.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name ==[c] %@", name)
        
        do {
            let matchingIngredients = try viewContext.fetch(fetchRequest)
            if !matchingIngredients.isEmpty {
                showingDuplicateAlert = true
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
                isPresented = false
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
