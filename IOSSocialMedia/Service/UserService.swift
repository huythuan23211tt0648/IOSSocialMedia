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
            links: [LinkItem],
            newImage: UIImage?
        ) async throws {
            
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            // --- BƯỚC 1: CHUẨN BỊ DỮ LIỆU USER ---
            var userData: [String: Any] = [
                "username": username,
                "bio": bio,
                "pronouns": pronouns,
                "updated_at": FieldValue.serverTimestamp()
            ]
            
            // Biến lưu ảnh mới (nếu có) để dùng update Post và Comment
            var newProfileImageUrl: String? = nil
            
            if let image = newImage,
               let resizedImage = image.resized(toWidth: 300),
               let imageData = resizedImage.jpegData(compressionQuality: 0.5) {
                
                let base64String = imageData.base64EncodedString()
                userData["profile_image_url"] = base64String
                newProfileImageUrl = base64String
            }
            
            // Xử lý Links
            var socialLinksData: [String: String] = [:]
            for link in links {
                let lowerTitle = link.title.lowercased()
                if lowerTitle.contains("facebook") { socialLinksData["facebook"] = link.url }
                else if lowerTitle.contains("threads") { socialLinksData["threads"] = link.url }
                else if lowerTitle.contains("youtube") { socialLinksData["youtube"] = link.url }
                else { socialLinksData["website"] = link.url }
            }
            if !socialLinksData.isEmpty {
                userData["social_links"] = socialLinksData
            }
            
            // --- BƯỚC 2: KHỞI TẠO BATCH ---
            let batch = db.batch()
            
            // A. Update User
            let userRef = db.collection("users").document(uid)
            batch.updateData(userData, forDocument: userRef)
            
            // --- BƯỚC 3: TÌM VÀ UPDATE POSTS (Của chính user này) ---
            let postsSnapshot = try await db.collection("posts")
                .whereField("owner_uid", isEqualTo: uid)
                .getDocuments()
            
            var postUpdateData: [String: Any] = [:]
            postUpdateData["owner_username"] = username
            if let newUrl = newProfileImageUrl {
                postUpdateData["owner_image_url"] = newUrl
            }
            
            for document in postsSnapshot.documents {
                let postRef = db.collection("posts").document(document.documentID)
                batch.updateData(postUpdateData, forDocument: postRef)
            }
            
            // --- BƯỚC 4: TÌM VÀ UPDATE COMMENTS (COLLECTION GROUP QUERY) ---
            // 🔥 QUAN TRỌNG: Tìm trong TẤT CẢ các sub-collection tên là "comments" trên toàn database
            let commentsSnapshot = try await db.collectionGroup("comments")
                .whereField("uid", isEqualTo: uid)
                .getDocuments()
            
            var commentUpdateData: [String: Any] = [:]
            commentUpdateData["username"] = username // Key trong Comment Model
            if let newUrl = newProfileImageUrl {
                commentUpdateData["profile_image_url"] = newUrl // Key trong Comment Model
            }
            
            for document in commentsSnapshot.documents {
                // document.reference tự động trỏ đúng đường dẫn (vd: posts/ID_POST/comments/ID_COMMENT)
                batch.updateData(commentUpdateData, forDocument: document.reference)
            }
            
            // --- BƯỚC 5: THỰC THI (COMMIT) ---
            // Lưu ý: Batch giới hạn 500 lệnh. Nếu user có quá nhiều post + comment (>500), sẽ cần chia nhỏ batch.
            // Nhưng với app vừa/nhỏ thì ok.
            try await batch.commit()
            
            print("✅ Đã update: User + \(postsSnapshot.count) Posts + \(commentsSnapshot.count) Comments")
            
            // --- BƯỚC 6: REFRESH DATA ---
            await fetchCurrentUser()
        }
    
    
    // 1. Hàm Follow
        func follow(uid: String) async throws {
            guard let currentUid = Auth.auth().currentUser?.uid else { return }
            
            let followingRef = Firestore.firestore().collection("users").document(currentUid).collection("user-following").document(uid)
            let followersRef = Firestore.firestore().collection("users").document(uid).collection("user-followers").document(currentUid)
            
            let currentUserRef = Firestore.firestore().collection("users").document(currentUid)
            let targetUserRef = Firestore.firestore().collection("users").document(uid)
            
          _ =  try await Firestore.firestore().runTransaction { (transaction, errorPointer) -> Any? in
                // Tạo document trong sub-collection
                transaction.setData([:], forDocument: followingRef)
                transaction.setData([:], forDocument: followersRef)
                
                // Tăng số lượng following của mình
                transaction.updateData(["following_count": FieldValue.increment(Int64(1))], forDocument: currentUserRef)
                
                // Tăng số lượng followers của người kia
                transaction.updateData(["followers_count": FieldValue.increment(Int64(1))], forDocument: targetUserRef)
                
                return nil
            }
        }
        
        // 2. Hàm Unfollow
        func unfollow(uid: String) async throws {
            guard let currentUid = Auth.auth().currentUser?.uid else { return }
            
            let followingRef = Firestore.firestore().collection("users").document(currentUid).collection("user-following").document(uid)
            let followersRef = Firestore.firestore().collection("users").document(uid).collection("user-followers").document(currentUid)
            
            let currentUserRef = Firestore.firestore().collection("users").document(currentUid)
            let targetUserRef = Firestore.firestore().collection("users").document(uid)
            
           _ = try await Firestore.firestore().runTransaction { (transaction, errorPointer) -> Any? in
                // Xóa document
                transaction.deleteDocument(followingRef)
                transaction.deleteDocument(followersRef)
                
                // Giảm số lượng
                transaction.updateData(["following_count": FieldValue.increment(Int64(-1))], forDocument: currentUserRef)
                transaction.updateData(["followers_count": FieldValue.increment(Int64(-1))], forDocument: targetUserRef)
                
                return nil
            }
        }
        
        // 3. Kiểm tra xem mình đã follow người này chưa
        func checkIfUserIsFollowed(uid: String) async throws -> Bool {
            guard let currentUid = Auth.auth().currentUser?.uid else { return false }
            
            let snapshot = try await Firestore.firestore()
                .collection("users")
                .document(currentUid)
                .collection("user-following")
                .document(uid)
                .getDocument()
            
            return snapshot.exists
        }
}
