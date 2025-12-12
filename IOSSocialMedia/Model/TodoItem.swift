//
//  Untitled.swift
//  IOSSocialMedia
//
//  Created by cao_dong on 11/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift // <--- THÊM DÒNG NÀY

struct TodoItem: Identifiable, Codable {
    @DocumentID var id: String? // ID do Firestore tự tạo
    var title: String
    var isCompleted: Bool = false
}
