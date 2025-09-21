import SwiftUI
import SwiftData
import OSLog

/// 宠物重要日期设置视图
struct PetImportantDatesView: View {
    @ObservedObject var viewModel: PetViewModel
    @FocusState private var isWeightFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    
    // 日志
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "PetImportantDatesView")
    
    // 新增：用于处理保存和完成的回调
    var onSaveAndFinish: (() -> Void)?
    
    // 定义更高对比度的颜色
    private let textColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let labelColor = Color(red: 0.3, green: 0.3, blue: 0.3)
    private let accentColor = Color(red: 0.69, green: 0.45, blue: 0.25)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text(LocalizedStringKey("A few more details"))
                    .font(.appTitle2)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 20) // 标题向下移动
                
                // 生日选择
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("Birthday"))
                        .font(.appHeadline)
                        .foregroundColor(labelColor)
                    
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 20))
                            .foregroundColor(accentColor)
                            .padding(.leading)
                        
                        Spacer()
                        
                        DatePicker("", selection: $viewModel.birthday, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(.trailing)
                            .accentColor(accentColor)
                    }
                    .padding()
                    .background(Color(red: 0.95, green: 0.91, blue: 0.85))
                    .cornerRadius(20)
                }
                .padding(.horizontal)
                
                // 领养日选择
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("Adoption Day / Gotcha Day"))
                        .font(.appHeadline)
                        .foregroundColor(labelColor)
                    
                    HStack {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 20))
                            .foregroundColor(accentColor)
                            .padding(.leading)
                        
                        Spacer()
                        
                        DatePicker("", selection: $viewModel.adoptionDay, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(.trailing)
                            .accentColor(accentColor)
                    }
                    .padding()
                    .background(Color(red: 0.95, green: 0.91, blue: 0.85))
                    .cornerRadius(20)
                }
                .padding(.horizontal)
                
                // 初始体重输入
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("Initial Weight"))
                        .font(.appHeadline)
                        .foregroundColor(labelColor)
                    
                    HStack {
                        Image(systemName: "scalemass")
                            .font(.system(size: 20))
                            .foregroundColor(accentColor)
                            .padding(.leading)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            TextField(LocalizedStringKey("Enter weight"), text: $viewModel.initialWeight)
                                .keyboardType(.decimalPad)
                                .foregroundColor(textColor)
                                .focused($isWeightFocused)
                                .multilineTextAlignment(.trailing)
                                .simultaneousGesture(
                                    TapGesture()
                                        .onEnded {
                                            logger.info("⚖️ PetImportantDates Weight TextField simultaneousGesture 触发")
                                        }
                                )
                                .onChange(of: viewModel.initialWeight) { oldValue, newValue in
                                    // 确保只输入数字和小数点
                                    let filtered = newValue.filter { "0123456789.".contains($0) }
                                    if filtered != newValue {
                                        viewModel.initialWeight = filtered
                                    }
                                }
                            
                            Text(viewModel.weightUnitPreference.rawValue)
                                .foregroundColor(labelColor)
                        }
                        .padding(.trailing)
                    }
                    .padding()
                    .background(Color(red: 0.95, green: 0.91, blue: 0.85))
                    .cornerRadius(20)
                }
                .padding(.horizontal)
                
                // 体重单位偏好
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("Weight Unit"))
                        .font(.appHeadline)
                        .foregroundColor(labelColor)
                    
                    HStack(spacing: 15) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Button(action: {
                                viewModel.weightUnitPreference = unit
                            }) {
                                Text(unit.rawValue)
                                    .fontWeight(viewModel.weightUnitPreference == unit ? .bold : .regular)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 30)
                                    .frame(maxWidth: .infinity)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(viewModel.weightUnitPreference == unit ? 
                                          accentColor : 
                                          Color(red: 0.95, green: 0.91, blue: 0.85))
                            )
                            .foregroundColor(viewModel.weightUnitPreference == unit ? .white : textColor)
                        }
                    }
                }
                .padding(.horizontal)
                
                // 移除了性格描述和故事输入字段
                
                Spacer(minLength: 20) // 大幅减少底部空间
                
                // Finish按钮
                Button(action: {
                    onSaveAndFinish?()
                }) {
                    Text("Finish & Welcome \(viewModel.name)!")
                        .font(.appHeadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(accentColor)
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 80) // 大幅上移
            }
            .padding(.bottom, keyboardHeight)
        }
        .background(Color(red: 0.99, green: 0.98, blue: 0.94))
        .onTapGesture {
            // 点击空白处收起键盘
            isWeightFocused = false
        }
        .toolbar {
            // 🔧 键盘工具栏完成按钮（仅在有焦点时显示）
            if isWeightFocused {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(String(localized: "Done")) {
                        logger.info("🔧 PetImportantDates键盘工具栏完成按钮被点击")
                        logger.info("🔧 当前焦点状态 - Weight: \(isWeightFocused)")
                        
                        // 关闭键盘
                        isWeightFocused = false
                        
                        // 备用方法：使用 UIApplication 方式关闭键盘
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                        logger.info("🔧 键盘关闭操作已执行")
                    }
                    .foregroundColor(accentColor)
                    .onAppear {
                        logger.info("🔧 PetImportantDates Done按钮已创建")
                    }
                }
            }
        }
        .onChange(of: isWeightFocused) { oldValue, newValue in
            logger.info("⚖️ PetImportantDates Weight焦点状态变化: \(oldValue) -> \(newValue)")
        }
        .onAppear {
            // 监听键盘通知
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                keyboardHeight = 0
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Pet.self, configurations: config)
    let viewModel = PetViewModel(modelContext: container.mainContext)
    return PetImportantDatesView(viewModel: viewModel, onSaveAndFinish: {
        print("Save and finish callback")
    })
        .background(Color(red: 0.99, green: 0.98, blue: 0.94))
}