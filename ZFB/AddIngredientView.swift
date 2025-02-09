import SwiftUI

struct AddIngredientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var category = "其他"
    @State private var quantity = ""
    @State private var unit = "个"
    @State private var purchaseDate = Date()
    @State private var expiryDate = Date()
    @State private var notes = ""
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    
    let categories = ["蔬菜", "水果", "肉类", "海鲜", "调味料", "其他"]
    let commonUnits = ["个", "颗", "把", "包", "克", "千克", "升", "毫升"]
    
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
                    
                    Picker("分类", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    HStack {
                        TextField("数量", text: $quantity)
                            .keyboardType(.decimalPad)
                        Picker("单位", selection: $unit) {
                            ForEach(commonUnits, id: \.self) { unit in
                                Text(unit).tag(unit)
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
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $inputImage)
        }
    }
    
    private func saveIngredient() {
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
