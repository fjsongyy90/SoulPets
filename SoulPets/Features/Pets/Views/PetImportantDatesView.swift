import SwiftUI
import SwiftData

/// 宠物重要日期设置视图
struct PetImportantDatesView: View {
    @ObservedObject var viewModel: PetViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 生日选择
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("Birthday"))
                    .font(.headline)
                
                DatePicker("", selection: $viewModel.birthday, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }
            
            // 领养日选择
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("Adoption / Gotcha Day"))
                    .font(.headline)
                
                DatePicker("", selection: $viewModel.adoptionDay, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }
            
            // 体重单位偏好
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("Weight Unit"))
                    .font(.headline)
                
                Picker("", selection: $viewModel.weightUnitPreference) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // 可选健康信息
            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizedStringKey("Optional Health Information"))
                    .font(.headline)
                    .padding(.top)
                
                // 芯片ID
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("Microchip ID"))
                        .font(.subheadline)
                    
                    TextField("", text: $viewModel.microchipID)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // 保险单号
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("Insurance Policy No."))
                        .font(.subheadline)
                    
                    TextField("", text: $viewModel.insurancePolicyNo)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Pet.self, configurations: config)
    let viewModel = PetViewModel(modelContext: container.mainContext)
    return PetImportantDatesView(viewModel: viewModel)
} 