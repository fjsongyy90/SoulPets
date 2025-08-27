import SwiftUI
import SwiftData
import PhotosUI

/// 宠物基本信息表单视图
struct PetBasicInfoView: View {
    @ObservedObject var viewModel: PetViewModel
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var focusedField: Field?
    @State private var keyboardHeight: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    
    // 定义更高对比度的颜色
    private let textColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let labelColor = Color(red: 0.3, green: 0.3, blue: 0.3)
    private let accentColor = Color(red: 0.69, green: 0.45, blue: 0.25)
    
    enum Field {
        case name, breed
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 30) {
                        Text(LocalizedStringKey("Tell us about your new friend"))
                            .font(.appTitle2)
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top, 20) // 标题向下移动
                        
                        // 头像选择器
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.97, green: 0.90, blue: 0.83).opacity(0.5))
                                .frame(width: 120, height: 120)
                            
                            if let petImage = viewModel.avatar {
                                Image(uiImage: petImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else {
                                Image(viewModel.petType == .dog ? "pet_dog" : "pet_cat")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .foregroundColor(accentColor)
                            }
                            
                            // 相机按钮
                            Circle()
                                .fill(Color.white)
                                .frame(width: 30, height: 30)
                                .shadow(radius: 2)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(accentColor)
                                )
                                .offset(x: 40, y: -40)
                        }
                        .overlay(
                            PhotosPicker(selection: $photoItem, matching: .images) {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: 120, height: 120)
                            }
                        )
                        .onChange(of: photoItem) { _, newValue in
                            Task {
                                if let data = try? await newValue?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    await MainActor.run {
                                        viewModel.avatar = image
                                    }
                                }
                            }
                        }
                        
                        // 名字输入
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStringKey("Name"))
                                .font(.appHeadline)
                                .foregroundColor(labelColor)
                            
                            TextField("", text: $viewModel.name)
                                .focused($focusedField, equals: .name)
                                .padding()
                                .foregroundColor(textColor)
                                .background(Color(red: 0.95, green: 0.91, blue: 0.85))
                                .cornerRadius(20)
                                .id("nameField")
                                .onChange(of: viewModel.name) { _, _ in
                                    // 清除错误状态，只在用户输入时清除，不立即验证
                                    if !viewModel.name.isEmpty {
                                        viewModel.nameError = nil
                                    }
                                }
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .breed
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
                                .font(.appHeadline)
                                .foregroundColor(labelColor)
                            
                            TextField("e.g. Golden Retriever, Orange Tabby", text: $viewModel.breed)
                                .focused($focusedField, equals: .breed)
                                .padding()
                                .foregroundColor(textColor)
                                .background(Color(red: 0.95, green: 0.91, blue: 0.85))
                                .cornerRadius(20)
                                .id("breedField")
                                .submitLabel(.done)
                                .onSubmit {
                                    focusedField = nil
                                }
                        }
                        .padding(.horizontal)
                        
                        // 性别选择
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStringKey("Gender"))
                                .font(.appHeadline)
                                .foregroundColor(labelColor)
                            
                            HStack(spacing: 10) {
                                ForEach(Gender.allCases, id: \.self) { gender in
                                    Button(action: {
                                        viewModel.gender = gender
                                        // 点击性别选项时收起键盘
                                        focusedField = nil
                                    }) {
                                Text(LocalizedStringKey(gender.rawValue))
                                    .font(viewModel.gender == gender ? .appHeadline : .appBody)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .frame(maxWidth: .infinity)
                                    }
                                    .background(
                                        Capsule()
                                            .fill(viewModel.gender == gender ? 
                                                  accentColor : 
                                                  Color(red: 0.95, green: 0.91, blue: 0.85))
                                    )
                                    .foregroundColor(viewModel.gender == gender ? .white : textColor)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // 绝育状态
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(LocalizedStringKey("Neutered / Spayed?"))
                                    .font(.appHeadline)
                                    .foregroundColor(labelColor)
                                
                                Spacer()
                                
                                Toggle("", isOn: $viewModel.isNeutered)
                                    .labelsHidden()
                                    .tint(accentColor)
                            }
                            .padding()
                            .background(Color(red: 0.95, green: 0.91, blue: 0.85))
                            .cornerRadius(20)
                        }
                        .padding(.horizontal)
                        
                        Spacer() // 使用弹性空间
                        
                        // 隐私承诺文案
                        Text("Your pet's data never leaves your device.")
                            .font(.appLightCaption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.bottom, 8) // 缩小与按钮的间距
                        
                        // Next按钮 - 移除置灰状态
                        Button(action: {
                            viewModel.moveToNextStep()
                        }) {
                            Text(LocalizedStringKey("Next"))
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
                        .padding(.bottom, 120) // 进一步上移
                    }
                    .padding(.bottom, keyboardHeight > 0 ? keyboardHeight : 0)
                }
                .onChange(of: focusedField) { _, newValue in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if newValue == .name {
                            scrollProxy.scrollTo("nameField", anchor: .center)
                        } else if newValue == .breed {
                            scrollProxy.scrollTo("breedField", anchor: .center)
                        }
                    }
                }
                .background(Color(red: 0.99, green: 0.98, blue: 0.94))
                .onTapGesture {
                    // 点击空白处收起键盘
                    focusedField = nil
                }
            }
            
            // 自定义键盘工具栏
            if keyboardHeight > 0 {
                HStack {
                    Spacer()
                    Button {
                        focusedField = nil
                    } label: {
                        Text("完成")
                            .fontWeight(.semibold)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                Capsule()
                                    .fill(accentColor)
                            )
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 8)
                }
                .frame(height: 44)
                .background(Color(UIColor.systemBackground).opacity(0.9))
                .offset(y: -(keyboardHeight.isFinite ? keyboardHeight : 0) + 44) // 确保offset值是有效的
            }
        }
        .onAppear {
            // 监听键盘通知
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    let height = keyboardFrame.height
                    keyboardHeight = height.isFinite && height >= 0 ? height : 0
                }
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                keyboardHeight = 0
            }
        }
        // 移除系统默认的工具栏
        // .toolbar(.hidden, for: .keyboard) // 不兼容的API，已移除
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Pet.self, configurations: config)
    let viewModel = PetViewModel(modelContext: container.mainContext)
    return PetBasicInfoView(viewModel: viewModel)
        .background(Color(red: 0.99, green: 0.98, blue: 0.94))
} 