//
//  CommentViewModel.swift
//  IOSSocialMedia
//
//  Created by cao_dong on 22/12/25.
//

import SwiftUI

class CommentViewModel:ObservableObject {
    @Published var comments: [Comment]=[]
    @Published var isLoading = false
    private let postId : String
    
    init(isLoading: Bool = false, postId: String) {
 
        self.postId = postId
    }
    func loadComments() async {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        do{
            let loadedComments = try await PostService.shared.fetchComments(postId: postId)
            DispatchQueue.main.async {
                            self.comments = loadedComments
                            self.isLoading = false
                        }
        }
        catch{
            print("Lỗi tải comment: \(error.localizedDescription)")
                        DispatchQueue.main.async { self.isLoading = false }
        }
    }
    func sendComment(content: String) async {
       
            // Tạo comment tạm (username thật nên lấy từ User Profile)
         
            do {
                try await PostService.shared.addComment(postId: postId, content: content)
                await loadComments() // Tải lại sau khi gửi
            } catch {
                print("Lỗi gửi: \(error)")
            }
        }
}


