//
//  HomeViewModel.swift
//  IOSSocialMedia
//
//  Created by cao_dong on 22/12/25.
//

import SwiftUI

// 1. ViewModel để quản lý dữ liệu trang chủ
class HomeViewModel : ObservableObject{
    @Published var posts : [Post] = []
    @Published var isLoading = false
    
    // ham goi postService
    func loadPosts() async {
        DispatchQueue.main.async{
            self.isLoading = true
        }
        do {
            let loadedPosts = try await PostService.shared.fetchAllPosts()
            DispatchQueue.main.async{
                self.posts = loadedPosts
                self.isLoading=false
            }
        }
        catch {
            print("Lỗi tải bài viết: \(error.localizedDescription)")
                        DispatchQueue.main.async { self.isLoading = false }
        }
    }
    
}
// 2. View để hiển thị ảnh từ chuỗi Base64.

struct Base64ImageView:View {
    let base64String : String
    var body : some View {
        if let data = Data(base64Encoded: base64String,options: .ignoreUnknownCharacters),let uiImage = UIImage(data: data){
            Image(uiImage: uiImage).resizable().scaledToFill()
        }else{
            Rectangle()
                .foregroundColor(.gray.opacity(0.3))
                .overlay(Text("Lỗi ảnh").font(.caption))
        }
    }
}

//struct HomeViewModel: View {
//    var body: some View {
//        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//    }
//}
//
//#Preview {
//    HomeViewModel()
//}
