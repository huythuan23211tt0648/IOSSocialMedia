import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    // 👇 1. THÊM INIT ĐỂ TỰ ĐỘNG KIỂM TRA ĐĂNG NHẬP
        init() {
            // Kiểm tra xem trong Firebase có lưu session cũ không
            if auth.currentUser != nil {
                self.isLoggedIn = true
            } else {
                self.isLoggedIn = false
            }
        }
    
    /// Đăng ký tài khoản mới với Firebase Auth và lưu thông tin vào Firestore
    func register(name: String,
                  email: String,
                  password: String,
                  completion: @escaping (Result<Void, Error>) -> Void) {
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let self = self, let user = result?.user else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "AuthViewModel",
                                                code: -1,
                                                userInfo: [NSLocalizedDescriptionKey: "Không lấy được thông tin người dùng"])))
                }
                return
            }
            
            // Tạo model và lưu vào Firestore (DocumentID = uid)
            let appUser = User(id: user.uid,
                               username: name,
                                  email: email,
                                  createdAt: nil) // @ServerTimestamp sẽ được set trên server
            
            do {
                try self.db.collection("users").document(user.uid).setData(from: appUser) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            self.isLoggedIn = true
                            completion(.success(()))
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Đăng nhập với email & mật khẩu Firebase
    func login(email: String,
               password: String,
               completion: @escaping (Result<Void, Error>) -> Void) {
        auth.signIn(withEmail: email, password: password) { [weak self] _, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.isLoggedIn = true
                completion(.success(()))
            }
        }
    }
    // 👇 2. HÀM SIGN OUT ĐÃ SỬA
        func signOut() {
            do {
                // Gọi lệnh đăng xuất của Firebase
                try auth.signOut()
                
                // Cập nhật lại biến isLoggedIn về false để View chuyển màn hình
                DispatchQueue.main.async {
                    self.isLoggedIn = false
                }
                
                print("✅ Đã đăng xuất thành công")
            } catch let error {
                print("❌ Lỗi đăng xuất: \(error.localizedDescription)")
            }
        }
}
