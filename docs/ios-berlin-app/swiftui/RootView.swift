import SwiftUI

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

#Preview {
    RootView()
}
