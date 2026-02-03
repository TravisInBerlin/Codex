import SwiftUI

struct TabBarStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
    }
}

extension View {
    func tabBarStyle() -> some View {
        modifier(TabBarStyle())
    }
}
