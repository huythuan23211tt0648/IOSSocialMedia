//
//  PostService.swift
//  IOSSocialMedia
//
//  Created by cao_dong on 14/12/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth
import UIKit

class PostService:ObservableObject {

    static let db = Firestore.firestore()
     let uid = Auth.auth().currentUser?.uid
    
    let db = Firestore.firestore()
    // Singleton để gọi ở đâu cũng được
        static let shared = PostService()
    @Published var posts: [Post] = []
    

    // MARK: CREATE POST
        func uploadPost(caption: String, images: [UIImage]) async throws {
            // 1. Kiểm tra User ID
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            let db = Firestore.firestore()
            
            // 2. Convert tất cả ảnh sang Base64
            var base64Strings: [String] = []
            
            for image in images {
                // Resize ảnh về 600px
                if let resizedImage = image.resized(toWidth: 600) {
                    // Nén ảnh JPEG chất lượng 0.5
                    if let imageData = resizedImage.jpegData(compressionQuality: 0.5) {
                        let str = imageData.base64EncodedString()
                        base64Strings.append(str)
                    }
                }
            }
            
            // 3. Lấy thông tin User hiện tại
            let userSnapshot = try await db.collection("users").document(uid).getDocument()
            let userData = userSnapshot.data() ?? [:]
            
            let userName = userData["username"] as? String ?? "unknown"
            let profileImageUrl = userData["profile_image_url"] as? String
            
            // 4. Tạo Object Post
            let post = Post(
                ownerUid: uid,
                ownerUsername: userName,
                ownerImageUrl: profileImageUrl,
                caption: caption,
                imageUrls: base64Strings,
                likesCount: 0,
                commentsCount: 0
            )
            
            // --- BƯỚC 5: DÙNG BATCH ĐỂ GHI POST VÀ TĂNG BIẾN ĐẾM ---
            let batch = db.batch()
            
            // A. Tạo Reference cho bài viết mới (Tự sinh ID)
            let newPostRef = db.collection("posts").document()
            
            // B. Ghi dữ liệu bài viết vào Reference đó
            try batch.setData(from: post, forDocument: newPostRef)
            
            // C. Tăng biến đếm posts_count trong User (Atomic Increment)
            let userRef = db.collection("users").document(uid)
            
            // Lưu ý: Key "posts_count" phải khớp với CodingKeys trong User Model
            batch.updateData([
                "posts_count": FieldValue.increment(Int64(1))
            ], forDocument: userRef)
            
            // D. Thực thi Batch (Gửi lên Server)
            try await batch.commit()
            
            print("✅ Tạo bài viết thành công và đã tăng posts_count")
        }
    
    //MARK: GET LIST POST
    func fetchAllPosts() async throws -> [Post]{
        let snapshot  = try await Firestore.firestore().collection("posts").order(by: "timestamp", descending: true).getDocuments()
        
        //map từ document -> oject post
        return snapshot.documents.compactMap({try? $0.data(as: Post.self)})
    }
    
    //MARK: GET LIST POST BY USER_ID
    func fetchUserPosts(uid: String) async {
            do {
                let snapshot = try await db.collection("posts")
                    .whereField("owner_uid", isEqualTo: uid)
                    .order(by: "timestamp", descending: true)
                    .getDocuments()
                
                let fetchedPosts = snapshot.documents.compactMap({ try? $0.data(as: Post.self) })
                
                // Cập nhật lên UI (Bắt buộc chạy trên Main Thread)
                await MainActor.run {
                    self.posts = fetchedPosts
                    print("Đã tải \(self.posts.count) bài viết cho user \(uid)")
                }
            } catch {
                print("Lỗi tải bài viết: \(error.localizedDescription)")
            }
        }
    
    
    // MARK: - LIKE / UNLIKE
    func likePost(
        post: Post
       
    ) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {return
        }
        guard let postId = post.id else { return }
        // Ở đây mình ví dụ lấy tạm username từ Auth (nếu có updateDisplayName)
                let username = Auth.auth().currentUser?.displayName ?? "User"
        let postRef = db.collection("posts").document(postId)
        let likeRef = postRef.collection("likes").document(uid)

