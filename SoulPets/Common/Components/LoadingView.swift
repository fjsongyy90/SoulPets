//
//  LoadingView.swift
//  SoulPets
//
//  Created by 宋友勇 on 2025/10/12.
//

import SwiftUI

/// 一个简单的加载视图，在后台准备数据时显示
struct LoadingView: View {
    
    // 统一样式，与您App风格保持一致
    private let backgroundColor = Color(red: 0.98, green: 0.97, blue: 0.94)
    private let labelColor = Color(red: 0.5, green: 0.5, blue: 0.5)
    private let accentColor = Color(red: 0.60, green: 0.35, blue: 0.15)
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                    .scaleEffect(1.5) // 让加载指示器更明显一些
                
                Text("Preparing your pet's space...")
                    .font(.subheadline) // 使用您项目中定义的字体
                    .foregroundColor(labelColor)
            }
        }
    }
}

#Preview {
    LoadingView()
}
