import SwiftUI

struct CreateView: View {
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var caption: String = ""
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                
                // MARK: Image preview
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(10)
                        .padding()
                } else {
                    Button {
                        isImagePickerPresented = true
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("Chọn ảnh để đăng")
                                .foregroundColor(.gray)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(12)
                        .padding()
                    }
                }
                
                Divider()
                
                // MARK: Caption input
                VStack(alignment: .leading) {
                    Text("Caption")
                        .font(.headline)
                    
                    TextEditor(text: $caption)
                        .padding(8)
                        .frame(height: 120)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // MARK: Submit button
                Button(action: {
                    print("Đăng bài...")
                    // call API here
                }) {
                    Text("Đăng bài")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedImage == nil ? Color.gray : Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .disabled(selectedImage == nil)
            }
            .navigationTitle("Tạo bài viết")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(selectedImage: $selectedImage)
            }
        }
    }
}
