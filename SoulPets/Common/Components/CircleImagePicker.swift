import SwiftUI
import PhotosUI
import OSLog

/// 圆形图片选择器组件
struct CircleImagePicker: View {
    @Binding var image: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var showingAvatarEditor = false
    @State private var selectedImage: UIImage?
    
    private let logger = Logger(subsystem: "com.byte.driver.SoulPets", category: "CircleImagePicker")
    
    var size: CGFloat = 120
    var placeholderSystemName: String = "pawprint.circle.fill"
    var accentColor: Color = Color(red: 0.60, green: 0.35, blue: 0.15)
    
    var body: some View {
        VStack {
            PhotosPicker(selection: $photoItem, matching: .images) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: size, height: size)
                    
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: size - 4, height: size - 4)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: placeholderSystemName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: size / 2)
                            .foregroundColor(accentColor)
                    }
                    
                    Circle()
                        .stroke(accentColor, lineWidth: 2)
                        .frame(width: size, height: size)
                }
            }
            .buttonStyle(.plain)
            
            Text(LocalizedStringKey("Tap to select photo"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onChange(of: photoItem) { _, newValue in
            Task {
                if let newValue {
                    let startTime = Date()
                    logger.info("📷 开始加载选中的照片...")
                    
                    do {
                        if let data = try await newValue.loadTransferable(type: Data.self) {
                            let loadTime = Date().timeIntervalSince(startTime)
                            logger.info("📷 照片数据加载完成，耗时: \(String(format: "%.3f", loadTime))秒，大小: \(data.count / 1024)KB")
                            
                            if let uiImage = UIImage(data: data) {
                                let decodeTime = Date().timeIntervalSince(startTime)
                                logger.info("📷 照片解码完成，总耗时: \(String(format: "%.3f", decodeTime))秒")
                                
                                await MainActor.run {
                                    selectedImage = uiImage
                                    showingAvatarEditor = true
                                    logger.info("📷 准备打开头像编辑器")
                                }
                            }
                        }
                    } catch {
                        logger.error("❌ 加载照片失败: \(error.localizedDescription)")
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingAvatarEditor) {
            if let selectedImage = selectedImage {
                AvatarEditorView(
                    originalImage: selectedImage,
                    onSave: { croppedImage in
                        image = croppedImage
                        showingAvatarEditor = false
                        self.selectedImage = nil
                        photoItem = nil
                    },
                    onCancel: {
                        showingAvatarEditor = false
                        self.selectedImage = nil
                        photoItem = nil
                    }
                )
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
    @State var image: UIImage? = nil
        
        var body: some View {
            CircleImagePicker(image: $image)
        }
    }
    
    return PreviewWrapper()
} 