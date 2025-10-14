//
//  ShareSheet.swift
//  SoulPets
//
//  Created by 宋友勇 on 2025/10/14.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    
    // 要分享的内容
    var activityItems: [Any]
    
    // 可选的、不希望出现的服务（比如不显示“隔空投送”）
    var applicationActivities: [UIActivity]? = nil
    
    // 创建 UIViewController
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        // 可以在这里添加完成回调
        controller.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            if let error = error {
                print("分享操作出错: \(error.localizedDescription)")
            } else if completed {
                print("分享操作完成")
            } else {
                print("分享操作被取消")
            }
        }
        return controller
    }
    
    // 更新 UIViewController
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // 通常不需要在这里做什么
    }
}
