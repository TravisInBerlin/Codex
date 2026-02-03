import Foundation

protocol APIClientProtocol {
    func fetchSentences() async throws -> [SentenceDTO]
    func fetchSentenceDetail(id: String) async throws -> SentenceDetailDTO
    func fetchSources() async throws -> [SourceDTO]
    func updateSource(id: String, enabled: Bool) async throws -> SourceDTO
    func editSource(id: String, handle: String, rssUrl: String) async throws -> SourceDTO
    func createSource(handle: String, rssUrl: String) async throws -> SourceDTO
    func previewSource(handle: String, rssUrl: String) async throws -> SourcePreviewDTO
    func ingestNow() async throws -> IngestResultDTO
    func deleteSource(id: String) async throws -> Bool
    func fetchCards(status: String?) async throws -> [CardDTO]
    func createCard(lexemeId: String) async throws -> CardDTO
    func reviewCard(id: String, rating: String) async throws -> CardDTO
    func fetchNotificationSchedule() async throws -> NotificationScheduleDTO
    func updateNotificationSchedule(_ schedule: NotificationScheduleDTO) async throws -> NotificationScheduleDTO
    func fetchAbbreviations() async throws -> [String]
    func updateAbbreviations(_ abbreviations: [String]) async throws -> [String]
}

final class APIClient: APIClientProtocol {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchSentences() async throws -> [SentenceDTO] {
        try await request("/sentences")
    }

    func fetchSentenceDetail(id: String) async throws -> SentenceDetailDTO {
        try await request("/sentences/\(id)")
    }

    func fetchSources() async throws -> [SourceDTO] {
        try await request("/sources")
    }

    func updateSource(id: String, enabled: Bool) async throws -> SourceDTO {
        let body = try JSONEncoder().encode(["enabled": enabled])
        return try await request("/sources/\(id)", method: "PATCH", body: body)
    }

    func editSource(id: String, handle: String, rssUrl: String) async throws -> SourceDTO {
        let body = try JSONEncoder().encode([
            "handle": handle,
            "rssUrl": rssUrl
        ])
        return try await request("/sources/\(id)", method: "PATCH", body: body)
    }

    func createSource(handle: String, rssUrl: String) async throws -> SourceDTO {
        let body = try JSONEncoder().encode([
            "handle": handle,
            "type": "rss",
            "rssUrl": rssUrl
        ])
        return try await request("/sources", method: "POST", body: body)
    }

    func previewSource(handle: String, rssUrl: String) async throws -> SourcePreviewDTO {
        let body = try JSONEncoder().encode([
            "handle": handle,
            "type": "rss",
            "rssUrl": rssUrl
        ])
        return try await request("/sources/preview", method: "POST", body: body)
    }

    func ingestNow() async throws -> IngestResultDTO {
        try await request("/ingest/auto", method: "POST")
    }

    func deleteSource(id: String) async throws -> Bool {
        struct Response: Decodable { let deleted: Bool }
        let res: Response = try await request("/sources/\(id)", method: "DELETE")
        return res.deleted
    }

    func fetchCards(status: String?) async throws -> [CardDTO] {
        var path = "/cards"
        if let status {
            path += "?status=\(status)"
        }
        return try await request(path)
    }

    func createCard(lexemeId: String) async throws -> CardDTO {
        let body = try JSONEncoder().encode(["lexemeId": lexemeId])
        return try await request("/cards", method: "POST", body: body)
    }

    func reviewCard(id: String, rating: String) async throws -> CardDTO {
        let body = try JSONEncoder().encode(["rating": rating])
        return try await request("/cards/\(id)/review", method: "POST", body: body)
    }

    func fetchNotificationSchedule() async throws -> NotificationScheduleDTO {
        try await request("/notifications/schedule")
    }

    func updateNotificationSchedule(_ schedule: NotificationScheduleDTO) async throws -> NotificationScheduleDTO {
        let body = try JSONEncoder().encode(schedule)
        return try await request("/notifications/schedule", method: "PATCH", body: body)
    }

    func fetchAbbreviations() async throws -> [String] {
        struct Response: Decodable { let abbreviations: [String] }
        let res: Response = try await request("/settings/abbreviations")
        return res.abbreviations
    }

