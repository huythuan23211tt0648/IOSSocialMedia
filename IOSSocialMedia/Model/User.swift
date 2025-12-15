import Foundation
import FirebaseFirestoreSwift

struct User: Identifiable, Codable {
    @DocumentID var id: String?          // DocumentID trong Firestore (uid hoặc random ID)
    var name: String
    var email: String
    @ServerTimestamp var createdAt: Date?
}
