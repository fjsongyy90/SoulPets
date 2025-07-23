import SwiftUI
import SwiftData

/// 宠物重要日期设置视图
struct PetImportantDatesView: View {
    @ObservedObject var viewModel: PetViewModel
    @FocusState private var isWeightFocused: Bool
    
    // 定义更高对比度的颜色
    private let textColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let labelColor = Color(red: 0.3, green: 0.3, blue: 0.3)
    private let accentColor = Color(red: 0.69, green: 0.45, blue: 0.25)
    
    var body: some View {
        VStack(spacing: 30) {
            Text(LocalizedStringKey("A few more details"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 步骤进度指示器
            ProgressBar(progress: 0.9)
                .padding(.horizontal, 40)
            
            // 生日选择
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("Birthday"))
                    .font(.headline)
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
                    .font(.headline)
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
                    .font(.headline)
                    .foregroundColor(labelColor)
                
                HStack {
                    Image(systemName: "scalemass")
                        .font(.system(size: 20))
                        .foregroundColor(accentColor)
                        .padding(.leading)
                    
                    TextField(LocalizedStringKey("Enter weight"), text: $viewModel.initialWeight)
                        .keyboardType(.decimalPad)
                        .padding(.horizontal)
                        .foregroundColor(textColor)
                        .focused($isWeightFocused)
                    
                    Text(viewModel.weightUnitPreference.rawValue)
                        .foregroundColor(labelColor)
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
                    .font(.headline)
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
            
            Spacer(minLength: 100) // 增加底部空间，防止键盘遮挡
        }
        .background(Color(red: 0.99, green: 0.98, blue: 0.94))
        .onTapGesture {
            // 点击空白处收起键盘
            isWeightFocused = false
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    isWeightFocused = false
                }
                .foregroundColor(accentColor)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // 防止键盘顶起视图
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Pet.self, configurations: config)
    let viewModel = PetViewModel(modelContext: container.mainContext)
    return PetImportantDatesView(viewModel: viewModel)
        .background(Color(red: 0.99, green: 0.98, blue: 0.94))
} 