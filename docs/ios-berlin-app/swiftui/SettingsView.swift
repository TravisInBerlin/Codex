import SwiftUI

struct SettingsView: View {
    @State private var notificationsOn = true
    @State private var startHour = 9
    @State private var endHour = 21
    @State private var maxSentences = 2

    var body: some View {
        Form {
            Section("通知") {
                Toggle("通知を有効にする", isOn: $notificationsOn)
                Stepper("開始: \(startHour)時", value: $startHour, in: 6...12)
                Stepper("終了: \(endHour)時", value: $endHour, in: 18...23)
                Stepper("文数: 最大\(maxSentences)文", value: $maxSentences, in: 1...2)
            }

            Section("学習") {
                Text("必須: 意味 / 性 / 語源")
                Text("追加: 再帰動詞 / 前置詞セット / 過去形・過去分詞")
            }
        }
        .navigationTitle("設定")
    }
}

#Preview {
    SettingsView()
}
