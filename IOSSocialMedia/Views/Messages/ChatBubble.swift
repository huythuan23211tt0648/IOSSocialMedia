import SwiftUI

struct ChatBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isMe {
                Spacer()
                Text(message.text)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(18)
                    .frame(maxWidth: 260, alignment: .trailing)
            } else {
                Text(message.text)
                    .padding()
                    .background(Color(.systemGray4))
                    .foregroundColor(.black)
                    .cornerRadius(18)
                    .frame(maxWidth: 260, alignment: .leading)
                Spacer()
            }
        }
    }
}
