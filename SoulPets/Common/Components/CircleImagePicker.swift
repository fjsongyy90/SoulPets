import SwiftUI
import PhotosUI
import OSLog

/// 圆形图片选择器组件
struct CircleImagePicker: View {
    @Binding var image: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var editableImage: EditableImage?
    
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
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    
                    // ✅ 第2步：加载成功后，直接设置我们的新状态
                    await MainActor.run {
                        self.editableImage = EditableImage(image: uiImage)
                    }
                }
            }
        }
        // ✅ 第3步：将 fullScreenCover 绑定到新的 item 状态
            .fullScreenCover(item: $editableImage) { item in
                AvatarEditorView(
                    originalImage: item.image,
                    onSave: { croppedImage in
                        image = croppedImage
                        editableImage = nil // 关闭 cover
                        photoItem = nil
                    },
                    onCancel: {
                        editableImage = nil // 关闭 cover
                        photoItem = nil
                    }
                )
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
