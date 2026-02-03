import Foundation

enum MockData {
    static let sentence1Id = UUID().uuidString
    static let sentence2Id = UUID().uuidString

    static let sentences: [Sentence] = [
        Sentence(
            id: sentence1Id,
            textDe: "Die Polizei bittet um Hinweise zu einem Vorfall am Alexanderplatz.",
            textJa: "警察はアレクサンダープラッツの事件に関する情報提供を求めている。",
            lexemes: [
                Lexeme(
                    id: UUID().uuidString,
                    textDe: "die Polizei",
                    meaningJa: "警察",
                    gender: "die",
                    etymology: "ギリシャ語→ラテン語経由で警察組織を指す語。",
                    prepositionPattern: nil,
                    verbForms: nil
                ),
                Lexeme(
                    id: UUID().uuidString,
                    textDe: "um Hinweise bitten",
                    meaningJa: "情報提供を求める",
                    gender: "none",
                    etymology: "bitten（頼む）+ um（〜を求めて）。",
                    prepositionPattern: "bitten um + Akk.",
                    verbForms: "bitten – bat – gebeten"
                )
            ]
        ),
        Sentence(
            id: sentence2Id,
            textDe: "Die BVG meldet eine Sperrung auf der U2.",
            textJa: "BVGはU2の運休を報告。",
            lexemes: [
                Lexeme(
                    id: UUID().uuidString,
                    textDe: "die Sperrung",
                    meaningJa: "封鎖・運休",
                    gender: "die",
                    etymology: "sperren（閉じる）由来。",
                    prepositionPattern: nil,
                    verbForms: nil
                ),
                Lexeme(
                    id: UUID().uuidString,
                    textDe: "auf der U2",
                    meaningJa: "U2線で",
                    gender: "none",
                    etymology: "路線名は交通系の固有名詞。",
                    prepositionPattern: "auf + Dat.",
                    verbForms: nil
                )
            ]
        )
    ]

    static let feedItems: [FeedItem] = [
        FeedItem(
            id: UUID(),
            sentenceId: sentence1Id,
            headline: "Heute in Berlin:",
            textDe: sentences[0].textDe,
            textJa: sentences[0].textJa,
            tags: ["police", "events"]
        ),
        FeedItem(
            id: UUID(),
            sentenceId: sentence2Id,
            headline: "Berlin Update:",
            textDe: sentences[1].textDe,
            textJa: sentences[1].textJa,
            tags: ["transport"]
        )
    ]

    static let cards: [Card] = [
        Card(
            id: UUID(),
            front: "der Verdächtige",
            back: "意味: 容疑者 / 性: der / 語源: verdächtigen（疑う）由来",
            status: .due
        ),
        Card(
            id: UUID(),
            front: "die Sperrung",
            back: "意味: 封鎖・運休 / 性: die / 語源: sperren（閉じる）",
            status: .new
        )
    ]

    static let sources: [SourceItem] = [
        SourceItem(id: UUID(), handle: "polizeiberlin", enabled: true, lastSync: "10分前", rssUrl: nil),
        SourceItem(id: UUID(), handle: "berlinerzeitung", enabled: true, lastSync: "40分前", rssUrl: nil),
        SourceItem(id: UUID(), handle: "BVG", enabled: false, lastSync: "-", rssUrl: nil)
    ]

    static func sentence(for id: String) -> Sentence? {
        sentences.first { $0.id == id }
    }
}
