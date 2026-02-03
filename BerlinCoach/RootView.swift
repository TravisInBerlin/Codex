import SwiftUI

struct RootView: View {
    @State private var router = NotificationRouter.shared

    var body: some View {
        ZStack {
            Theme.night.ignoresSafeArea()
            NavigationStack {
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
                .navigationDestination(item: Binding(
                    get: { router.selectedSentenceId },
                    set: { _ in router.selectedSentenceId = nil }
                )) { id in
                    DetailView(sentenceId: id)
                }
                .navigationDestination(for: String.self) { id in
                    DetailView(sentenceId: id)
                }
            }
            .toolbarBackground(Theme.night, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .tint(Theme.sky)
        .preferredColorScheme(.dark)
        .tabBarStyle()
    }
}

#Preview {
    RootView()
}
