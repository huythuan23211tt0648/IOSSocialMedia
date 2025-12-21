//
//  PostService.swift
//  IOSSocialMedia
//
//  Created by cao_dong on 14/12/25.
//

import Foundation
import Firebase
import FirebaseFirestore

struct PostService {

    static let db = Firestore.firestore()

    // MARK: - LIKE / UNLIKE
    static func likePost(
        post: Post,
        uid: String,
        username: String
    ) async throws {

        guard let postId = post.id else { return }

        let db = Firestore.firestore()
        let postRef = db.collection("posts").document(postId)
        let likeRef = postRef.collection("likes").document(uid)

        try await db.runTransaction { transaction, errorPointer in

            let likeSnapshot: DocumentSnapshot
            do {
                likeSnapshot = try transaction.getDocument(likeRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            if likeSnapshot.exists {
                // UNLIKE
                transaction.deleteDocument(likeRef)
                transaction.updateData([
                    "likes_count": FieldValue.increment(Int64(-1))
                ], forDocument: postRef)
            } else {
                // LIKE
                transaction.setData([
                    "uid": uid,
                    "username": username,
                    "timestamp": FieldValue.serverTimestamp()
                ], forDocument: likeRef)

                transaction.updateData([
                    "likes_count": FieldValue.increment(Int64(1))
                ], forDocument: postRef)
            }

            return nil
        }
    }


    // MARK: - ADD COMMENT
    static func addComment(postId: String, comment: Comment) async throws {
        let postRef = db.collection("posts").document(postId)

        try await postRef.collection("comments").addDocument(from: comment)
        try await postRef.updateData([
            "comments_count": FieldValue.increment(Int64(1))
        ])
    }


  
}
