import Foundation
import Observation

@Observable
final class NotificationRouter {
    static let shared = NotificationRouter()
    var selectedSentenceId: String? = nil
}
