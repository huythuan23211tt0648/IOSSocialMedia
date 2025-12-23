import SwiftUI
import PhotosUI // 👈 Bắt buộc import cái này cho iOS 15+

struct UniversalImagePicker: UIViewControllerRepresentable {
    // MARK: - CẤU HÌNH
    // Dùng cho chế độ 1 ảnh
    var singleImage: Binding<UIImage?>?
    
    // Dùng cho chế độ nhiều ảnh
    var multipleImages: Binding<[UIImage]>?
    
    // Giới hạn số lượng (0 là không giới hạn)
    let limit: Int
    
    @Environment(\.presentationMode) var presentationMode

    // 👇 HÀM KHỞI TẠO CHO 1 ẢNH
    init(selectedImage: Binding<UIImage?>) {
        self.singleImage = selectedImage
        self.multipleImages = nil
        self.limit = 1 // Chế độ 1 ảnh
    }
    
    // 👇 HÀM KHỞI TẠO CHO NHIỀU ẢNH
    init(selectedImages: Binding<[UIImage]>, limit: Int = 0) {
        self.singleImage = nil
        self.multipleImages = selectedImages
        self.limit = limit // Chế độ nhiều ảnh
    }

    // MARK: - LOGIC UIKIT
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images // Chỉ lấy ảnh, không lấy video
        config.selectionLimit = limit // 1 hoặc nhiều
        config.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - COORDINATOR (XỬ LÝ KẾT QUẢ)
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: UniversalImagePicker

        init(_ parent: UniversalImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Đóng popup chọn ảnh ngay lập tức
            parent.presentationMode.wrappedValue.dismiss()
            
            // Nếu không chọn gì thì return
            guard !results.isEmpty else { return }
            
            // --- TRƯỜNG HỢP 1: CHỌN 1 ẢNH ---
            if parent.limit == 1, let provider = results.first?.itemProvider {
                if provider.canLoadObject(ofClass: UIImage.self) {
                    provider.loadObject(ofClass: UIImage.self) { image, _ in
                        // Cập nhật UI phải ở Main Thread
                        DispatchQueue.main.async {
                            self.parent.singleImage?.wrappedValue = image as? UIImage
                        }
                    }
                }
                return
            }
            
            // --- TRƯỜNG HỢP 2: CHỌN NHIỀU ẢNH ---
            // Xử lý bất đồng bộ để load hết ảnh user đã chọn
            var tempImages: [UIImage] = []
            let dispatchGroup = DispatchGroup() // Dùng cái này để đợi load xong hết mới update
            
            for result in results {
                let provider = result.itemProvider
                if provider.canLoadObject(ofClass: UIImage.self) {
                    dispatchGroup.enter() // Bắt đầu load 1 ảnh
                    provider.loadObject(ofClass: UIImage.self) { image, _ in
                        if let uiImage = image as? UIImage {
                            tempImages.append(uiImage)
                        }
                        dispatchGroup.leave() // Load xong 1 ảnh
                    }
                }
            }
            
            // Khi tất cả ảnh đã load xong
            dispatchGroup.notify(queue: .main) {
                self.parent.multipleImages?.wrappedValue = tempImages
            }
        }
    }
}
