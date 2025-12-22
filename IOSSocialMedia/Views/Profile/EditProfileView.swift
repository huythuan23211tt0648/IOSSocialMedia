import SwiftUI
import PhotosUI

// MARK: - 1. MODEL DỮ LIỆU
struct LinkItem: Identifiable {
    let id = UUID()
    var url: String
    var title: String
}


// MARK: - 2. MÀN HÌNH CHÍNH: EDIT PROFILE
struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    
    // 1. KHỞI TẠO USER SERVICE
    @StateObject private var userService = UserService()
    
    // Dữ liệu Form
    @State private var username: String = ""
    @State private var pronouns: String = ""
    @State private var bio: String = ""
    
    // Dữ liệu Links
    @State private var links: [LinkItem] = []
    @State private var showLinksSheet: Bool = false
    
    // Image Picker State
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker: Bool = false
    
    // Init Navbar (Hỗ trợ Sáng/Tối)
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        // Để nil để hệ thống tự chọn màu (Trắng cho Light, Đen cho Dark)
        // appearance.backgroundColor = .systemBackground
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Nền hệ thống (Trắng/Đen)
                Color(UIColor.systemBackground).ignoresSafeArea()
                
                if userService.isLoading {
                    ProgressView().tint(.primary)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 1. Avatar Section
                            AvatarSection(
                                selectedImage: selectedImage,
                                profileImageUrl: userService.currentUser?.profileImageUrl
                            ) {
                                showImagePicker = true
                            }
                            
                            // 2. Input Section
                            ProfileInputSection(
                                username: $username,
                                pronouns: $pronouns,
                                bio: $bio
                            )
                            
                            // 3. Menu Section
                            ProfileMenuSection(
                                linksCount: links.count,
                                onLinksTap: {
                                    showLinksSheet = true
                                }
                            )
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Chỉnh sửa trang cá nhân")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") { dismiss() }
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveProfile()
                    } label: {
                        Text("Xong")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.9))
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                UniversalImagePicker(selectedImage: $selectedImage)
            }
            // Sheet quản lý Links
            .sheet(isPresented: $showLinksSheet) {
                LinksListView(links: $links)
            }
        }
        .task {
            await userService.fetchCurrentUser()
            loadUserDataToUI()
        }
    }
    
    // Đổ dữ liệu từ API vào UI
    func loadUserDataToUI() {
        guard let user = userService.currentUser else { return }
        self.username = user.username
        self.bio = user.bio ?? ""
        self.pronouns = user.pronouns ?? ""
        
        // Map SocialLinks sang mảng LinkItem
        if let social = user.socialLinks {
            var loadedLinks: [LinkItem] = []
            if let web = social.website, !web.isEmpty {
                loadedLinks.append(LinkItem(url: web, title: "Website"))
            }
            if let threads = social.threads, !threads.isEmpty {
                loadedLinks.append(LinkItem(url: threads, title: "Threads"))
            }
            if let fb = social.facebook, !fb.isEmpty {
                loadedLinks.append(LinkItem(url: fb, title: "Facebook"))
            }
            if let yt = social.youtube, !yt.isEmpty {
                 loadedLinks.append(LinkItem(url: yt, title: "Youtube"))
            }
            self.links = loadedLinks
        }
    }
    
    // Lưu Profile
    func saveProfile() {
        Task {
            do {
                try await userService.updateUserProfile(
                    username: username,
                    bio: bio,
                    pronouns: pronouns,
                    links: links,
                    newImage: selectedImage
                )
                dismiss()
            } catch {
                print("Lỗi lưu: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - 3. MÀN HÌNH DANH SÁCH LIÊN KẾT (LINKS LIST VIEW)
struct LinksListView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var links: [LinkItem] // Binding về màn hình chính
    @State private var showAddLinkView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 0) {
                    // Nút Thêm liên kết to
                    Button {
                        showAddLinkView = true
                    } label: {
                        HStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                                    .frame(width: 44, height: 44)
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .foregroundColor(.primary)
                            }
                            Text("Thêm liên kết")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.vertical, 15)
                    }
                    
                    Text("Liên kết của bạn sẽ hiển thị với mọi người trên và ngoài Instagram. Tìm hiểu thêm")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                    
                    // Danh sách link đã thêm
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(links) { link in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(link.title.isEmpty ? link.url : link.title)
                                            .foregroundColor(.primary)
                                            .fontWeight(.medium)
                                            .lineLimit(1)
                                        Text(link.url)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    // Nút xoá nhanh
                                    Button {
                                        if let idx = links.firstIndex(where: {$0.id == link.id}) {
                                            links.remove(at: idx)
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Liên kết")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "arrow.left").foregroundColor(.primary)
                    }
                }
            }
            // Mở màn hình nhập liệu
            .sheet(isPresented: $showAddLinkView) {
                AddLinkView { url, title in
                    let newLink = LinkItem(url: url, title: title)
                    links.append(newLink)
                }
            }
        }
    }
}

