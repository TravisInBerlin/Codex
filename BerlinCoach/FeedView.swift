import SwiftUI

struct FeedView: View {
    @State private var showInputSheet = false
    @State private var model = FeedViewModel()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Theme.night.ignoresSafeArea()

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
                    .padding(.top, 2)

                    if model.isLoading {
                        ProgressView()
                            .tint(Theme.sky)
                    }

                    if let errorMessage = model.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Theme.amber)
                    }

                    ForEach(model.items) { item in
                        NavigationLink(value: item.sentenceId) {
                            FeedCardView(item: item)
                        }
                        .buttonStyle(.plain)
                    }

                    if !model.isLoading && model.items.isEmpty {
                        Text("まだデータがありません。")
                            .font(.footnote)
                            .foregroundStyle(Theme.textDim)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 90)
            }
            .refreshable {
                await model.load()
            }

            Button {
                showInputSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(18)
                    .background(Theme.sky)
                    .clipShape(Circle())
                    .shadow(radius: 8)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 120)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(isPresented: $showInputSheet) {
            InputSheetView()
        }
        .task {
            await model.load()
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct FeedCardView: View {
    let item: FeedItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.headline)
                .font(.headline)
                .foregroundStyle(Theme.sky)
            Text(item.textDe)
                .font(.body)
                .foregroundStyle(Theme.text)
            Text("JP: \(item.textJa)")
                .font(.footnote)
                .foregroundStyle(Theme.textMuted)
            HStack {
                ForEach(item.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.surface)
                        .clipShape(Capsule())
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
        .cardStyle()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    FeedView()
}
