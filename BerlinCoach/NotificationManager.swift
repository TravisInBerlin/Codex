import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    private let maxBodyLength = 220

    func requestAuthorization() async {
        do {
            _ = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            // ignore for now
        }
    }

    func scheduleHourlyNotifications(
        sentences: [Sentence],
        startHour: Int,
        endHour: Int,
        maxSentences: Int
    ) async {
        await scheduleIntervalNotifications(
            sentences: sentences,
            startHour: startHour,
            startMinute: 0,
            endHour: endHour,
            endMinute: 0,
            intervalMinutes: 60,
            maxSentences: maxSentences
        )
    }

    func scheduleIntervalNotifications(
        sentences: [Sentence],
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        intervalMinutes: Int,
        maxSentences: Int
    ) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        guard !sentences.isEmpty else { return }

        let calendar = Calendar.current
        let now = Date()
        var startDate = calendar.date(
            bySettingHour: startHour,
            minute: startMinute,
            second: 0,
            of: now
        ) ?? now

        var endDate = calendar.date(
            bySettingHour: endHour,
            minute: endMinute,
            second: 0,
            of: now
        ) ?? now

        if endDate <= startDate {
            endDate = calendar.date(byAdding: .day, value: 1, to: endDate) ?? endDate
        }

        if startDate < now {
            while startDate < now {
                startDate = calendar.date(byAdding: .minute, value: intervalMinutes, to: startDate) ?? startDate
            }
        }

        let maxNotifications = 64
        var scheduled = 0
        var index = 0
        var date = startDate
        while date <= endDate && scheduled < maxNotifications {
            let slice = sliceSentences(sentences, index: index, maxSentences: maxSentences)
            let body = slice.map { sentence in
                "\(sentence.textDe)\nJP: \(sentence.textJa)"
            }.joined(separator: "\n")

            let trimmedBody = trim(body)
            let firstSentenceId = slice.first?.id ?? ""

            let content = UNMutableNotificationContent()
            content.title = "今日のベルリン"
            content.body = trimmedBody
            content.sound = .default
            content.userInfo = ["sentenceId": firstSentenceId]

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let request = UNNotificationRequest(
                identifier: "berlincoach_\(components.year ?? 0)_\(components.hour ?? 0)_\(components.minute ?? 0)_\(scheduled)",
                content: content,
                trigger: trigger
            )

            try? await center.add(request)

            date = calendar.date(byAdding: .minute, value: intervalMinutes, to: date) ?? date
            scheduled += 1
            index += 1
        }
    }

    private func sliceSentences(_ sentences: [Sentence], index: Int, maxSentences: Int) -> [Sentence] {
        let count = max(1, min(maxSentences, 2))
        let start = (index * count) % sentences.count
        let end = min(start + count, sentences.count)
        if start < end {
            return Array(sentences[start..<end])
        }
        return [sentences[start % sentences.count]]
    }

    private func trim(_ text: String) -> String {
        guard text.count > maxBodyLength else { return text }
        let idx = text.index(text.startIndex, offsetBy: maxBodyLength)
        return String(text[..<idx]) + "…"
    }
}
