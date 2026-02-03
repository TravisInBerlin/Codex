import SwiftUI

struct CardsView: View {
    @State private var model = CardsViewModel()
    @State private var showBack = false
    @State private var dragOffset: CGFloat = 0
    @State private var isSwiping = false
    @State private var cardHeight: CGFloat = 260
    @State private var transitionDirection: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            CardsScreen(
                model: $model,
                showBack: $showBack,
                dragOffset: $dragOffset,
                isSwiping: $isSwiping,
                cardHeight: $cardHeight,
                transitionDirection: $transitionDirection,
                geoSize: geo.size
            )
        }
        .background(Theme.night.ignoresSafeArea())
        .navigationTitle("単語カード")
        .task {
            await model.load()
            showBack = false
        }
        .onChange(of: model.filter) { _, _ in
            Task {
                await model.load()
                showBack = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cardAdded)) { _ in
            Task {
                await model.load()
                showBack = false
            }
        }
    }
}

#Preview {
    CardsView()
}

struct ActionButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

private struct CardsScreen: View {
    @Binding var model: CardsViewModel
    @Binding var showBack: Bool
    @Binding var dragOffset: CGFloat
    @Binding var isSwiping: Bool
    @Binding var cardHeight: CGFloat
    @Binding var transitionDirection: CGFloat
    let geoSize: CGSize

    var body: some View {
        let targetHeight = max(240, geoSize.height * 0.42)
        VStack(spacing: 16) {
            filterPicker
            progressRow
            cardStack(height: targetHeight)
            actionButtons
            navButtons
            upcomingStrip
            if model.currentCard == nil {
                reloadButton
            }
            Spacer(minLength: 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .onAppear {
            cardHeight = targetHeight
        }
    }

    private var filterPicker: some View {
        Picker("", selection: $model.filter) {
            Text("今日の復習").tag(CardFilter.due)
            Text("新着").tag(CardFilter.new)
            Text("苦手").tag(CardFilter.difficult)
            Text("すべて").tag(CardFilter.all)
        }
        .pickerStyle(.segmented)
    }

    private var progressRow: some View {
        HStack {
            Text("進捗 \(model.currentNumber)/\(model.totalCount)")
                .font(.caption)
                .foregroundStyle(Theme.textDim)
            Spacer()
            if let error = model.errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(Theme.amber)
            }
        }
    }

    private func cardStack(height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Theme.surface)
                .frame(height: height)
                .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 6)

            RoundedRectangle(cornerRadius: 24)
                .fill(Theme.card)
                .frame(height: height)
                .padding(.horizontal, 8)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)

            cardContent
        }
        .offset(x: dragOffset)
        .opacity(cardOpacity)
        .scaleEffect(cardScale)
        .animation(.easeOut(duration: 0.18), value: dragOffset)
        .onTapGesture {
            if model.currentCard != nil {
                withAnimation(.easeInOut(duration: 0.22)) {
                    showBack.toggle()
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    guard model.currentCard != nil else { return }
                    dragOffset = value.translation.width
                    isSwiping = true
                }
                .onEnded { value in
                    guard model.currentCard != nil else {
                        dragOffset = 0
                        isSwiping = false
                        return
                    }
                    let threshold: CGFloat = 100
                    if value.translation.width < -threshold {
                        transitionDirection = 1
                        dragOffset = 0
                        withAnimation(.easeInOut(duration: 0.18)) {
                            model.moveNext()
                            showBack = false
                        }
                    } else if value.translation.width > threshold {
                        transitionDirection = -1
                        dragOffset = 0
                        withAnimation(.easeInOut(duration: 0.18)) {
                            model.movePrev()
                            showBack = false
                        }
                    } else {
                        dragOffset = 0
                    }
                    isSwiping = false
                }
        )
    }

    private var cardOpacity: Double {
        let width = max(geoSize.width, 1)
        let progress = min(abs(dragOffset) / (width * 0.6), 1)
        return Double(max(0.35, 1 - progress))
    }

    private var cardScale: CGFloat {
        let width = max(geoSize.width, 1)
        let progress = min(abs(dragOffset) / (width * 0.8), 1)
        return 1 - (0.04 * progress)
    }

    private var cardContent: some View {
        VStack(spacing: 12) {
            if showBack, let card = model.currentCard {
                Text(card.back)
                    .font(.body)
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 12)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else if let card = model.currentCard {
                Text(card.front)
                    .font(.title2)
                    .foregroundStyle(Theme.text)
            } else {
                Text("No Card")
                    .font(.title2)
                    .foregroundStyle(Theme.textDim)
            }
            Text(showBack ? "Tap to hide" : "Tap to flip")
                .font(.caption)
                .foregroundStyle(Theme.textDim)
        }
        .padding(.horizontal, 12)
        .rotation3DEffect(.degrees(showBack ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .id(model.currentCard?.id ?? UUID())
        .transition(
            .asymmetric(
                insertion: .move(edge: transitionDirection > 0 ? .trailing : .leading)
                    .combined(with: .opacity),
                removal: .opacity
            )
        )
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            ActionButton(title: "もう一回", color: Theme.amber) {
                Task {
                    await model.reviewCurrent(rating: "again")
                    showBack = false
                }
            }
            .disabled(model.currentCard == nil)
            ActionButton(title: "あいまい", color: Theme.sky) {
                Task {
                    await model.reviewCurrent(rating: "unsure")
                    showBack = false
                }
            }
            .disabled(model.currentCard == nil)
            ActionButton(title: "覚えた", color: Theme.mint) {
                Task {
                    await model.reviewCurrent(rating: "know")
                    showBack = false
                }
            }
            .disabled(model.currentCard == nil)
        }
    }

    private var navButtons: some View {
        HStack {
            Button {
                transitionDirection = -1
                model.movePrev()
                showBack = false
            } label: {
                Label("前へ", systemImage: "chevron.left")
            }
            .buttonStyle(.bordered)
            .disabled(model.currentCard == nil)

            Spacer(minLength: 32)

            Button {
                transitionDirection = 1
                model.moveNext()
                showBack = false
            } label: {
                Label("次へ", systemImage: "chevron.right")
            }
            .buttonStyle(.bordered)
            .disabled(model.currentCard == nil)
        }
    }

    private var upcomingStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(model.upcomingCards, id: \.id) { card in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.front)
                            .font(.caption)
                            .foregroundStyle(Theme.text)
                            .lineLimit(2)
                        Text(card.status.rawValue)
                            .font(.caption2)
                            .foregroundStyle(Theme.textDim)
                    }
                    .padding(10)
                    .frame(width: 140, height: 80, alignment: .leading)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var reloadButton: some View {
        Button("再読み込み") {
            Task {
                await model.load()
                showBack = false
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.sky)
    }
}
