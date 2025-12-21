import SwiftUI
import FirebaseAuth

struct RegisterView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false

    var body: some View {
        ScrollView{
            
     
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.9), .purple.opacity(0.8)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 5) {
                ZStack {
                    LinearGradient(colors: [.yellow, .orange, .pink, .purple],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 8)

                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 4)
                }

                VStack(spacing: 8) {
                    Text("Tạo tài khoản")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Tham gia để kết nối và khám phá")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 12)

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Họ và tên")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: "person")
                                .foregroundColor(.pink)
                            TextField("Nguyễn Văn A", text: $name)
                                .textInputAutocapitalization(.words)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.pink)
                            TextField("email@domain.com", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mật khẩu")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.pink)
                            Group {
                                if showPassword {
                                    TextField("••••••••", text: $password)
                                } else {
                                    SecureField("••••••••", text: $password)
                                }
                            }
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Nhập lại mật khẩu")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: "lock.rotation")
                                .foregroundColor(.pink)
                            Group {
                                if showConfirmPassword {
                                    TextField("••••••••", text: $confirmPassword)
                                } else {
                                    SecureField("••••••••", text: $confirmPassword)
                                }
                            }
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    Button(action: register) {
                        Text("Đăng ký")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(isRegisterDisabled || isLoading ? Color.gray : Color.pink)
                            .cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)
                    }
                    .disabled(isRegisterDisabled || isLoading)

                    HStack {
                        Text("Đã có tài khoản?")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        Button("Đăng nhập") {
                            dismiss()
                        }
                        .font(.footnote)
                        .foregroundColor(.pink)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                .padding(.horizontal)

                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 16)
        }
        .navigationBarBackButtonHidden(true)
        .alert("Lỗi đăng ký", isPresented: $showErrorAlert, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(errorMessage ?? "Đã có lỗi xảy ra, vui lòng thử lại.")
        })
        .alert("Đăng ký thành công", isPresented: $showSuccessAlert, actions: {
            Button("OK") {
                dismiss()
            }
        }, message: {
            Text("Tài khoản đã được tạo. Bạn có thể đăng nhập và sử dụng ngay.")
        })
        }
    }

    private var isRegisterDisabled: Bool {
        name.isEmpty || email.isEmpty || password.isEmpty || password != confirmPassword
    }
    
    private func register() {
        guard !isRegisterDisabled, !isLoading else { return }
        isLoading = true
        
        auth.register(name: name, email: email, password: password) { result in
            isLoading = false
            
            switch result {
            case .success:
                showSuccessAlert = true
            case .failure(let error):
                errorMessage = vietnameseMessage(for: error)
                showErrorAlert = true
            }
        }
    }
    
    private func vietnameseMessage(for error: Error) -> String {
        let nsError = error as NSError
        
        // Chỉ xử lý các lỗi từ Firebase Auth, còn lại dùng mô tả mặc định
        guard nsError.domain == AuthErrorDomain,
              let code = AuthErrorCode.Code(rawValue: nsError.code) else {
            return "Đã có lỗi xảy ra, vui lòng thử lại.\n\nChi tiết: \(error.localizedDescription)"
        }
        
        switch code {
        case .invalidEmail:
            return "Email không hợp lệ. Vui lòng kiểm tra lại định dạng email."
        case .emailAlreadyInUse:
            return "Email này đã được sử dụng cho một tài khoản khác."
        case .weakPassword:
            return "Mật khẩu quá yếu. Vui lòng dùng mật khẩu mạnh hơn (ít nhất 6 ký tự)."
        case .networkError:
            return "Lỗi kết nối mạng. Vui lòng kiểm tra lại internet và thử lại."
        case .tooManyRequests:
            return "Bạn đã thao tác quá nhiều lần. Vui lòng thử lại sau ít phút."
        default:
            return "Không thể đăng ký tài khoản. Vui lòng thử lại.\n\nChi tiết: \(error.localizedDescription)"
        }
    }
}
