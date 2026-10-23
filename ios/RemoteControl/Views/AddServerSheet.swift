import SwiftUI

public struct AddServerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: BookmarkStore

    @State private var name: String = "辦公室電腦"
    @State private var host: String = "192.168.1."
    @State private var port: String = "5000"
    @State private var code: String = ""
    @State private var preferredMode: ControlMode = .trackpad

    var editingBookmark: ServerBookmark? = nil

    public init(store: BookmarkStore, editingBookmark: ServerBookmark? = nil) {
        self.store = store
        self.editingBookmark = editingBookmark
        if let b = editingBookmark {
            _name = State(initialValue: b.name)
            _host = State(initialValue: b.host)
            _port = State(initialValue: "\(b.port)")
            _code = State(initialValue: b.code)
            _preferredMode = State(initialValue: ControlMode(rawValue: b.preferredMode) ?? .trackpad)
        }
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("電腦名稱與連線位址")) {
                    TextField("例如：書房電腦、公司主機", text: $name)
                    HStack {
                        Text("IP / 主機名稱")
                            .foregroundColor(.secondary)
                            .frame(width: 90, alignment: .leading)
                        TextField("192.168.1.100", text: $host)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    HStack {
                        Text("通訊埠 (Port)")
                            .foregroundColor(.secondary)
                            .frame(width: 90, alignment: .leading)
                        TextField("5000", text: $port)
                            .keyboardType(.numberPad)
                    }
                }

                Section(header: Text("安全密碼")) {
                    SecureField("輸入電腦顯示的臨時或安全密碼", text: $code)
                        .autocapitalization(.none)
                }

                Section(header: Text("操作偏好設定")) {
                    Picker("預設操作模式", selection: $preferredMode) {
                        ForEach(ControlMode.allCases) { mode in
                            Label(mode.title, systemImage: mode.icon).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(editingBookmark == nil ? "新增電腦連線" : "編輯電腦設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        let p = Int(port) ?? 5000
                        if let b = editingBookmark {
                            var updated = b
                            updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            updated.host = host.trimmingCharacters(in: .whitespacesAndNewlines)
                            updated.port = p
                            updated.code = code.trimmingCharacters(in: .whitespacesAndNewlines)
                            updated.preferredMode = preferredMode.rawValue
                            store.update(updated)
                        } else {
                            let newB = ServerBookmark(
                                name: name.isEmpty ? "我的電腦" : name,
                                host: host.isEmpty ? "192.168.1.100" : host,
                                port: p,
                                code: code,
                                preferredMode: preferredMode.rawValue
                            )
                            store.add(newB)
                        }
                        dismiss()
                    }
                    .disabled(host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
