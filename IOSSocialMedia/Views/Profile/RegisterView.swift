import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Tạo tài khoản")
                .font(.largeTitle)
                .bold()

            TextField("Họ và tên", text: $name)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

            TextField("Email", text: $email)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

            SecureField("Mật khẩu", text: $password)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

            Button(action: {
                auth.isLoggedIn = true
            }) {
                Text("Đăng ký")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
    }
}
