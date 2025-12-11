//
//  ContentViewFireBase.swift
//  IOSSocialMedia
//
//  Created by cao_dong on 11/12/25.
//
import SwiftUI

struct ContentViewFireBase: View {
    @StateObject var viewModel = TodoViewModel()
    @State private var text = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Khu vực thêm mới
                HStack {
                    TextField("Nhập công việc mới...", text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        if !text.isEmpty {
                            viewModel.addItem(title: text)
                            text = "" // Reset ô nhập
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                
                // Danh sách công việc
                List {
                    ForEach(viewModel.todos) { item in
                        HStack {
                            Text(item.title)
                                .strikethrough(item.isCompleted, color: .gray)
                                .foregroundColor(item.isCompleted ? .gray : .primary)
                            
                            Spacer()
                            
                            // Nút để Update trạng thái
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(item.isCompleted ? .green : .gray)
                                .onTapGesture {
                                    viewModel.updateItem(item)
                                }
                        }
                    }
                    .onDelete(perform: viewModel.deleteItem) // Vuốt để xoá
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Todo Firestore")
        }
        .onAppear {
            viewModel.fetchData() // Bắt đầu lắng nghe dữ liệu khi app chạy
        }
    }
}
