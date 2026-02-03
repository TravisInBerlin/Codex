import Foundation
import Observation

@Observable
final class FeedViewModel {
    private let repo: FeedRepositoryProtocol
    var items: [FeedItem] = []
    var isLoading = false
    var errorMessage: String? = nil

    init(repo: FeedRepositoryProtocol = FeedRepository(api: AppEnvironment.apiClient)) {
        self.repo = repo
        self.items = AppEnvironment.useMockApi ? MockData.feedItems : []
    }

    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            items = try await repo.loadFeedItems()
        } catch {
            if let urlError = error as? URLError, urlError.code == .cancelled {
                return
            }
            errorMessage = "更新できませんでした: \(error.localizedDescription)"
        }
    }
}

@Observable
final class DetailViewModel {
    let sentenceId: String
    private let repo: SentenceRepositoryProtocol
    var sentence: Sentence
    var isLoading = false
    var errorMessage: String? = nil

    init(sentenceId: String, repo: SentenceRepositoryProtocol = SentenceRepository(api: AppEnvironment.apiClient)) {
        self.sentenceId = sentenceId
        self.repo = repo
        if AppEnvironment.useMockApi {
            self.sentence = MockData.sentence(for: sentenceId) ?? MockData.sentences.first!
        } else {
            self.sentence = Sentence.placeholder(id: sentenceId)
        }
    }

    @MainActor
    func load() async {
        do {
            isLoading = true
            errorMessage = nil
            sentence = try await repo.loadDetail(id: sentenceId)
        } catch {
            if AppEnvironment.useMockApi {
                sentence = MockData.sentence(for: sentenceId) ?? MockData.sentences.first!
            }
            errorMessage = "読み込みに失敗しました: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

@Observable
final class CardsViewModel {
    private let repo: CardsRepositoryProtocol
    var cards: [Card] = []
    var session: [Card] = []
    var filter: CardFilter = .all
    var isLoading = false
    var currentIndex = 0
    var errorMessage: String? = nil

    init(repo: CardsRepositoryProtocol = CardsRepository(api: AppEnvironment.apiClient)) {
        self.repo = repo
        self.cards = AppEnvironment.useMockApi ? MockData.cards : []
    }

    var currentCard: Card? {
        guard !session.isEmpty else { return nil }
        if currentIndex >= session.count {
            currentIndex = 0
        }
        return session[currentIndex]
    }

    var totalCount: Int {
        session.count
    }

    var currentNumber: Int {
        guard totalCount > 0 else { return 0 }
        return min(currentIndex + 1, totalCount)
    }

    var upcomingCards: [Card] {
        guard !session.isEmpty else { return [] }
        let start = min(currentIndex, session.count - 1)
        return Array(session[start..<session.count].prefix(6))
    }

    var filteredCards: [Card] {
        switch filter {
        case .due:
            return cards.filter { $0.status == .due }
        case .new:
            return cards.filter { $0.status == .new }
        case .difficult:
            return cards.filter { $0.status == .difficult }
        case .all:
            return cards
        }
    }

    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            cards = try await repo.loadCards(status: filter)
            rebuildSession()
        } catch {
            if AppEnvironment.useMockApi {
                cards = MockData.cards
            }
            errorMessage = "カード読み込みに失敗しました: \(error.localizedDescription)"
            if session.isEmpty {
                rebuildSession()
            }
        }
    }

    @MainActor
    func reviewCurrent(rating: String) async {
        guard let current = currentCard else { return }
        let mapped: String
        switch rating {
        case "again":
            mapped = "due"
        case "unsure":
            mapped = "difficult"
        case "know":
            mapped = "learned"
        default:
            mapped = rating
        }
        do {
            _ = try await repo.reviewCard(id: current.id, rating: mapped)
        } catch {
            // keep local state
        }
        applyLocalUpdate(cardId: current.id, status: mapped)
        removeFromSession(cardId: current.id)
    }

    @MainActor
    func moveNext() {
        guard !session.isEmpty else { return }
        if currentIndex + 1 < session.count {
            currentIndex += 1
        }
    }

    @MainActor
    func movePrev() {
        guard !session.isEmpty else { return }
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }

    @MainActor
    func rebuildSession() {
        session = filteredCards
        currentIndex = 0
    }

    @MainActor
    private func removeFromSession(cardId: UUID) {
        if let index = session.firstIndex(where: { $0.id == cardId }) {
            session.remove(at: index)
            if currentIndex >= session.count {
                currentIndex = max(session.count - 1, 0)
            }
        }
    }

    @MainActor
    private func applyLocalUpdate(cardId: UUID, status: String) {
        guard let index = cards.firstIndex(where: { $0.id == cardId }) else { return }
        let updated = Card(
            id: cards[index].id,
            front: cards[index].front,
            back: cards[index].back,
            status: CardStatus(rawValue: status) ?? cards[index].status
        )
        cards[index] = updated
    }
}

@Observable
final class SourcesViewModel {
    private let repo: SourcesRepositoryProtocol
    var sources: [SourceItem] = []
    var isLoading = false
    var errorMessage: String? = nil
    var preview: SourcePreviewDTO? = nil
    var isPreviewing = false