       _ = try await db.runTransaction { transaction, errorPointer in
                    let likeSnapshot: DocumentSnapshot
                    do {
                        likeSnapshot = try transaction.getDocument(likeRef)
                        print("like thanh cong")
                    } catch let error as NSError {
                        errorPointer?.pointee = error
                        print("like fail")
                        return nil
                    }

                    if likeSnapshot.exists {
                        // UNLIKE
                        transaction.deleteDocument(likeRef)
                        transaction.updateData(["likes_count": FieldValue.increment(Int64(-1))], forDocument: postRef)
                    } else {
                        // LIKE
                        transaction.setData([
                            "uid": uid,
                            "username": username,
                            "timestamp": FieldValue.serverTimestamp()
                        ], forDocument: likeRef)
                        
                        transaction.updateData(["likes_count": FieldValue.increment(Int64(1))], forDocument: postRef)
                    }
                    return nil
                }
    }
    
    // MARK: - CHECK IF USER LIKED POST
        func checkIfUserLikedPost(postId: String) async throws -> Bool {
            guard let uid = Auth.auth().currentUser?.uid else { return false }
            
            // Kiểm tra xem trong sub-collection "likes" có document tên là UID của mình không
            let snapshot = try await Firestore.firestore()
                .collection("posts")
                .document(postId)
                .collection("likes")
                .document(uid)
                .getDocument()
            
            return snapshot.exists
        }


    // MARK: - ADD COMMENT (Dùng Batch Write)
        func addComment(postId: String, content: String) async throws {
            
            // 1. Kiểm tra đăng nhập
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            // 2. Lấy thông tin user hiện tại để gắn vào comment
            // (Lưu ý: Việc gọi fetch user ở đây sẽ làm chậm comment 1 chút, tốt nhất nên truyền User từ bên ngoài vào nếu có thể)
            let userSnapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
            let userData = userSnapshot.data() ?? [:]
            
            let userName = userData["username"] as? String ?? "Unknown"
             let profileImageUrl = userData["profile_image_url"] as? String // Nếu muốn lấy avatar
            
            // 3. Tạo Object Comment
            let newComment = Comment(
                uid: uid,
                username: userName,
                content: content,
                profileImageUrl: profileImageUrl, // Hoặc điền profileImageUrl lấy ở trên
                likeCount: 0,
                timestamp: nil // Firestore sẽ tự điền serverTimestamp
            )
            
            // 4. Chuẩn bị Batch
            let postRef = db.collection("posts").document(postId)
            let newCommentRef = postRef.collection("comments").document() // Tạo ID mới
            
            let batch = db.batch()
            
            // 👇 SỬA LỖI Ở ĐÂY: Dùng biến 'newComment' chứ không phải kiểu 'Comment'
            try batch.setData(from: newComment, forDocument: newCommentRef)
            
            // Tăng đếm comment
            batch.updateData(["comments_count": FieldValue.increment(Int64(1))], forDocument: postRef)
            
            // 5. Gửi lên Server
            try await batch.commit()
            
            print("✅ Đã thêm comment thành công!")
        }
    
    
    
    
    // MARK: - DELETE POST (Dùng Batch Write - Quan trọng)
        func deletePost(postId: String) async throws {
            let postRef = db.collection("posts").document(postId)
            let batch = db.batch() // Tạo gói lệnh
            
            // 1. Lấy tất cả Likes để xóa
            let likesSnapshot = try await postRef.collection("likes").getDocuments()
            for doc in likesSnapshot.documents {
                batch.deleteDocument(doc.reference) // Thêm lệnh xóa vào gói
            }
            
            // 2. Lấy tất cả Comments để xóa
            let commentsSnapshot = try await postRef.collection("comments").getDocuments()
            for doc in commentsSnapshot.documents {
                batch.deleteDocument(doc.reference) // Thêm lệnh xóa vào gói
            }
            
            // 3. Xóa bài viết chính
            batch.deleteDocument(postRef)
            
            // 4. Gửi 1 lần duy nhất lên Server
            try await batch.commit()
            
            print("Đã xóa bài viết và toàn bộ dữ liệu liên quan.")
        }
    
//    MARK: FETCH COMMENTS
    func fetchComments(postId:String) async throws -> [Comment]{
        let snapshot = try await db.collection("posts")
            .document(postId)
            .collection("comments")
            .order(by: "timestamp", descending: true) // Sắp xếp: Mới nhất lên đầu
            .getDocuments()
        
        // Map dữ liệu từ Firestore sang mảng [Comment]
                return snapshot.documents.compactMap({ try? $0.data(as: Comment.self) })
    }

//MARK: UPDATE
    func updatePost(postId: String, caption: String, images: [UIImage]) async throws {
        let db = Firestore.firestore()
        
        // 1. Xử lý ảnh: Convert lại toàn bộ mảng ảnh hiện tại sang Base64
        // (Giống hệt logic trong uploadPost)
        var base64Strings: [String] = []
        
        for image in images {
            // Resize ảnh về 600px để tối ưu dung lượng
            if let resizedImage = image.resized(toWidth: 600) {
                // Nén ảnh JPEG chất lượng 0.5
                if let imageData = resizedImage.jpegData(compressionQuality: 0.5) {
                    let str = imageData.base64EncodedString()
                    base64Strings.append(str)
                }
            }
        }
        
        // 2. Tạo data update
        // Lưu ý: Key "image_urls" phải khớp với tên field trên Firestore của bạn
        // Nếu bạn dùng Codable là imageUrls thì check lại Firestore xem nó lưu là gì (thường là snake_case nếu dùng @PropertyName)
        let updateData: [String: Any] = [
            "caption": caption,
            "image_urls": base64Strings
        ]
        
        // 3. Gửi lên Firestore
        try await db.collection("posts").document(postId).updateData(updateData)
    }
    
    
}
