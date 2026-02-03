import Foundation

protocol FeedRepositoryProtocol {
    func loadFeedItems() async throws -> [FeedItem]
}

final class FeedRepository: FeedRepositoryProtocol {
    private let api: APIClientProtocol

    init(api: APIClientProtocol) {
        self.api = api
    }

    func loadFeedItems() async throws -> [FeedItem] {
        let sentences = try await api.fetchSentences()
        return sentences.map { dto in
            FeedItem(
                id: UUID(),
                sentenceId: dto.id,
                headline: "Heute in Berlin:",
                textDe: dto.textDe,
                textJa: dto.textJa,
                tags: dto.tags
            )
        }
    }
}

protocol SentenceRepositoryProtocol {
    func loadDetail(id: String) async throws -> Sentence
}

final class SentenceRepository: SentenceRepositoryProtocol {
    private let api: APIClientProtocol

    init(api: APIClientProtocol) {
        self.api = api
    }

    func loadDetail(id: String) async throws -> Sentence {
        let detail = try await api.fetchSentenceDetail(id: id)
        let lexemes = detail.lexemes.map {
            Lexeme(
                id: $0.id ?? UUID().uuidString,
                textDe: $0.textDe,
                meaningJa: $0.meaningJa,
                gender: $0.gender,
                etymology: $0.etymology,
                prepositionPattern: $0.prepositionPattern,
                verbForms: $0.verbForms
            )
        }
        return Sentence(
            id: detail.sentence.id,
            textDe: detail.sentence.textDe,
            textJa: detail.sentence.textJa,
            lexemes: lexemes
        )
    }
}

protocol CardsRepositoryProtocol {
    func loadCards(status: CardFilter?) async throws -> [Card]
    func createCard(lexemeId: String) async throws -> Card
    func reviewCard(id: UUID, rating: String) async throws -> Card
}

final class CardsRepository: CardsRepositoryProtocol {
    private let api: APIClientProtocol

    init(api: APIClientProtocol) {
        self.api = api
    }

    func loadCards(status: CardFilter?) async throws -> [Card] {
        let statusParam: String?
        switch status {
        case .due: statusParam = "due"
        case .new: statusParam = "new"
        case .difficult: statusParam = "difficult"
        case .all, .none: statusParam = nil
        }

        let cards = try await api.fetchCards(status: statusParam)
        return cards.map { dto in
            Card(
                id: UUID(uuidString: dto.id) ?? UUID(),
                front: dto.front,
                back: dto.back,
                status: CardStatus(rawValue: dto.status) ?? .new
            )
        }
    }

    func createCard(lexemeId: String) async throws -> Card {
        let dto = try await api.createCard(lexemeId: lexemeId)
        return Card(
            id: UUID(uuidString: dto.id) ?? UUID(),
            front: dto.front,
            back: dto.back,
            status: CardStatus(rawValue: dto.status) ?? .new
        )
    }

    func reviewCard(id: UUID, rating: String) async throws -> Card {
        let dto = try await api.reviewCard(id: id.uuidString, rating: rating)
        return Card(
            id: UUID(uuidString: dto.id) ?? UUID(),
            front: dto.front,
            back: dto.back,
            status: CardStatus(rawValue: dto.status) ?? .new
        )
    }
}

protocol SourcesRepositoryProtocol {
    func loadSources() async throws -> [SourceItem]
    func setEnabled(id: UUID, enabled: Bool) async throws -> SourceItem
    func createSource(handle: String, rssUrl: String) async throws -> SourceItem
    func previewSource(handle: String, rssUrl: String) async throws -> SourcePreviewDTO
    func ingestNow() async throws -> IngestResultDTO
    func editSource(id: UUID, handle: String, rssUrl: String) async throws -> SourceItem
    func deleteSource(id: UUID) async throws
}

final class SourcesRepository: SourcesRepositoryProtocol {
    private let api: APIClientProtocol

    init(api: APIClientProtocol) {
        self.api = api
    }

    func loadSources() async throws -> [SourceItem] {
        let sources = try await api.fetchSources()
        return sources.map {
            SourceItem(
                id: UUID(uuidString: $0.id) ?? UUID(),
                handle: $0.handle,
                enabled: $0.enabled,
                lastSync: $0.lastSyncAt ?? "-",
                rssUrl: $0.rssUrl
            )
        }
    }

    func setEnabled(id: UUID, enabled: Bool) async throws -> SourceItem {
        let dto = try await api.updateSource(id: id.uuidString, enabled: enabled)
        return SourceItem(
            id: UUID(uuidString: dto.id) ?? UUID(),
            handle: dto.handle,
            enabled: dto.enabled,
            lastSync: dto.lastSyncAt ?? "今",
            rssUrl: dto.rssUrl
        )
    }

    func createSource(handle: String, rssUrl: String) async throws -> SourceItem {
        let dto = try await api.createSource(handle: handle.isEmpty ? "rss" : handle, rssUrl: rssUrl)
        return SourceItem(
            id: UUID(uuidString: dto.id) ?? UUID(),
            handle: dto.handle,
            enabled: dto.enabled,
            lastSync: dto.lastSyncAt ?? "-",
            rssUrl: dto.rssUrl
        )
    }

    func previewSource(handle: String, rssUrl: String) async throws -> SourcePreviewDTO {
        try await api.previewSource(handle: handle, rssUrl: rssUrl)
    }

    func ingestNow() async throws -> IngestResultDTO {
        try await api.ingestNow()
    }

    func editSource(id: UUID, handle: String, rssUrl: String) async throws -> SourceItem {
        let dto = try await api.editSource(id: id.uuidString, handle: handle, rssUrl: rssUrl)
        return SourceItem(
            id: UUID(uuidString: dto.id) ?? UUID(),
            handle: dto.handle,
            enabled: dto.enabled,
            lastSync: dto.lastSyncAt ?? "-",
            rssUrl: dto.rssUrl
        )
    }

    func deleteSource(id: UUID) async throws {
        _ = try await api.deleteSource(id: id.uuidString)
    }
}

protocol SettingsRepositoryProtocol {
    func loadSchedule() async throws -> NotificationScheduleDTO
    func updateSchedule(_ schedule: NotificationScheduleDTO) async throws -> NotificationScheduleDTO
    func loadAbbreviations() async throws -> [String]
    func updateAbbreviations(_ abbreviations: [String]) async throws -> [String]
}

final class SettingsRepository: SettingsRepositoryProtocol {
    private let api: APIClientProtocol

    init(api: APIClientProtocol) {
        self.api = api
    }

    func loadSchedule() async throws -> NotificationScheduleDTO {
        try await api.fetchNotificationSchedule()
    }

    func updateSchedule(_ schedule: NotificationScheduleDTO) async throws -> NotificationScheduleDTO {
        try await api.updateNotificationSchedule(schedule)
    }

    func loadAbbreviations() async throws -> [String] {
        try await api.fetchAbbreviations()
    }

    func updateAbbreviations(_ abbreviations: [String]) async throws -> [String] {
        try await api.updateAbbreviations(abbreviations)
    }
}
