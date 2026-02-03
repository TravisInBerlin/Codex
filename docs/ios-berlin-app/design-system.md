# Visual Design System (SwiftUI)

Theme: Berlin urban + learning assistant. Calm dark base, bright accent highlights, readable Japanese + German.

---

## Color Palette

Base
- Night: #0F1220
- Deep: #141A2B
- Surface: #1B2340
- Card: #1F294A

Accent
- Mint: #4DE3B2
- Sky: #6CB7FF
- Amber: #F7B267

Text
- Primary: #EEF2FF
- Secondary: #B7C0DD
- Muted: #8A93B7

Status
- Success: #4DE3B2
- Warning: #F7B267
- Error: #FF7A7A

---

## Typography

Primary
- Japanese: "Hiragino Sans" (fallback: "Noto Sans JP")
- Latin: "Avenir Next" (fallback: "SF Pro")

Sizes
- Title: 24–28
- Section: 18–20
- Body: 15–16
- Caption: 12–13

Usage
- German text: Body or Title
- Japanese translation: Caption or Secondary
- Headings: Title/Section

---

## Components

### Cards
- Background: Card
- Corner radius: 16
- Shadow: subtle
- Tag chips: capsule, thinMaterial

### Buttons
- Primary: filled Sky
- Secondary: outline Mint
- Tertiary: text button

### Tags
- Small pills with muted background
- Color based on category (police/transport/politics/events)

---

## Layout Principles

- Plenty of whitespace
- Sentence first, explanation below
- Never show more than 2 sentences on card
- Use dividers to separate sections

---

## Motion

- Subtle fade/slide on card appearance
- Button tap scale: 0.98
- Notification open: gentle zoom

---

## SwiftUI Token Example

```swift
struct Theme {
    static let night = Color(hex: "0F1220")
    static let surface = Color(hex: "1B2340")
    static let card = Color(hex: "1F294A")
    static let mint = Color(hex: "4DE3B2")
    static let sky = Color(hex: "6CB7FF")
    static let amber = Color(hex: "F7B267")
    static let text = Color(hex: "EEF2FF")
    static let textMuted = Color(hex: "B7C0DD")
}
```

---

## Sample Card Styling (SwiftUI)

```swift
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
    }
}
```
