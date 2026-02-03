# SwiftUI Mockups (Design Applied)

Goal: Apply the design system to key screens with realistic component styling.

---

## Theme Helpers

```swift
import SwiftUI

struct Theme {
    static let night = Color(hex: "0F1220")
    static let deep = Color(hex: "141A2B")
    static let surface = Color(hex: "1B2340")
    static let card = Color(hex: "1F294A")
    static let mint = Color(hex: "4DE3B2")
    static let sky = Color(hex: "6CB7FF")
    static let amber = Color(hex: "F7B267")
    static let text = Color(hex: "EEF2FF")
    static let textMuted = Color(hex: "B7C0DD")
    static let textDim = Color(hex: "8A93B7")
}

extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}
```

---

## Feed Mock

```swift
struct FeedMockView: View {
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Berlin Learning Feed")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(Theme.text)
                            Text("今日のベルリン：9:00–21:00 毎時")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textMuted)
                        }
                        .padding(.top, 8)

                        FeedCardMock(
                            title: "Heute in Berlin:",
                            de: "Die Polizei bittet um Hinweise zu einem Vorfall am Alexanderplatz.",
                            ja: "警察はアレクサンダープラッツの事件に関する情報提供を求めている。",
                            tags: ["police", "events"]
                        )

                        FeedCardMock(
                            title: "Berlin Update:",
                            de: "Die BVG meldet eine Sperrung auf der U2.",
                            ja: "BVGはU2の運休を報告。",
                            tags: ["transport"]
                        )
                    }
                    .padding()
                }
                .background(Theme.night)

                Button {
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(18)
                        .background(Theme.sky)
                        .clipShape(Circle())
                        .shadow(radius: 8)
                }
                .padding()
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Feed")
                        .foregroundStyle(Theme.text)
                }
            }
        }
    }
}

struct FeedCardMock: View {
    let title: String
    let de: String
    let ja: String
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).foregroundStyle(Theme.sky)
            Text(de).foregroundStyle(Theme.text)
            Text("JP: \(ja)").font(.footnote).foregroundStyle(Theme.textMuted)
            HStack {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.surface)
                        .clipShape(Capsule())
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
        .cardStyle()
    }
}
```

---

## Detail Mock

```swift
struct DetailMockView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("文")
                        .font(.headline)
                        .foregroundStyle(Theme.textMuted)
                    Text("Die Polizei bittet um Hinweise zu einem Vorfall am Alexanderplatz.")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.text)
                    Text("警察はアレクサンダープラッツの事件に関する情報提供を求めている。")
                        .font(.footnote)
                        .foregroundStyle(Theme.textMuted)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 10) {
                    Text("キーワード")
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                    LexemeMock(title: "die Polizei", detail: "性: die  / 語源: ギリシャ語→ラテン語")
                    LexemeMock(title: "um Hinweise bitten", detail: "前置詞: bitten um + Akk. / 活用: bitten – bat – gebeten")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("ミニドリル")
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                    Text("Q: der/die/das Vorfall?")
                        .foregroundStyle(Theme.text)
                    Button("答えを見る") {}
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.mint)
                }
                .cardStyle()
            }
            .padding()
        }
        .background(Theme.night)
        .navigationTitle("文の詳細")
    }
}

struct LexemeMock: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).bold().foregroundStyle(Theme.text)
            Text(detail).font(.footnote).foregroundStyle(Theme.textMuted)
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

---

## Cards Mock

```swift
struct CardsMockView: View {
    var body: some View {
        VStack(spacing: 16) {
            Picker("", selection: .constant(0)) {
                Text("今日の復習").tag(0)
                Text("新着").tag(1)
                Text("苦手").tag(2)
                Text("すべて").tag(3)
            }
            .pickerStyle(.segmented)

            VStack(spacing: 12) {
                Text("der Verdächtige")
                    .font(.title2)
                    .foregroundStyle(Theme.text)
                Text("Tap to flip")
                    .font(.caption)
                    .foregroundStyle(Theme.textDim)
            }
            .frame(maxWidth: .infinity)
            .padding(28)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            HStack {
                Button("もう一回") {}
                    .buttonStyle(.bordered)
                Button("あいまい") {}
                    .buttonStyle(.bordered)
                Button("覚えた") {}
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.sky)
            }
        }
        .padding()
        .background(Theme.night)
        .navigationTitle("単語カード")
    }
}
```

---

## Sources Mock

```swift
struct SourcesMockView: View {
    var body: some View {
        List {
            SourceRow(handle: "polizeiberlin", enabled: true, lastSync: "10分前")
            SourceRow(handle: "berlinerzeitung", enabled: true, lastSync: "40分前")
            SourceRow(handle: "BVG", enabled: false, lastSync: "-")
        }
        .scrollContentBackground(.hidden)
        .background(Theme.night)
        .navigationTitle("取得ソース")
    }
}

struct SourceRow: View {
    let handle: String
    let enabled: Bool
    let lastSync: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("@\(handle)")
                    .foregroundStyle(Theme.text)
                Text("最終更新: \(lastSync)")
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }
            Spacer()
            Toggle("", isOn: .constant(enabled)).labelsHidden()
        }
        .listRowBackground(Theme.surface)
    }
}
```

---

## Settings Mock

```swift
struct SettingsMockView: View {
    var body: some View {
        Form {
            Section("通知") {
                Toggle("通知を有効にする", isOn: .constant(true))
                Stepper("開始: 9時", value: .constant(9), in: 6...12)
                Stepper("終了: 21時", value: .constant(21), in: 18...23)
                Stepper("文数: 最大2文", value: .constant(2), in: 1...2)
            }

            Section("学習") {
                Text("必須: 意味 / 性 / 語源")
                Text("追加: 再帰動詞 / 前置詞セット / 過去形・過去分詞")
            }
        }
        .navigationTitle("設定")
    }
}
```
