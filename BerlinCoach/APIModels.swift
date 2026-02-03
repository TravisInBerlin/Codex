import Foundation

struct SentenceDTO: Codable, Hashable {
    let id: String
    let textDe: String
    let textJa: String
    let tags: [String]
}

struct LexemeDTO: Codable, Hashable {
    let id: String?
    let textDe: String
    let meaningJa: String
    let gender: String
    let etymology: String
    let prepositionPattern: String?
    let verbForms: String?
}

struct SentenceDetailDTO: Codable, Hashable {
    let sentence: SentenceDTO
    let lexemes: [LexemeDTO]
}

struct SourceDTO: Codable, Hashable {
    let id: String
    let handle: String
    let enabled: Bool
    let lastSyncAt: String?
    let type: String?
    let rssUrl: String?
}

struct SourcePreviewDTO: Codable, Hashable {
    let ok: Bool
    let title: String?
    let items: [String]
}

struct IngestResultDTO: Codable, Hashable {
    let fetched: Int
    let stored: Int
    let errors: [String]
}

struct CardDTO: Codable, Hashable {
    let id: String
    let front: String
    let back: String
    let status: String
    let dueAt: String?
}

struct NotificationScheduleDTO: Codable, Hashable {
    let active: Bool
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
    let maxSentences: Int
    let intervalMinutes: Int
}
