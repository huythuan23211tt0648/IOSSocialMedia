import Foundation

struct ChatUser: Identifiable {
    let id = UUID()
    let username: String
    let avatar: String
}

struct Message: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isMe: Bool
}


struct Conversation: Identifiable {
    let id = UUID()
    let user: ChatUser
    let lastMessage: String
    let time: String
}

let sampleUsers = [
    ChatUser(username: "john_doe", avatar: "avatar1"),
    ChatUser(username: "anna.dev", avatar: "avatar2"),
]

let sampleMessages = [
    Message(text: "Hey, how are you?", isMe: false),
    Message(text: "I'm good! You?", isMe: true),
    Message(text: "Working on my SwiftUI project 😁", isMe: false),
]

let sampleConversations = [
    Conversation(user: sampleUsers[0], lastMessage: "Let's meet tomorrow!", time: "8m"),
    Conversation(user: sampleUsers[1], lastMessage: "New design is done!", time: "2h"),
]
