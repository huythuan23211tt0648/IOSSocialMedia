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

// 1. Tạo Struct con để quản lý link (cho gọn)
struct SocialLinks: Codable {
    var facebook: String?
    var threads: String?
    var youtube: String?
    var website: String?
    
    // Nếu tên biến giống tên field thì không cần CodingKeys,
    // nhưng cứ viết rõ ra cho chắc chắn.
}

// 2. Cập nhật User Model chính
struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var username: String
    var email: String
    var profileImageUrl: String?
    
    // --- CÁC TRƯỜNG MỚI BẠN YÊU CẦU ---
    var bio: String?          // Tiểu sử (Cho phép nhiều dòng)
    var pronouns: String?     // Danh xưng (VD: He/Him, She/Her)
    var socialLinks: SocialLinks? // Object chứa các link (Optional)
    
    // Các biến đếm cũ...
    var followersCount: Int = 0
    var followingCount: Int = 0
    var postsCount: Int = 0
    @ServerTimestamp var createdAt: Date?
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case profileImageUrl = "profile_image_url"
        
        // Map trường mới
        case bio
        case pronouns
        case socialLinks = "social_links" // Map snake_case sang camelCase
        
        case followersCount = "followers_count"
        case followingCount = "following_count"
        case postsCount = "posts_count"
        case createdAt = "created_at"
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
    var content: String
    var profileImageUrl: String?
    

    let likeCount: Int
    var isLiked: Bool = false
    @ServerTimestamp var timestamp: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case profileImageUrl = "profile_image_url"
        case uid
        case content
        case timestamp
        case likeCount
        case isLiked
    }
}


// 2. Tạo dữ liệu giả để test
let mockComments = [
    Comment(uid:"1231213",username: "wife_meoz", content: "Đỉnh quá bạn ơi! 😍", profileImageUrl: "person.crop.circle.fill", likeCount: 12),
    Comment(uid:"1231434",username: "namcito", content: "Xin info cái áo với ạ 👇", profileImageUrl: "star.circle.fill", likeCount: 4),
    Comment(uid:"12312343",username: "npdand", content: "Check inbox mình nhé shop ơi", profileImageUrl: "bolt.circle.fill",  likeCount: 0),
    Comment(uid:"12314343",username: "fan_cung", content: "Quá tuyệt vời luônnnnnnnn 🔥🔥🔥", profileImageUrl: "heart.circle.fill", likeCount: 1)
]


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
extension Date {
    func toShortTime() -> String {
        let components = Calendar.current.dateComponents([.second, .minute, .hour, .day, .weekOfYear], from: self, to: Date())
        
        if let week = components.weekOfYear, week > 0 {
            return "\(week)w" // 1w, 2w (tuần)
        } else if let day = components.day, day > 0 {
            return "\(day)d" // 1d, 2d (ngày)
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h" // 1h, 5h (giờ)
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m" // 1m, 30m (phút)
        } else if let second = components.second, second > 0 {
            return "\(second)s" // 5s (giây)
        } else {
            return "now" // Vừa xong
        }
    }
}

