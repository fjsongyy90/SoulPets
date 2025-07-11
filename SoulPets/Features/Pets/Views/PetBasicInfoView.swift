import SwiftUI
import SwiftData

/// 宠物基本信息表单视图
struct PetBasicInfoView: View {
    @ObservedObject var viewModel: PetViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 头像选择器
            HStack {
                Spacer()
                CircleImagePicker(image: $viewModel.avatar, size: 140)
                Spacer()
            }
            .padding(.bottom, 8)
            
            // 名字输入
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("Name"))
                    .font(.headline)
                
                TextField("", text: $viewModel.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: viewModel.name) { _, _ in
                        viewModel.validateForm()
                    }
                
                if let error = viewModel.nameError {
                    Text(LocalizedStringKey(error))
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // 品种/花色输入
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("Breed / Color"))
                    .font(.headline)
                
                TextField("", text: $viewModel.breed)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // 性别选择
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("Gender"))
                    .font(.headline)
                
                Picker("", selection: $viewModel.gender) {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        Text(LocalizedStringKey(gender.rawValue)).tag(gender)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // 绝育状态
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $viewModel.isNeutered) {
                    Text(LocalizedStringKey("Neutered / Spayed"))
                        .font(.headline)
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
    return PetBasicInfoView(viewModel: viewModel)
} 