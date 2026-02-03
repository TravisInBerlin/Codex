# SwiftUI Screen Design (MVP)

Goal: Provide implementation-level layout for the four main tabs and key flows.

---

## App Shell

```swift
struct RootView: View {
    var body: some View {
        TabView {
            FeedView()
                .tabItem { Label("Feed", systemImage: "newspaper") }
            CardsView()
                .tabItem { Label("Cards", systemImage: "rectangle.stack") }
            SourcesView()
                .tabItem { Label("Sources", systemImage: "list.bullet") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
```

---

## 1) FeedView

UI
- Header: title + subtitle (9:00–21:00)
- List of sentence cards
- Floating action button: paste / add link

```swift
struct FeedView: View {
    @State private var showInputSheet = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    Section {
                        ForEach(feedItems) { item in
                            NavigationLink(value: item.id) {
                                FeedCardView(item: item)
                            }
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Berlin Learning Feed")
                                .font(.title2).bold()
                            Text("今日のベルリン：9:00–21:00 毎時")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }

                Button {
                    showInputSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .padding(18)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                        .shadow(radius: 6)
                }
                .padding()
            }
            .navigationDestination(for: UUID.self) { id in
                DetailView(sentenceId: id)
            }
            .sheet(isPresented: $showInputSheet) {
                InputSheetView()
            }
        }
    }
}
```

FeedCardView
```swift
struct FeedCardView: View {
    let item: FeedItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.headline)
                .font(.headline)
            Text(item.textDe)
                .font(.body)
            Text("JP: \(item.textJa)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                ForEach(item.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 8)
    }
}
```

---

## 2) DetailView

UI
- Sentence (DE + JA)
- Explanation blocks
- Key lexemes
- Actions: reviewed / auto-added
- Mini drill

```swift
struct DetailView: View {
    let sentenceId: UUID

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("文")
                        .font(.headline)
                    Text(sentence.textDe)
                        .font(.title3)
                    Text(sentence.textJa)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("キーワード")
                        .font(.headline)
                    ForEach(lexemes) { lex in
                        LexemeCardView(lexeme: lex)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("ミニドリル")
                        .font(.headline)
                    MiniDrillView(lexeme: quizLexeme)
                }

                HStack {
                    Button("レビュー済みにする") { /* save */ }
                        .buttonStyle(.borderedProminent)
                    Button("カードに追加済み") { }
                        .buttonStyle(.bordered)
                        .disabled(true)
                }
            }
            .padding()
        }
        .navigationTitle("文の詳細")
    }
}
```

LexemeCardView
```swift
struct LexemeCardView: View {
    let lexeme: Lexeme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(lexeme.textDe).bold()
            Text(lexeme.meaningJa)
            Text("性: \(lexeme.gender) / 語源: \(lexeme.etymology)")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if let pattern = lexeme.prepositionPattern {
                Text("前置詞: \(pattern)").font(.footnote)
            }
            if let forms = lexeme.verbForms {
                Text("活用: \(forms)").font(.footnote)
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

---

## 3) CardsView

UI
- Filter chips
- Swipe/flip style card
- Review buttons

```swift
struct CardsView: View {
    @State private var filter: CardFilter = .due

    var body: some View {
        VStack(spacing: 16) {
            Picker("", selection: $filter) {
                Text("今日の復習").tag(CardFilter.due)
                Text("新着").tag(CardFilter.new)
                Text("苦手").tag(CardFilter.difficult)
                Text("すべて").tag(CardFilter.all)
            }
            .pickerStyle(.segmented)

            FlashCardView(card: currentCard)

            HStack {
                Button("もう一回") { /* review */ }
                    .buttonStyle(.bordered)
                Button("あいまい") { /* review */ }
                    .buttonStyle(.bordered)
                Button("覚えた") { /* review */ }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .navigationTitle("単語カード")
    }
}
```

---

## 4) SourcesView

UI
- List with toggles
- Add source sheet
- Drag to reorder

```swift
struct SourcesView: View {
    @State private var showAdd = false

    var body: some View {
        List {
            ForEach(sources) { source in
                HStack {
                    Text("@\(source.handle)")
                    Spacer()
                    Toggle("", isOn: binding(for: source))
                        .labelsHidden()
                }
            }
            .onMove { from, to in
                // reorder
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showAdd) {
            AddSourceView()
        }
        .navigationTitle("取得ソース")
    }
}
```

---

## 5) SettingsView

UI
- Notification schedule
- Learning fields

```swift
struct SettingsView: View {
    @State private var notificationsOn = true
    @State private var startHour = 9
    @State private var endHour = 21
    @State private var maxSentences = 2

    var body: some View {
        Form {
            Section("通知") {
                Toggle("通知を有効にする", isOn: $notificationsOn)
                Stepper("開始: \(startHour)時", value: $startHour, in: 6...12)
                Stepper("終了: \(endHour)時", value: $endHour, in: 18...23)
                Stepper("文数: 最大\(maxSentences)文", value: $maxSentences, in: 1...2)
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

---

## Notes
- All code is layout-level and can be wired to data later.
- `feedItems`, `sentence`, `lexemes`, etc. are placeholders.
- Use `NavigationStack` for modern iOS nav.
