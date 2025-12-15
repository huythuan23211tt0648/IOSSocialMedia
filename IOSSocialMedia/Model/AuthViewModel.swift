import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
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
                                  name: name,
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
}
