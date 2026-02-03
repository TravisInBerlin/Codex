import Foundation

struct FeedItem: Identifiable, Hashable {
    let id: UUID
    let sentenceId: String
    let headline: String
    let textDe: String
    let textJa: String
    let tags: [String]
}

struct Lexeme: Identifiable, Hashable {
    let id: String
    let textDe: String
    let meaningJa: String
    let gender: String
    let etymology: String
    let prepositionPattern: String?
    let verbForms: String?
}

struct Sentence: Identifiable, Hashable {
    let id: String
    let textDe: String
    let textJa: String
    let lexemes: [Lexeme]
}

extension Sentence {
    static func placeholder(id: String) -> Sentence {
        Sentence(id: id, textDe: "", textJa: "", lexemes: [])
    }
}

struct Card: Identifiable, Hashable {
    let id: UUID
    let front: String
    let back: String
    let status: CardStatus
}

enum CardStatus: String {
    case new
    case due
    case learned
    case difficult
}

struct SourceItem: Identifiable, Hashable {
    let id: UUID
    let handle: String
    var enabled: Bool
    let lastSync: String
    let rssUrl: String?
}

enum CardFilter {
    case due
    case new
    case difficult
    case all
}
