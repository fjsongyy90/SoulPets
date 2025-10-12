//
//  EditableImage.swift
//  SoulPets
//
//  Created by 宋友勇 on 2025/10/12.
//


import SwiftUI

/// 一个可识别的图片包装器，用于驱动 sheet 和 fullScreenCover
struct EditableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}