// MARK: - 4. MÀN HÌNH NHẬP LIÊN KẾT (ADD LINK VIEW)
struct AddLinkView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (String, String) -> Void
    
    @State private var urlText: String = ""
    @State private var titleText: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Input URL
                    CustomInputView15(label: "URL", text: $urlText)
                        .autocapitalization(.none)
                    
                    // Input Title
                    CustomInputView15(label: "Tiêu đề", text: $titleText)
                    
                    Text("Mọi người trên Instagram có thể nhìn thấy liên kết và tiêu đề liên kết.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Thêm liên kết")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "arrow.left").foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if !urlText.isEmpty {
                            onSave(urlText, titleText)
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundColor(urlText.isEmpty ? .gray : .blue)
                    }
                    .disabled(urlText.isEmpty)
                }
            }
        }
    }
}

// MARK: - 5. CÁC COMPONENT CON (HỖ TRỢ SÁNG/TỐI)

struct AvatarSection: View {
    var selectedImage: UIImage?
    var profileImageUrl: String?
    var onEditTap: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 20) {
                ZStack {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable().scaledToFill()
                            .frame(width: 90, height: 90).clipShape(Circle())
                    }
                    else if let base64String = profileImageUrl, !base64String.isEmpty {
                        Base64ImageView(base64String: base64String)
                            .frame(width: 90, height: 90).clipShape(Circle())
                    }
                    else {
                        Image(systemName: "person.circle.fill")
                            .resizable().foregroundColor(.gray)
                            .frame(width: 90, height: 90)
                    }
                }
                
                Image(systemName: "person.crop.circle.fill")
                    .resizable().foregroundColor(.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
            }
            
            Button(action: onEditTap) {
                Text("Chỉnh sửa ảnh hoặc avatar")
                    .font(.footnote).fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.3, green: 0.6, blue: 0.9))
            }
        }
        .padding(.top, 20)
    }
}

struct ProfileInputSection: View {
    @Binding var username: String
    @Binding var pronouns: String
    @Binding var bio: String
    
    var body: some View {
        VStack(spacing: 15) {
            CustomInputView15(label: "Tên người dùng", text: $username)
            CustomInputView15(label: "Danh xưng", text: $pronouns)
            CustomInputView15(label: "Tiểu sử", text: $bio)
        }
    }
}

struct ProfileMenuSection: View {
    var linksCount: Int
    var onLinksTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onLinksTap) {
                HStack {
                    Text("Thêm liên kết").foregroundColor(.primary)
                    Spacer()
                    if linksCount > 0 {
                        Text("\(linksCount)").foregroundColor(.gray).padding(.trailing, 4)
                    }
                    Image(systemName: "chevron.right").foregroundColor(.gray)
                }
                .padding()
            }
        }
    }
}

struct CustomInputView15: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.caption).foregroundColor(.gray)
            TextField("", text: $text)
                .foregroundColor(.primary).font(.body)
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
        )
    }
}
