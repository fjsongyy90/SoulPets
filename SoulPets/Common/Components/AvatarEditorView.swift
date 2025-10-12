import SwiftUI

/// 头像编辑视图 - 支持图片移动、缩放和圆形裁剪
struct AvatarEditorView: View {
    let originalImage: UIImage
    let onSave: (UIImage) -> Void
    let onCancel: () -> Void
    
    // 图片变换状态
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    // 优化后的图片
    @State private var optimizedImage: UIImage?
    
    // 裁剪圆的尺寸
    private let cropCircleSize: CGFloat = 280
    
    // 颜色定义
    private let backgroundColor = Color(red: 0.15, green: 0.15, blue: 0.15)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 深色背景
                backgroundColor.ignoresSafeArea()
                
                // 优先显示优化后的图片，如果还没优化完就显示原始图片
                let displayImage = optimizedImage ?? originalImage
                
                VStack(spacing: 0) {
                    // 说明文字
                    instructionText
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                    
                    // 编辑区域
                    GeometryReader { geometry in
                        ZStack {
                            // 底层：可移动和缩放的图片
                            Image(uiImage: displayImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width, height: geometry.size.width)
                                .scaleEffect(scale)
                                .offset(offset)
                                .clipped()
                            
                            // 中层：带圆形"洞"的黑色遮罩（不拦截触摸）
                            Color.black.opacity(0.7)
                                .frame(width: geometry.size.width, height: geometry.size.width)
                                .mask(
                                    // 创建一个反向遮罩：整个区域是白色，中间圆形是透明
                                    ZStack {
                                        Rectangle()
                                            .fill(Color.white)
                                        
                                        Circle()
                                            .frame(width: cropCircleSize, height: cropCircleSize)
                                            .blendMode(.destinationOut)
                                    }
                                    .compositingGroup()
                                )
                                .allowsHitTesting(false)
                            
                            // 顶层：圆形裁剪框边框（不拦截触摸）
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: cropCircleSize, height: cropCircleSize)
                                .allowsHitTesting(false)
                        }
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .gesture(dragGesture)
                        .gesture(magnificationGesture)
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .padding()
                    
                    // 操作提示和重置按钮
                    controlsSection
                        .padding(.top, 30)
                        .padding(.bottom, 40)
                }
            }
            .navigationTitle(String(localized: "Edit Avatar"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                optimizeImage()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        onCancel()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Done")) {
                        cropAndSave()
                    }
                    .foregroundColor(accentColor)
                    .fontWeight(.semibold)
                }
            }
            .toolbarBackground(backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    // MARK: - 子视图
    
    private var instructionText: some View {
        VStack(spacing: 8) {
            Text(String(localized: "avatar_editor.instruction"))
                .font(.appSubheadline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            
            Text(String(localized: "avatar_editor.hint"))
                .font(.appCaption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
    
    private var controlsSection: some View {
        VStack(spacing: 20) {
            // 缩放指示器
            HStack(spacing: 12) {
                Image(systemName: "minus.magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 16))
                
                // 缩放比例显示
                Text("\(Int(scale * 100))%")
                    .font(.appCallout)
                    .foregroundColor(.white)
                    .frame(width: 60)
                
                Image(systemName: "plus.magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 16))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.15))
            )
            
            // 重置按钮
            Button(action: resetTransform) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16))
                    Text(String(localized: "Reset"))
                        .font(.appSubheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                )
            }
        }
    }
    
    // MARK: - 手势
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                scale *= delta
                lastScale = value
                
                // 限制缩放范围 0.5x - 5x
                scale = max(0.5, min(scale, 5.0))
            }
            .onEnded { _ in
                lastScale = 1.0
            }
    }
    
    // MARK: - 操作方法
    
    /// 优化图片尺寸以提升性能（在后台静默执行）
    private func optimizeImage() {
        Task {
            // 在后台线程处理
            let originalImg = originalImage
            let optimized = await Task.detached {
                // 目标尺寸：屏幕宽度的2倍（支持高清屏）
                let targetSize = await UIScreen.main.bounds.width * 2
                return Self.resizeImage(originalImg, targetSize: targetSize)
            }.value
            
            // 回到主线程更新UI（无缝切换到优化后的图片）
            await MainActor.run {
                optimizedImage = optimized
            }
        }
    }
    
    /// 调整图片大小（静态方法，避免主线程隔离问题）
    private static func resizeImage(_ image: UIImage, targetSize: CGFloat) -> UIImage {
        let size = image.size
        let maxDimension = max(size.width, size.height)
        
        // 如果图片已经够小，直接返回
        if maxDimension <= targetSize {
            return image
        }
        
        // 计算新尺寸（保持宽高比）
        let scale = targetSize / maxDimension
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        // 使用高质量渲染
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }
    
    /// 重置变换
    private func resetTransform() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            scale = 1.0
            offset = .zero
        }
        lastScale = 1.0
        lastOffset = .zero
    }
    
    /// 裁剪并保存
    private func cropAndSave() {
        guard let croppedImage = cropCircularImage() else {
            return
        }
        onSave(croppedImage)
    }
    
    /// 裁剪圆形图片
    private func cropCircularImage() -> UIImage? {
        // 计算屏幕尺寸
        let screenSize = UIScreen.main.bounds.size
        let imageViewSize = min(screenSize.width, screenSize.height)
        
        // 计算图片在视图中的实际尺寸（考虑 scaledToFill）
        let imageSize = originalImage.size
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect: CGFloat = 1.0 // 正方形视图
        
        var drawSize: CGSize
        if imageAspect > viewAspect {
            // 图片更宽，以高度为准
            drawSize = CGSize(width: imageViewSize * imageAspect, height: imageViewSize)
        } else {
            // 图片更高，以宽度为准
            drawSize = CGSize(width: imageViewSize, height: imageViewSize / imageAspect)
        }
        
        // 应用缩放
        drawSize = CGSize(width: drawSize.width * scale, height: drawSize.height * scale)
        
        // 计算绘制偏移量（考虑居中 + 用户偏移）
        let centerX = imageViewSize / 2
        let centerY = imageViewSize / 2
        let drawX = centerX - drawSize.width / 2 + offset.width
        let drawY = centerY - drawSize.height / 2 + offset.height
        
        // 计算裁剪圆在图片坐标系中的位置
        let cropRadius = cropCircleSize / 2
        let cropCenterX = centerX
        let cropCenterY = centerY
        
        // 转换到图片坐标系
        let scale = originalImage.scale
        
        // 创建图形上下文
        UIGraphicsBeginImageContextWithOptions(CGSize(width: cropCircleSize, height: cropCircleSize), false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        // 裁剪为圆形
        context.addEllipse(in: CGRect(x: 0, y: 0, width: cropCircleSize, height: cropCircleSize))
        context.clip()
        
        // 计算要绘制的图片区域
        let drawRect = CGRect(
            x: drawX - (cropCenterX - cropRadius),
            y: drawY - (cropCenterY - cropRadius),
            width: drawSize.width,
            height: drawSize.height
        )
        
        // 绘制图片
        originalImage.draw(in: drawRect)
        
        // 获取结果
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return croppedImage
    }
}

// MARK: - 预览
#Preview {
    AvatarEditorView(
        originalImage: UIImage(systemName: "photo")!,
        onSave: { _ in },
        onCancel: {}
    )
}
