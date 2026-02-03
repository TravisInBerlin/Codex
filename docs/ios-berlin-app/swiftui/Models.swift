import Foundation

struct FeedItem: Identifiable, Hashable {
    let id: UUID
    let headline: String
    let textDe: String
    let textJa: String
    let tags: [String]
}

struct Lexeme: Identifiable, Hashable {
    let id: UUID
    let textDe: String
    let meaningJa: String
    let gender: String
    let etymology: String
    let prepositionPattern: String?
    let verbForms: String?
}

enum CardFilter {
    case due
    case new
    case difficult
    case all
}
