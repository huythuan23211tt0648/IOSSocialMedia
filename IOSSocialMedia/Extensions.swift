//
//  Extensions.swift
//  IOSSocialMedia
//
//  Created by cao_dong on 22/12/25.
//

import SwiftUI
extension UIImage {
    // Hàm này giúp thay đổi kích thước ảnh
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

struct TabBarAccessor: UIViewControllerRepresentable {
    var callback: (UITabBar) -> Void
    private let proxyController = UIViewController()

    func makeUIViewController(context: UIViewControllerRepresentableContext<TabBarAccessor>) -> UIViewController {
        proxyController.view.backgroundColor = .clear
        return proxyController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<TabBarAccessor>) {
        // Tìm TabBarController cha
        if let tabBarController = uiViewController.tabBarController {
            // Gửi TabBar ra ngoài để xử lý
            callback(tabBarController.tabBar)
        }
    }
}
