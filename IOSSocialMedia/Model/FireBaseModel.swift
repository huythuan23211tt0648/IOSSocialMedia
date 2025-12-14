//
//  FireBaseModel.swift
//  IOSSocialMedia
//
//  Created by cao_dong on 14/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift // <--- THÊM DÒNG NÀY

// ==========================================
// 1. USER MODEL (Collection: "users")
// ==========================================
struct User: Identifiable, Codable {
    // @DocumentID: Tự động lấy ID của document (UID) gán vào biến này
    @DocumentID var id: String?
    
    var username: String
    var email: String
    var profileImageUrl: String? // Có thể null nếu chưa up avatar
    var bio: String?
    
    // Dùng Date của Swift, Firebase sẽ tự chuyển đổi
    var joinedDate: Date
    
    // CodingKeys: Dùng nếu tên biến trong Code khác tên field trên Firebase
    // Ví dụ: Trong code là 'profileImageUrl', trên Firebase là 'profile_image_url'
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case profileImageUrl = "profile_image_url"
        case bio
        case joinedDate = "joined_date"
    }
}

// ==========================================
// 2. POST MODEL (Collection: "posts")
// ==========================================
struct Post: Identifiable, Codable {
    @DocumentID var id: String?

    var ownerUid: String
    var ownerUsername: String
    var ownerImageUrl: String?

    var caption: String

    // 🔥 NHIỀU ẢNH
    var imageUrls: [String]

    var likesCount: Int
    var commentsCount: Int

    @ServerTimestamp var timestamp: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case ownerUid = "owner_uid"
        case ownerUsername = "owner_username"
        case ownerImageUrl = "owner_image_url"
        case caption
        case imageUrls = "image_urls"   // 👈 QUAN TRỌNG
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case timestamp
    }
}


// ==========================================
// 3. COMMENT MODEL (Sub-collection: "comments")
// ==========================================
struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    var uid: String // ID người comment
    var username: String
    var profileImageUrl: String?
    
    var text: String
    
    @ServerTimestamp var timestamp: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case profileImageUrl = "profile_image_url"
        case uid
        case text
        case timestamp
    }
}


// Model này đại diện cho 1 document trong sub-collection "likes"
struct Like: Identifiable, Codable {
    @DocumentID var id: String? // Thường ID này chính là UID của người like
    
    var uid: String
    var username: String
    var profileImageUrl: String?
    
    @ServerTimestamp var timestamp: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case uid
        case username
        case profileImageUrl = "profile_image_url"
        case timestamp
    }
}