    init(repo: SourcesRepositoryProtocol = SourcesRepository(api: AppEnvironment.apiClient)) {
        self.repo = repo
        self.sources = AppEnvironment.useMockApi ? MockData.sources : []
    }

    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            sources = try await repo.loadSources()
        } catch {
            if AppEnvironment.useMockApi {
                sources = MockData.sources
            }
            errorMessage = "ソース取得に失敗しました: \(error.localizedDescription)"
        }
    }

    @MainActor
    func toggle(id: UUID, enabled: Bool) async {
        do {
            let updated = try await repo.setEnabled(id: id, enabled: enabled)
            if let index = sources.firstIndex(where: { $0.id == id }) {
                sources[index] = updated
            }
        } catch {
            // keep local state if update fails
        }
    }

    @MainActor
    func addSource(handle: String, rssUrl: String) async {
        do {
            let created = try await repo.createSource(handle: handle, rssUrl: rssUrl)
            sources.insert(created, at: 0)
        } catch {
            errorMessage = "ソース追加に失敗しました: \(error.localizedDescription)"
        }
    }

    @MainActor
    func previewSource(handle: String, rssUrl: String) async {
        isPreviewing = true
        errorMessage = nil
        defer { isPreviewing = false }
        do {
            preview = try await repo.previewSource(handle: handle, rssUrl: rssUrl)
        } catch {
            preview = nil
            errorMessage = "プレビュー取得に失敗しました: \(error.localizedDescription)"
        }
    }

    @MainActor
    func ingestNow() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let res = try await repo.ingestNow()
            if !res.errors.isEmpty {
                errorMessage = "取得に失敗したソースがあります"
            }
            await load()
        } catch {
            errorMessage = "取得に失敗しました: \(error.localizedDescription)"
        }
    }

    @MainActor
    func editSource(id: UUID, handle: String, rssUrl: String) async {
        do {
            let updated = try await repo.editSource(id: id, handle: handle, rssUrl: rssUrl)
            if let index = sources.firstIndex(where: { $0.id == id }) {
                sources[index] = updated
            }
        } catch {
            errorMessage = "ソース更新に失敗しました: \(error.localizedDescription)"
        }
    }

    @MainActor
    func deleteSource(id: UUID) async {
        do {
            try await repo.deleteSource(id: id)
            sources.removeAll { $0.id == id }
        } catch {
            errorMessage = "ソース削除に失敗しました: \(error.localizedDescription)"
        }
    }
}

@Observable
final class SettingsViewModel {
    private let repo: SettingsRepositoryProtocol
    var notificationsOn = true
    var startHour = 9
    var startMinute = 0
    var endHour = 21
    var endMinute = 0
    var intervalMinutes = 60
    var maxSentences = 2
    var abbreviations: [String] = []

    init(repo: SettingsRepositoryProtocol = SettingsRepository(api: AppEnvironment.apiClient)) {
        self.repo = repo
    }

    @MainActor
    func load() async {
        do {
            let schedule = try await repo.loadSchedule()
            notificationsOn = schedule.active
            startHour = schedule.startHour
            startMinute = schedule.startMinute
            endHour = schedule.endHour
            endMinute = schedule.endMinute
            maxSentences = schedule.maxSentences
            intervalMinutes = schedule.intervalMinutes
            abbreviations = try await repo.loadAbbreviations()
        } catch {
            // keep defaults
        }
    }

    @MainActor
    func save() async {
        let schedule = NotificationScheduleDTO(
            active: notificationsOn,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            maxSentences: maxSentences,
            intervalMinutes: intervalMinutes
        )
        _ = try? await repo.updateSchedule(schedule)

        guard notificationsOn else { return }
        await NotificationManager.shared.requestAuthorization()
        let sentenceRepo = SentenceRepository(api: AppEnvironment.apiClient)
        var freshSentences: [Sentence] = []
        do {
            let feedRepo = FeedRepository(api: AppEnvironment.apiClient)
            let feedItems = try await feedRepo.loadFeedItems()
            for item in feedItems.prefix(10) {
                let detail = try await sentenceRepo.loadDetail(id: item.sentenceId)
                freshSentences.append(detail)
            }
        } catch {
            if AppEnvironment.useMockApi {
                freshSentences = MockData.sentences
            }
        }
        await NotificationManager.shared.scheduleIntervalNotifications(
            sentences: freshSentences.isEmpty ? (AppEnvironment.useMockApi ? MockData.sentences : []) : freshSentences,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            intervalMinutes: max(1, intervalMinutes),
            maxSentences: maxSentences
        )
    }

    @MainActor
    func saveAbbreviations() async {
        _ = try? await repo.updateAbbreviations(abbreviations)
    }
}
