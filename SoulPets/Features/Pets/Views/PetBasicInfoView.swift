import SwiftUI
import SwiftData

/// 宠物基本信息表单视图
struct PetBasicInfoView: View {
    @ObservedObject var viewModel: PetViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Text(LocalizedStringKey("Tell us about your new friend"))
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 步骤进度指示器
            ProgressBar(progress: 0.5)
                .padding(.horizontal, 40)
            
            // 头像选择器
            ZStack {
                Circle()
                    .fill(Color(red: 0.97, green: 0.90, blue: 0.83).opacity(0.5))
                    .frame(width: 120, height: 120)
                
                if let petImage = viewModel.avatar {
                    Image(uiImage: petImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Image(viewModel.petType == .dog ? "dog" : "cat")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70)
                }
                
                // 加号按钮
                Circle()
                    .fill(Color.white)
                    .frame(width: 30, height: 30)
                    .shadow(radius: 2)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.69, green: 0.45, blue: 0.25))
                    )
                    .offset(x: 40, y: -40)
            }
            .onTapGesture {
                // 这里应该打开照片选择器，但目前我们保留CircleImagePicker的功能
            }
            
            // 名字输入
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("Name"))
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                TextField("", text: $viewModel.name)
                    .padding()
                    .background(Color(red: 0.95, green: 0.91, blue: 0.85))
                    .cornerRadius(20)
                    .onChange(of: viewModel.name) { _, _ in
                        viewModel.validateForm()
                    }
                
                if let error = viewModel.nameError {
                    Text(LocalizedStringKey(error))
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            
            // 品种/花色输入
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("Breed / Color"))
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("", text: $viewModel.breed)
                        .padding()
                    
                    Image(systemName: "circle")
                        .foregroundColor(Color(red: 0.69, green: 0.45, blue: 0.25))
                        .padding(.trailing)
                }
                .background(Color(red: 0.95, green: 0.91, blue: 0.85))
                .cornerRadius(20)
            }
            .padding(.horizontal)
            
            // 性别选择
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("Gender"))
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 10) {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        Button(action: {
                            viewModel.gender = gender
                        }) {
                            Text(LocalizedStringKey(gender.rawValue))
                                .fontWeight(viewModel.gender == gender ? .bold : .regular)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity)
                        }
                        .background(
                            Capsule()
                                .fill(viewModel.gender == gender ? 
                                      Color(red: 0.69, green: 0.45, blue: 0.25) : 
                                      Color(red: 0.95, green: 0.91, blue: 0.85))
                        )
                        .foregroundColor(viewModel.gender == gender ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal)
            
            // 绝育状态
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(LocalizedStringKey("Neutred Spray?"))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $viewModel.isNeutered)
                        .labelsHidden()
                        .tint(Color(red: 0.69, green: 0.45, blue: 0.25))
                }
                .padding()
                .background(Color(red: 0.95, green: 0.91, blue: 0.85))
                .cornerRadius(20)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // 下一步按钮
            Button(action: {
                // 这里什么都不做，由父视图处理
            }) {
                Text(LocalizedStringKey("Next"))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(viewModel.formIsValid ? 
                                  Color(red: 0.69, green: 0.45, blue: 0.25) : 
                                  Color.gray)
                    )
            }
            .padding(.horizontal, 40)
            .padding(.bottom)
            .disabled(!viewModel.formIsValid)
        }
        .background(Color(red: 0.99, green: 0.98, blue: 0.94))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Pet.self, configurations: config)
    let viewModel = PetViewModel(modelContext: container.mainContext)
    return PetBasicInfoView(viewModel: viewModel)
        .background(Color(red: 0.99, green: 0.98, blue: 0.94))
} 