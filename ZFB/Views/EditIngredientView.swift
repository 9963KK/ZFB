import SwiftUI
import CoreData

struct EditIngredientView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    let ingredient: Ingredient
    @State private var name: String
    @State private var category: String
    @State private var quantity: String
    @State private var unit: String
    @State private var purchaseDate: Date
    @State private var expiryDate: Date
    @State private var notes: String
    @State private var inputImage: UIImage?
    @State private var hasChanges = false
    @State private var showingImagePicker = false
    @State private var showingDiscardAlert = false
    @State private var showingCategoryMismatchAlert = false
    @State private var showingEmptyAlert = false
    @State private var showingDuplicateAlert = false
    @State private var suggestedCategory: String?
    @State private var showingDeleteAlert = false
    @State private var showingCategoryPicker = false
    
    // 保存原始值用于撤销
    private let originalName: String
    private let originalCategory: String
    private let originalQuantity: String
    private let originalUnit: String
    private let originalPurchaseDate: Date
    private let originalExpiryDate: Date
    private let originalNotes: String
    
    let categories = ["蔬菜", "水果", "肉类", "海鲜", "调味料", "其他"]
    
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
    
    init(ingredient: Ingredient) {
        self.ingredient = ingredient
        
        // 初始化当前值
        _name = State(initialValue: ingredient.name ?? "")
        _category = State(initialValue: ingredient.category ?? "")
        _quantity = State(initialValue: UnitFormatter.format(quantity: ingredient.quantity, unit: ingredient.unit ?? "个"))
        _unit = State(initialValue: ingredient.unit ?? "个")
        _purchaseDate = State(initialValue: ingredient.purchaseDate ?? Date())
        _expiryDate = State(initialValue: ingredient.expiryDate ?? Date())
        _notes = State(initialValue: ingredient.notes ?? "")
        
        // 保存原始值
        originalName = ingredient.name ?? ""
        originalCategory = ingredient.category ?? ""
        originalQuantity = UnitFormatter.format(quantity: ingredient.quantity, unit: ingredient.unit ?? "个")
        originalUnit = ingredient.unit ?? "个"
        originalPurchaseDate = ingredient.purchaseDate ?? Date()
        originalExpiryDate = ingredient.expiryDate ?? Date()
        originalNotes = ingredient.notes ?? ""
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    HStack(spacing: 12) {
                        TextField("名称", text: $name)
                            .onChange(of: name) { newName in
                                checkForChanges()
                                checkCategoryMatch(for: newName)
                            }
                        
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
                            .onChange(of: category) { _ in checkForChanges() }
                        }
                        .frame(width: 150)
                    }
                    
                    HStack {
                        if isIntegerUnit {
                            Button(action: {
                                let newValue = max(0, currentQuantity - 1)
                                formatQuantity(newValue)
                                checkForChanges()
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.blue)
                                    .imageScale(.large)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        
                        TextField("数量", text: $quantity)
                            .keyboardType(.decimalPad)
                            .onChange(of: quantity) { newValue in
                                checkForChanges()
                            }
                            .frame(minWidth: 50)
                            .multilineTextAlignment(.center)
                        
                        if isIntegerUnit {
                            Button(action: {
                                let newValue = currentQuantity + 1
                                formatQuantity(newValue)
                                checkForChanges()
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
                            checkForChanges()
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
                        .onChange(of: notes) { _ in checkForChanges() }
                }
                
                Section(header: Text("图片")) {
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            Text("更换图片")
                            Spacer()
                            if inputImage != nil || ingredient.imageData != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                if hasChanges {
                    Section {
                        Button(action: revertChanges) {
                            HStack {
                                Spacer()
                                Text("撤销所有更改")
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("删除食材")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("编辑食材")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        if hasChanges {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty || category.isEmpty || quantity.isEmpty || unit.isEmpty)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage)
            }
            .alert("确认删除", isPresented: $showingDeleteAlert) {
                Button("删除", role: .destructive) {
                    deleteIngredient()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("确定要删除这个食材吗？此操作无法撤销。")
            }
            .alert("放弃更改", isPresented: $showingDiscardAlert) {
                Button("放弃", role: .destructive) {
                    dismiss()
                }
                Button("继续编辑", role: .cancel) {}
            } message: {
                Text("您有未保存的更改，确定要放弃吗？")
            }
            .alert("食材类别不匹配", isPresented: $showingCategoryMismatchAlert) {
                Button("更新为\(suggestedCategory ?? "")") {
                    if let newCategory = suggestedCategory {
                        category = newCategory
                    }
                }
                Button("保持现有类别", role: .cancel) {}
            } message: {
                Text("检测到\"\(name)\"可能属于\"\(suggestedCategory ?? "")\"类别，是否要更新？")
            }
            .alert("食材已用完", isPresented: $showingEmptyAlert) {
                Button("确定") {
                    dismiss()
                }
            } message: {
                Text("\"\(name)\"已用完，将被标记为已用完状态")
            }
            .alert("食材重复", isPresented: $showingDuplicateAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text("已经存在相同名称的食材")
            }
        }
    }
    
    private func checkForChanges() {
        hasChanges = name != originalName ||
            category != originalCategory ||
            quantity != originalQuantity ||
            unit != originalUnit ||
            !Calendar.current.isDate(purchaseDate, inSameDayAs: originalPurchaseDate) ||
            !Calendar.current.isDate(expiryDate, inSameDayAs: originalExpiryDate) ||
            notes != originalNotes ||
            inputImage != nil
    }
    
    private func revertChanges() {
        name = originalName
        category = originalCategory
        quantity = originalQuantity
        unit = originalUnit
        purchaseDate = originalPurchaseDate
        expiryDate = originalExpiryDate
        notes = originalNotes
        inputImage = nil
        hasChanges = false
    }
    
    private func saveChanges() {
        // 检查是否存在重复的食材名称（排除当前编辑的食材）
        let fetchRequest: NSFetchRequest<Ingredient> = Ingredient.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name ==[c] %@ AND self != %@", name, ingredient)
        
        do {
            let matchingIngredients = try ingredient.managedObjectContext?.fetch(fetchRequest) ?? []
            if !matchingIngredients.isEmpty {
                showingDuplicateAlert = true
                return
            }
            
            let context = ingredient.managedObjectContext
            let quantityValue = Double(quantity) ?? 0
            
            // 更新食材信息
            ingredient.name = name
            ingredient.category = category
            
            // 使用动画更新数量
            withAnimation(.easeInOut(duration: 0.5)) {
                ingredient.quantity = quantityValue
            }
            
            ingredient.unit = unit
            ingredient.purchaseDate = purchaseDate
            ingredient.expiryDate = expiryDate
            ingredient.notes = notes
            
            if let imageData = inputImage?.jpegData(compressionQuality: 0.8) {
                ingredient.imageData = imageData
            }
            
            // 保存更改
            do {
                try context?.save()
                // 如果数量为0，在保存成功后显示提示
                if quantityValue == 0 {
                    showingEmptyAlert = true
                } else {
                    dismiss()
                }
            } catch {
                print("保存失败: \(error)")
            }
        } catch {
            print("获取重复食材失败: \(error)")
        }
    }
    
    private func deleteIngredient() {
        viewContext.delete(ingredient)
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("删除失败: \(error)")
        }
    }
    
    private func checkCategoryMatch(for ingredientName: String) {
        // 如果食材名称为空，不进行检查
        guard !ingredientName.isEmpty else { return }
        
        // 获取建议的类别
        let suggestedCat = IngredientCategoryManager.shared.getCategory(for: ingredientName)
        if suggestedCat != category && suggestedCat != "其他" {
            suggestedCategory = suggestedCat
            showingCategoryMismatchAlert = true
        }
    }
}
