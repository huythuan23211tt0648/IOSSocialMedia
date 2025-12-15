import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.9), .purple.opacity(0.8)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 24) {
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

                    Image(systemName: "camera.aperture")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 4)
                }

                VStack(spacing: 8) {
                    Text("Chào mừng trở lại")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Đăng nhập để tiếp tục khám phá")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 20)

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.blue)
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
                                .foregroundColor(.blue)
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

                    Button(action: login) {
                        Text("Đăng nhập")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background((email.isEmpty || password.isEmpty || isLoading) ? Color.gray : Color.blue)
                            .cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)

                    HStack {
                        Button("Quên mật khẩu?") {
                            // TODO: hook up reset flow when available
                        }
                        .font(.footnote)
                        .foregroundColor(.blue)

                        Spacer()

                        NavigationLink(destination: RegisterView().environmentObject(auth)) {
                            Text("Tạo tài khoản")
                                .font(.footnote)
                                .foregroundColor(.blue)
                        }
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
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .alert("Đăng nhập thất bại", isPresented: $showErrorAlert, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(errorMessage ?? "Vui lòng kiểm tra lại thông tin đăng nhập.")
        })

    }

    private func login() {
        guard !email.isEmpty, !password.isEmpty, !isLoading else { return }
        isLoading = true
        
        auth.login(email: email, password: password) { result in
            isLoading = false
            switch result {
            case .success:
                // AuthViewModel đã set isLoggedIn = true, UI khác sẽ tự phản ứng
                break
            case .failure(let error):
                errorMessage = vietnameseLoginMessage(for: error)
                showErrorAlert = true
            }
        }
    }
    
    private func vietnameseLoginMessage(for error: Error) -> String {
        let nsError = error as NSError
        
        guard nsError.domain == AuthErrorDomain,
              let code = AuthErrorCode.Code(rawValue: nsError.code) else {
            return "Không thể đăng nhập. Vui lòng thử lại.\n\nChi tiết: \(error.localizedDescription)"
        }
        
        switch code {
        case .invalidEmail:
            return "Email không hợp lệ. Vui lòng kiểm tra lại định dạng email."
        case .userNotFound:
            return "Không tìm thấy tài khoản với email này. Vui lòng kiểm tra lại hoặc đăng ký mới."
        case .wrongPassword:
            return "Mật khẩu không đúng. Vui lòng thử lại."
        case .networkError:
            return "Lỗi kết nối mạng. Vui lòng kiểm tra lại internet và thử lại."
        case .tooManyRequests:
            return "Bạn đã đăng nhập sai quá nhiều lần. Vui lòng thử lại sau ít phút."
        default:
            return "Sai tên email hoặc mật khẩu. Vui lòng thử lại."
        }
    }


}

//struct LoginView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginView()
//    }
//}
