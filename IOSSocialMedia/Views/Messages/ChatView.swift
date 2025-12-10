import SwiftUI

struct ChatView: View {
    let user: ChatUser
    
    @State private var typedMessage = ""
    @State private var messages: [Message] = sampleMessages
    
    var body: some View {
        VStack {
            // MARK: Messages list
            ScrollViewReader { reader in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(messages) { msg in
                            ChatBubble(message: msg)
                                .id(msg.id)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    // scroll to bottom when open
                    if let last = messages.last?.id {
                        reader.scrollTo(last, anchor: .bottom)
                    }
                }
                .onChange(of: messages) { _ in
                    // auto scroll when sending
                    if let last = messages.last?.id {
                        reader.scrollTo(last, anchor: .bottom)
                    }
                }
            }
            
            // MARK: Input bar
            HStack {
                TextField("Message...", text: $typedMessage)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                }
                .disabled(typedMessage.isEmpty)
            }
            .padding()
        }
        .navigationTitle(user.username)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func sendMessage() {
        let newMessage = Message(text: typedMessage, isMe: true)
        messages.append(newMessage)
        typedMessage = ""
    }
}
