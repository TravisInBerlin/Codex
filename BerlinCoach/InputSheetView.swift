import SwiftUI

struct InputSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var link = ""
    @State private var mode: InputMode = .text

    enum InputMode: String, CaseIterable, Identifiable {
        case text = "文章を貼り付け"
        case link = "リンクを追加"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("", selection: $mode) {
                    ForEach(InputMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if mode == .text {
                    TextEditor(text: $text)
                        .frame(minHeight: 120)
                } else {
                    TextField("https://", text: $link)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("取り込み")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("追加") { dismiss() }
                        .disabled(mode == .text ? text.isEmpty : link.isEmpty)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    InputSheetView()
}
