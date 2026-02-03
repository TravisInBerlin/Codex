import SwiftUI

struct DetailView: View {
    let sentenceId: UUID

    private let sentence = (
        textDe: "Die Polizei bittet um Hinweise zu einem Vorfall am Alexanderplatz.",
        textJa: "警察はアレクサンダープラッツの事件に関する情報提供を求めている。"
    )

    private let lexemes: [Lexeme] = [
        Lexeme(
            id: UUID(),
            textDe: "die Polizei",
            meaningJa: "警察",
            gender: "die",
            etymology: "ギリシャ語→ラテン語経由で警察組織を指す語。",
            prepositionPattern: nil,
            verbForms: nil
        ),
        Lexeme(
            id: UUID(),
            textDe: "um Hinweise bitten",
            meaningJa: "情報提供を求める",
            gender: "none",
            etymology: "bitten（頼む）+ um（〜を求めて）。",
            prepositionPattern: "bitten um + Akk.",
            verbForms: "bitten – bat – gebeten"
        )
    ]

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
                    Text("Q: der/die/das Vorfall?")
                    Button("答えを見る") {}
                        .buttonStyle(.borderedProminent)
                }

                HStack {
                    Button("レビュー済みにする") { }
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
                Text("前置詞: \(pattern)")
                    .font(.footnote)
            }
            if let forms = lexeme.verbForms {
                Text("活用: \(forms)")
                    .font(.footnote)
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DetailView(sentenceId: UUID())
}
