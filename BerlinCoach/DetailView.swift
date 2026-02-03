import SwiftUI

struct DetailView: View {
    let sentenceId: String
    @State private var model: DetailViewModel
    @State private var showAnswer = false
    @State private var reviewDone = false
    @State private var cardAdded = false
    @State private var isAddingCard = false
    @State private var cardError: String? = nil

    init(sentenceId: String) {
        self.sentenceId = sentenceId
        _model = State(initialValue: DetailViewModel(sentenceId: sentenceId))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("文")
                        .font(.headline)
                        .foregroundStyle(Theme.textMuted)
                    if model.isLoading && model.sentence.textDe.isEmpty {
                        ProgressView()
                            .tint(Theme.sky)
                    } else {
                        Text(model.sentence.textDe.isEmpty ? "読み込み中..." : model.sentence.textDe)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.text)
                        Text(model.sentence.textJa)
                            .font(.footnote)
                            .foregroundStyle(Theme.textMuted)
                    }
                    if let errorMessage = model.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Theme.amber)
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 8) {
                    Text("キーワード")
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                    if model.sentence.lexemes.isEmpty {
                        Text("キーワードは準備中です。")
                            .font(.footnote)
                            .foregroundStyle(Theme.textDim)
                    } else {
                        ForEach(model.sentence.lexemes) { lex in
                            LexemeCardView(lexeme: lex)
                        }
                    }
                }

                if let first = model.sentence.lexemes.first {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ミニドリル")
                            .font(.headline)
                            .foregroundStyle(Theme.text)
                        Text("Q: der/die/das \(first.textDe)?")
                            .foregroundStyle(Theme.text)
                        if showAnswer {
                            Text("A: \(quizGender(for: first))")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textMuted)
                        }
                        Button(showAnswer ? "答えを隠す" : "答えを見る") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showAnswer.toggle()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.mint)
                    }
                    .cardStyle()
                }

                if let first = model.sentence.lexemes.first {
                    HStack {
                    Button(reviewDone ? "レビュー済み" : "レビュー済みにする") {
                        reviewDone = true
                    }
                    .buttonStyle(.borderedProminent)
                        Button(cardAdded ? "カードに追加済み" : "カードに追加する") {
                            Task {
                                await addCard(lexemeId: first.id)
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(cardAdded || isAddingCard)
                    }
                }
                if let cardError {
                    Text(cardError)
                        .font(.footnote)
                        .foregroundStyle(Theme.amber)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Theme.night.ignoresSafeArea())
        .navigationTitle("文の詳細")
        .task {
            await model.load()
        }
        .onChange(of: model.sentence.id) { _, _ in
            showAnswer = false
            reviewDone = false
            cardAdded = false
            cardError = nil
        }
    }

    private func quizGender(for lexeme: Lexeme) -> String {
        let normalized = lexeme.textDe.lowercased()
        let word = normalized
            .split(separator: " ")
            .last
            .map(String.init) ?? normalized
        if word.hasSuffix("ung")
            || word.hasSuffix("heit")
            || word.hasSuffix("keit")
            || word.hasSuffix("schaft")
            || word.hasSuffix("tion")
            || word.hasSuffix("ität") {
            return "die"
        }
        return lexeme.gender
    }

    @MainActor
    private func addCard(lexemeId: String) async {
        guard !lexemeId.isEmpty else { return }
        isAddingCard = true
        cardError = nil
        defer { isAddingCard = false }
        do {
            let repo = CardsRepository(api: AppEnvironment.apiClient)
            _ = try await repo.createCard(lexemeId: lexemeId)
            cardAdded = true
            NotificationCenter.default.post(name: .cardAdded, object: nil)
        } catch {
            cardError = "カード追加に失敗しました: \(error.localizedDescription)"
        }
    }
}

#if DEBUG
#endif

extension Notification.Name {
    static let cardAdded = Notification.Name("BerlinCoach.CardAdded")
}
struct LexemeCardView: View {
    let lexeme: Lexeme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(lexeme.textDe).bold().foregroundStyle(Theme.text)
            Text(lexeme.meaningJa).foregroundStyle(Theme.text)
            Text("性: \(lexeme.gender) / 語源: \(lexeme.etymology)")
                .font(.footnote)
                .foregroundStyle(Theme.textMuted)
            if let pattern = lexeme.prepositionPattern {
                Text("前置詞: \(pattern)")
                    .font(.footnote)
                    .foregroundStyle(Theme.textMuted)
            }
            if let forms = lexeme.verbForms {
                Text("活用: \(forms)")
                    .font(.footnote)
                    .foregroundStyle(Theme.textMuted)
            } else if looksLikeVerb(lexeme.textDe) {
                Text("活用: （取得中）")
                    .font(.footnote)
                    .foregroundStyle(Theme.textDim)
            }
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func looksLikeVerb(_ text: String) -> Bool {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if t.hasPrefix("sich ") { return true }
        return t.hasSuffix("en")
    }
}

#Preview {
    DetailView(sentenceId: MockData.sentence1Id)
}
