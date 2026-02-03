import SwiftUI

struct SourceItem: Identifiable {
    let id = UUID()
    let handle: String
    var enabled: Bool
}

struct SourcesView: View {
    @State private var showAdd = false
    @State private var sources: [SourceItem] = [
        SourceItem(handle: "polizeiberlin", enabled: true),
        SourceItem(handle: "berlinerzeitung", enabled: true),
        SourceItem(handle: "BVG", enabled: false)
    ]

    var body: some View {
        List {
            ForEach($sources) { $source in
                HStack {
                    Text("@\(source.handle)")
                    Spacer()
                    Toggle("", isOn: $source.enabled)
                        .labelsHidden()
                }
            }
            .onMove { from, to in
                sources.move(fromOffsets: from, toOffset: to)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showAdd) {
            AddSourceView()
        }
        .navigationTitle("取得ソース")
    }
}

struct AddSourceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var handle = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("@アカウント名", text: $handle)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .navigationTitle("ソースを追加")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("追加") { dismiss() }
                        .disabled(handle.isEmpty)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SourcesView()
}
