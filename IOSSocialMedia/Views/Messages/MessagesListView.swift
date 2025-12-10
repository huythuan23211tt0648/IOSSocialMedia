import SwiftUI

struct MessagesListView: View {
    var conversations: [Conversation] = sampleConversations
    
    var body: some View {
        NavigationView {
            List(conversations) { convo in
                NavigationLink(destination: ChatView(user: convo.user)) {
                    HStack(spacing: 12) {
                        Image(convo.user.avatar)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 55, height: 55)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(convo.user.username)
                                .font(.system(size: 17, weight: .semibold))
                            
                            Text(convo.lastMessage)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Text(convo.time)
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Messages")
        }
    }
}
