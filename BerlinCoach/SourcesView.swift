import SwiftUI

struct SourcesView: View {
    @State private var showAdd = false
    @State private var showEdit = false
    @State private var editTarget: SourceItem? = nil
    @State private var model = SourcesViewModel()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                Section {
                    Button {
                        Task { await model.ingestNow() }
                    } label: {
                        if model.isLoading {
                            HStack {
                                ProgressView()
                                Text("取得中...")
                            }
                        } else {
                            Text("今すぐ取得")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.sky)
                    .disabled(model.isLoading)
                }
                .listRowBackground(Theme.night)

                if let error = model.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Theme.amber)
                        .listRowBackground(Theme.surface)
                }
                ForEach($model.sources) { $source in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("@\(source.handle)")
                                .foregroundStyle(Theme.text)
                            Text(source.enabled ? "取得中" : "一時停止")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                            Text("最終更新: \(source.lastSync)")
                                .font(.caption2)
                                .foregroundStyle(Theme.textDim)
                        }
                        Spacer()
                        Toggle("", isOn: $source.enabled)
                            .labelsHidden()
                            .onChange(of: source.enabled) { _, newValue in
                                Task { await model.toggle(id: source.id, enabled: newValue) }
                            }
                    }
                    .listRowBackground(Theme.surface)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editTarget = source
                        showEdit = true
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { await model.deleteSource(id: source.id) }
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
                .onMove { from, to in
                    model.sources.move(fromOffsets: from, toOffset: to)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.night.ignoresSafeArea())

            Button {
                showAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(18)
                    .background(Theme.sky)
                    .clipShape(Circle())
                    .shadow(radius: 8)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 28)
        }
        .task {
            await model.load()
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
        .toolbar(.visible, for: .navigationBar)
        .sheet(isPresented: $showAdd) {
            AddSourceView(model: model)
        }
        .sheet(isPresented: $showEdit) {
            if let target = editTarget {
                EditSourceView(model: model, source: target)
            }
        }
        .navigationTitle("取得ソース")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AddSourceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var handle = ""
    @State private var rssUrl = ""
    let model: SourcesViewModel

    var body: some View {
        NavigationStack {
            Form {
                TextField("表示名（任意）", text: $handle)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("RSS URL", text: $rssUrl)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("プレビュー") {
                    Task { await model.previewSource(handle: handle, rssUrl: rssUrl) }
                }
                .disabled(rssUrl.isEmpty || model.isPreviewing)
                if model.isPreviewing {
                    ProgressView()
                }
                if let preview = model.preview {
                    if let title = preview.title {
                        Text("タイトル: \(title)")
                            .font(.caption)
                    }
                    ForEach(preview.items, id: \.self) { item in
                        Text("・\(item)")
                            .font(.caption2)
                    }
                }
            }
            .navigationTitle("ソースを追加")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("追加") {
                        Task {
                            await model.addSource(handle: handle, rssUrl: rssUrl)
                            dismiss()
                        }
                    }
                    .disabled(rssUrl.isEmpty)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}

struct EditSourceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var handle: String
    @State private var rssUrl: String
    let model: SourcesViewModel
    let source: SourceItem

    init(model: SourcesViewModel, source: SourceItem) {
        self.model = model
        self.source = source
        _handle = State(initialValue: source.handle)
        _rssUrl = State(initialValue: source.rssUrl ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("表示名", text: $handle)
                TextField("RSS URL", text: $rssUrl)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Text("※ RSS URLは変更したい場合のみ入力")
                    .font(.caption2)
                    .foregroundStyle(Theme.textDim)
            }
            .navigationTitle("ソースを編集")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        Task {
                            await model.editSource(id: source.id, handle: handle, rssUrl: rssUrl)
                            dismiss()
                        }
                    }
                    .disabled(rssUrl.isEmpty)
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
