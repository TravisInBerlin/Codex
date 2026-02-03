import SwiftUI

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

            VStack(spacing: 12) {
                Text("der Verdächtige")
                    .font(.title2)
                Text("Tap to flip")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(28)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            HStack {
                Button("もう一回") { }
                    .buttonStyle(.bordered)
                Button("あいまい") { }
                    .buttonStyle(.bordered)
                Button("覚えた") { }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .navigationTitle("単語カード")
    }
}

#Preview {
    CardsView()
}
