//
//  UserService.swift
//  IOSSocialMedia
//
//  Created by cao_dong on 22/12/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

// MARK: - 2. USER SERVICE
class UserService: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    // Hàm lấy User hiện tại
    func fetchCurrentUser() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            // Nếu chưa login, set về nil hoặc xử lý logic riêng
            print("Chưa đăng nhập")
            return
        }
        
        await MainActor.run { self.isLoading = true }
        
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            let user = try snapshot.data(as: User.self)
            
            await MainActor.run {
                self.currentUser = user
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                print("Lỗi fetch user: \(error)")
            }
        }
    }
    // MARK: - UPDATE USER PROFILE
        func updateUserProfile(
            username: String,
            bio: String,
            pronouns: String,
            links: [LinkItem], // Nhận danh sách link từ View
            newImage: UIImage? // Ảnh mới (nếu có)
        ) async throws {
            
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            // 1. Tạo Dictionary chứa dữ liệu cần update
            var data: [String: Any] = [
                "username": username,
                "bio": bio,
                "pronouns": pronouns,
                // Cập nhật thời gian sửa đổi nếu cần
                "updated_at": FieldValue.serverTimestamp()
            ]
            
            // 2. Xử lý ảnh: Chuyển UIImage -> Base64 String
            // Lưu ý: Firestore giới hạn document 1MB. Ảnh Base64 rất nặng.
            // Nên nén mạnh (0.1 - 0.3) để tránh lỗi quá dung lượng.
            if let image = newImage,
               let imageData = image.jpegData(compressionQuality: 0.2) { // Nén 0.2
                
                let base64String = imageData.base64EncodedString()
                
                // Key phải khớp với CodingKeys trong Model: "profile_image_url"
                data["profile_image_url"] = base64String
            }
            
            // 3. Xử lý Links: Map từ [LinkItem] -> Dictionary của SocialLinks
            var socialLinksData: [String: String] = [:]
            
            for link in links {
                // Logic đơn giản để phân loại link dựa trên Tiêu đề hoặc URL
                let lowerTitle = link.title.lowercased()
                
                if lowerTitle.contains("facebook") {
                    socialLinksData["facebook"] = link.url
                } else if lowerTitle.contains("threads") {
                    socialLinksData["threads"] = link.url
                } else if lowerTitle.contains("youtube") {
                    socialLinksData["youtube"] = link.url
                } else {
                    // Mặc định cho vào website nếu không khớp cái nào
                    socialLinksData["website"] = link.url
                }
            }
            
            // Key khớp CodingKeys: "social_links"
            if !socialLinksData.isEmpty {
                data["social_links"] = socialLinksData
            }
            
            // 4. Gửi lên Firestore
            try await db.collection("users").document(uid).updateData(data)
            
            // 5. Cập nhật lại dữ liệu local (currentUser) để UI đổi ngay lập tức
            await fetchCurrentUser()
        }
}
