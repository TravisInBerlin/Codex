import SwiftUI

struct FeedView: View {
    @State private var showInputSheet = false

    private let feedItems: [FeedItem] = [
        FeedItem(
            id: UUID(),
            headline: "Heute in Berlin:",
            textDe: "Die Polizei bittet um Hinweise zu einem Vorfall am Alexanderplatz.",
            textJa: "警察はアレクサンダープラッツの事件に関する情報提供を求めている。",
            tags: ["police", "events"]
        ),
        FeedItem(
            id: UUID(),
            headline: "Berlin Update:",
            textDe: "Die BVG meldet eine Sperrung auf der U2.",
            textJa: "BVGはU2の運休を報告。",
            tags: ["transport"]
        )
    ]

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

#Preview {
    FeedView()
}
