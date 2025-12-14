//
//  PostViewModel.swift
//  IOSSocialMedia
//
//  Created by cao_dong on 14/12/25.
//
import SwiftUI
import Firebase

@MainActor
class PostViewModel: ObservableObject {

    @Published var post: Post
    @Published var comments: [Comment] = []

    // DEMO USER
    let uid = Auth.auth().currentUser?.uid ?? "demo_uid"
    let username = "caodong"

    init(post: Post) {
        self.post = post
    }

    // MARK: - LIKE
    func likePost() async {
        try? await PostService.likePost(
            post: post,
            uid: uid,
            username: username
        )
        post.likesCount += 1 // demo
    }

    // MARK: - LOAD COMMENTS
    func loadComments() async {
        guard let postId = post.id else { return }
        comments = (try? await PostService.fetchComments(postId: postId)) ?? []
    }

    // MARK: - ADD COMMENT
    func addComment(text: String) async {
        guard let postId = post.id else { return }

        let comment = Comment(
            
            uid: uid,
            username: username,
            profileImageUrl: nil,
            text: text,
            timestamp: nil
        )

        try? await PostService.addComment(
            postId: postId,
            comment: comment
        )

        await loadComments()
    }
}
