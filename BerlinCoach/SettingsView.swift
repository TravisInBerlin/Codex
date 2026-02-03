import SwiftUI

struct SettingsView: View {
    @State private var model = SettingsViewModel()
    @State private var startTime = Date()
    @State private var endTime = Date()

    var body: some View {
        Form {
            Section("通知") {
                Toggle("通知を有効にする", isOn: $model.notificationsOn)
                DatePicker("開始", selection: $startTime, displayedComponents: .hourAndMinute)
                DatePicker("終了", selection: $endTime, displayedComponents: .hourAndMinute)
                Stepper("頻度: \(model.intervalMinutes)分", value: $model.intervalMinutes, in: 1...120)
                Stepper("文数: 最大\(model.maxSentences)文", value: $model.maxSentences, in: 1...2)
                Text("※ 通知は最大64件まで")
                    .font(.caption2)
                    .foregroundStyle(Theme.textDim)
            }

            Section("学習") {
                Text("必須: 意味 / 性 / 語源")
                Text("必須: 過去形・過去分詞")
                Text("追加: 再帰動詞 / 前置詞セット")
            }

            Section("略語（文分割の例外）") {
                TextField("例: vgl., z.T., sog.", text: Binding(
                    get: { model.abbreviations.joined(separator: ", ") },
                    set: { model.abbreviations = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                ))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                Button("保存") {
                    Task { await model.saveAbbreviations() }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.night.ignoresSafeArea())
        .navigationTitle("設定")
        .task {
            await model.load()
            startTime = makeTime(hour: model.startHour, minute: model.startMinute)
            endTime = makeTime(hour: model.endHour, minute: model.endMinute)
        }
        .onChange(of: model.notificationsOn) { _, _ in
            Task { await model.save() }
        }
        .onChange(of: startTime) { _, _ in
            let comps = Calendar.current.dateComponents([.hour, .minute], from: startTime)
            model.startHour = comps.hour ?? 9
            model.startMinute = comps.minute ?? 0
            Task { await model.save() }
        }
        .onChange(of: endTime) { _, _ in
            let comps = Calendar.current.dateComponents([.hour, .minute], from: endTime)
            model.endHour = comps.hour ?? 21
            model.endMinute = comps.minute ?? 0
            Task { await model.save() }
        }
        .onChange(of: model.intervalMinutes) { _, _ in
            Task { await model.save() }
        }
        .onChange(of: model.maxSentences) { _, _ in
            Task { await model.save() }
        }
        .onAppear {
            Task { await model.save() }
        }
    }

    private func makeTime(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
    }
}

#Preview {
    SettingsView()
}
