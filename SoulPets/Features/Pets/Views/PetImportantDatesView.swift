import SwiftUI
import SwiftData

/// 宠物重要日期设置视图
struct PetImportantDatesView: View {
    @ObservedObject var viewModel: PetViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Text(LocalizedStringKey("A few more details"))
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 步骤进度指示器
            ProgressBar(progress: 0.9)
                .padding(.horizontal, 40)
            
            // 生日选择
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("Birthday"))
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.69, green: 0.45, blue: 0.25))
                        .padding(.leading)
                    
                    Spacer()
                    
                    DatePicker("", selection: $viewModel.birthday, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(.trailing)
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
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.brown)
                        .padding(.leading)
                    
                    Spacer()
                    
                    DatePicker("", selection: $viewModel.adoptionDay, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(.trailing)
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
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "scalemass")
                        .font(.system(size: 20))
                        .foregroundColor(.brown)
                        .padding(.leading)
                    
                    TextField(LocalizedStringKey("Enter weight"), text: $viewModel.initialWeight)
                        .keyboardType(.decimalPad)
                        .padding(.horizontal)
                    
                    Text(viewModel.weightUnitPreference.rawValue)
                        .foregroundColor(.secondary)
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
                    .foregroundColor(.secondary)
                
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
                                      Color(red: 0.69, green: 0.45, blue: 0.25) : 
                                      Color(red: 0.95, green: 0.91, blue: 0.85))
                        )
                        .foregroundColor(viewModel.weightUnitPreference == unit ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(red: 0.99, green: 0.98, blue: 0.94))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Pet.self, configurations: config)
    let viewModel = PetViewModel(modelContext: container.mainContext)
    return PetImportantDatesView(viewModel: viewModel)
        .background(Color(red: 0.99, green: 0.98, blue: 0.94))
} 