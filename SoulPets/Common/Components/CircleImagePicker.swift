import SwiftUI
import PhotosUI

/// 圆形图片选择器组件
struct CircleImagePicker: View {
    @Binding var image: UIImage?
    @State private var photoItem: PhotosPickerItem?
    
    var size: CGFloat = 120
    var placeholderSystemName: String = "pawprint.circle.fill"
    
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
                            .foregroundColor(Color("AccentColor"))
                    }
                    
                    Circle()
                        .stroke(Color("AccentColor"), lineWidth: 2)
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
                    do {
                        if let data = try await newValue.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            await MainActor.run {
                                image = uiImage
                            }
                        }
                    } catch {
                        print("Error loading image: \(error.localizedDescription)")
                    }
                }
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