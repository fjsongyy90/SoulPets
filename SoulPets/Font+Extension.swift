//
//  Font+Extension.swift
//  SoulPets
//
//  Created by 宋友勇 on 2025/8/19.
//

import SwiftUI

extension Font {
    // MARK: - 超大标题类字体 (ExtraBold)
    /// 超大标题 - 用于特别重要的标题
    static let appExtraLargeTitle = Font.custom("Nunito-ExtraBold", size: 40)
    /// 特大标题 - 用于页面主标题
    static let appLargeTitle = Font.custom("Nunito-ExtraBold", size: 34)
    
    // MARK: - 标题类字体 (Bold)
    /// 标题1 - 用于重要标题
    static let appTitle = Font.custom("Nunito-Bold", size: 28)
    /// 标题2 - 用于次级标题
    static let appTitle2 = Font.custom("Nunito-Bold", size: 22)
    /// 标题3 - 用于小标题
    static let appTitle3 = Font.custom("Nunito-Bold", size: 20)
    /// 标题行 - 用于按钮、导航栏标题
    static let appHeadline = Font.custom("Nunito-Bold", size: 17)
    
    // MARK: - 次级标题类字体 (SemiBold)
    /// 次级大标题
    static let appSubheadline = Font.custom("Nunito-SemiBold", size: 15)
    /// 标注 - 用于需要突出的标签、状态
    static let appCallout = Font.custom("Nunito-SemiBold", size: 16)
    /// 脚注 - 用于需要突出的小字
    static let appFootnote = Font.custom("Nunito-SemiBold", size: 13)
    
    // MARK: - 正文类字体 (Regular)
    /// 正文 - 用于所有常规文本
    static let appBody = Font.custom("Nunito-Regular", size: 17)
    /// 说明文字 - 用于描述、提示文本
    static let appCaption = Font.custom("Nunito-Regular", size: 12)
    /// 小说明文字 - 用于最小的说明文本
    static let appCaption2 = Font.custom("Nunito-Regular", size: 11)
    
    // MARK: - 轻量字体 (Light)
    /// 大面积辅助文字
    static let appLightBody = Font.custom("Nunito-Light", size: 17)
    /// 背景文字、水印文字
    static let appLightCaption = Font.custom("Nunito-Light", size: 12)
    /// 极小的背景文字
    static let appLightCaption2 = Font.custom("Nunito-Light", size: 10)
    
    // MARK: - 斜体字体 (Italic) - 用于引用、说明、特殊标注
    /// 引用正文
    static let appItalicBody = Font.custom("Nunito-Italic", size: 17)
    /// 引用说明
    static let appItalicCaption = Font.custom("Nunito-Italic", size: 12)
    /// 特殊标注
    static let appItalicFootnote = Font.custom("Nunito-Italic", size: 13)
    
    // MARK: - 自定义尺寸字体
    /// 自定义Light字体
    static func appLight(size: CGFloat) -> Font {
        return Font.custom("Nunito-Light", size: size)
    }
    
    /// 自定义Regular字体
    static func appRegular(size: CGFloat) -> Font {
        return Font.custom("Nunito-Regular", size: size)
    }
    
    /// 自定义SemiBold字体
    static func appSemiBold(size: CGFloat) -> Font {
        return Font.custom("Nunito-SemiBold", size: size)
    }
    
    /// 自定义Bold字体
    static func appBold(size: CGFloat) -> Font {
        return Font.custom("Nunito-Bold", size: size)
    }
    
    /// 自定义ExtraBold字体
    static func appExtraBold(size: CGFloat) -> Font {
        return Font.custom("Nunito-ExtraBold", size: size)
    }
    
    /// 自定义Italic字体
    static func appItalic(size: CGFloat) -> Font {
        return Font.custom("Nunito-Italic", size: size)
    }
}

// MARK: - 字体应用修饰符
extension View {
    /// 应用App默认字体样式到整个视图层次
    func applyAppFontStyle() -> some View {
        self
            .font(.appBody) // 设置默认字体为Regular
    }
}
