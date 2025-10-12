import SwiftUI
import SwiftData

/// 全屏照片查看器
struct FullScreenPhotoViewer: View {
    let photos: [PhotoItem]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    // 颜色定义
    private let backgroundColor = Color.black
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            TabView(selection: $selectedIndex) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, photoItem in
                    photoView(photoItem: photoItem)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            // 顶部关闭按钮
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
                Spacer()
            }
            
            // 底部页码指示器
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("\(selectedIndex + 1) / \(photos.count)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.5))
                        )
                    Spacer()
                }
                .padding(.bottom, 50)
            }
        }
        .statusBar(hidden: true)
    }
    
    @ViewBuilder
    private func photoView(photoItem: PhotoItem) -> some View {
        switch photoItem {
        case .existing(let recordPhoto):
            if let image = UIImage(data: recordPhoto.photoData) {
                photoImageView(image: image)
            }
        case .new(_, let uiImage):
            photoImageView(image: uiImage)
        }
    }
    
    @ViewBuilder
    private func photoImageView(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
    }
}

/// 照片项目类型
enum PhotoItem {
    case existing(RecordPhoto)
    case new(id: UUID, image: UIImage)
}

#Preview {
    FullScreenPhotoViewer(
        photos: [
            .new(id: UUID(), image: UIImage(systemName: "photo") ?? UIImage()),
            .new(id: UUID(), image: UIImage(systemName: "photo.fill") ?? UIImage())
        ],
        selectedIndex: .constant(0)
    )
}
