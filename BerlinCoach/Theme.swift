import SwiftUI

struct Theme {
    static let night = Color(hex: "0F1220")
    static let deep = Color(hex: "141A2B")
    static let surface = Color(hex: "1B2340")
    static let card = Color(hex: "1F294A")
    static let mint = Color(hex: "4DE3B2")
    static let sky = Color(hex: "6CB7FF")
    static let amber = Color(hex: "F7B267")
    static let text = Color(hex: "EEF2FF")
    static let textMuted = Color(hex: "B7C0DD")
    static let textDim = Color(hex: "8A93B7")
}

extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}
