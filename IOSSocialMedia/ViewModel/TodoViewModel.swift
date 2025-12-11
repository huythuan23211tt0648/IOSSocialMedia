//
//  TodoViewModel.swift
//  IOSSocialMedia
//
//  Created by cao_dong on 11/12/25.
//

import Foundation
import FirebaseFirestore

class TodoViewModel: ObservableObject {
    @Published var todos = [TodoItem]()
    private var db = Firestore.firestore()
    
    // MARK: - READ (Lắng nghe dữ liệu Realtime)
    func fetchData() {
        db.collection("todos").addSnapshotListener { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("Không có dữ liệu")
                return
            }
            
            // Map dữ liệu từ Firestore sang mảng TodoItem
            self.todos = documents.compactMap { queryDocumentSnapshot -> TodoItem? in
                return try? queryDocumentSnapshot.data(as: TodoItem.self)
            }
        }
    }
    
    // MARK: - CREATE (Thêm)
    func addItem(title: String) {
        let newItem = TodoItem(title: title)
        do {
            let _ = try db.collection("todos").addDocument(from: newItem)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - UPDATE (Sửa trạng thái hoàn thành)
    func updateItem(_ item: TodoItem) {
        guard let id = item.id else { return }
        
        // Đảo ngược trạng thái isCompleted
        let newValue = !item.isCompleted
        
        db.collection("todos").document(id).updateData([
            "isCompleted": newValue
        ]) { error in
            if let error = error { print(error.localizedDescription) }
        }
    }
    
    // MARK: - DELETE (Xoá)
    func deleteItem(at offsets: IndexSet) {
        offsets.map { todos[$0] }.forEach { item in
            guard let id = item.id else { return }
            db.collection("todos").document(id).delete() { error in
                if let error = error { print(error.localizedDescription) }
            }
        }
    }
}