    func updateAbbreviations(_ abbreviations: [String]) async throws -> [String] {
        struct Body: Encodable { let abbreviations: [String] }
        struct Response: Decodable { let abbreviations: [String] }
        let body = try JSONEncoder().encode(Body(abbreviations: abbreviations))
        let res: Response = try await request("/settings/abbreviations", method: "PUT", body: body)
        return res.abbreviations
    }

    private func request<T: Decodable>(_ path: String, method: String = "GET", body: Data? = nil) async throws -> T {
        let trimmedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = URL(string: trimmedPath, relativeTo: baseURL) ?? baseURL.appendingPathComponent(trimmedPath)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        #if DEBUG
        print("API Request:", request.url?.absoluteString ?? "")
        #endif
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

final class MockAPIClient: APIClientProtocol {
    func fetchSentences() async throws -> [SentenceDTO] {
        MockData.sentences.map {
            SentenceDTO(
                id: $0.id,
                textDe: $0.textDe,
                textJa: $0.textJa,
                tags: []
            )
        }
    }

    func fetchSentenceDetail(id: String) async throws -> SentenceDetailDTO {
        let sentence = MockData.sentences.first { $0.id == id } ?? MockData.sentences[0]
        let dto = SentenceDTO(id: sentence.id, textDe: sentence.textDe, textJa: sentence.textJa, tags: [])
        let lexemes = sentence.lexemes.map {
            LexemeDTO(
                id: $0.id,
                textDe: $0.textDe,
                meaningJa: $0.meaningJa,
                gender: $0.gender,
                etymology: $0.etymology,
                prepositionPattern: $0.prepositionPattern,
                verbForms: $0.verbForms
            )
        }
        return SentenceDetailDTO(sentence: dto, lexemes: lexemes)
    }

    func fetchSources() async throws -> [SourceDTO] {
        MockData.sources.map {
            SourceDTO(
                id: $0.id.uuidString,
                handle: $0.handle,
                enabled: $0.enabled,
                lastSyncAt: $0.lastSync,
                type: "rss",
                rssUrl: nil
            )
        }
    }

    func updateSource(id: String, enabled: Bool) async throws -> SourceDTO {
        SourceDTO(id: id, handle: "updated", enabled: enabled, lastSyncAt: "今", type: "rss", rssUrl: nil)
    }

    func editSource(id: String, handle: String, rssUrl: String) async throws -> SourceDTO {
        SourceDTO(id: id, handle: handle, enabled: true, lastSyncAt: "今", type: "rss", rssUrl: rssUrl)
    }

    func createSource(handle: String, rssUrl: String) async throws -> SourceDTO {
        SourceDTO(id: UUID().uuidString, handle: handle, enabled: true, lastSyncAt: "今", type: "rss", rssUrl: rssUrl)
    }

    func previewSource(handle: String, rssUrl: String) async throws -> SourcePreviewDTO {
        SourcePreviewDTO(ok: true, title: "Mock RSS", items: ["Preview item 1", "Preview item 2"])
    }

    func ingestNow() async throws -> IngestResultDTO {
        IngestResultDTO(fetched: 0, stored: 0, errors: [])
    }

    func deleteSource(id: String) async throws -> Bool {
        true
    }

    func fetchCards(status: String?) async throws -> [CardDTO] {
        MockData.cards.map {
            CardDTO(id: $0.id.uuidString, front: $0.front, back: $0.back, status: $0.status.rawValue, dueAt: nil)
        }
    }

    func createCard(lexemeId: String) async throws -> CardDTO {
        CardDTO(id: lexemeId, front: "", back: "", status: "new", dueAt: nil)
    }

    func reviewCard(id: String, rating: String) async throws -> CardDTO {
        CardDTO(id: id, front: "", back: "", status: rating, dueAt: nil)
    }

    func fetchNotificationSchedule() async throws -> NotificationScheduleDTO {
        NotificationScheduleDTO(
            active: true,
            startHour: 9,
            startMinute: 0,
            endHour: 21,
            endMinute: 0,
            maxSentences: 2,
            intervalMinutes: 60
        )
    }

    func updateNotificationSchedule(_ schedule: NotificationScheduleDTO) async throws -> NotificationScheduleDTO {
        schedule
    }

    func fetchAbbreviations() async throws -> [String] {
        []
    }

    func updateAbbreviations(_ abbreviations: [String]) async throws -> [String] {
        abbreviations
    }
}
