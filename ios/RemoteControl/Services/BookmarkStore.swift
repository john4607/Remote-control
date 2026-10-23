import Foundation
import Combine

@MainActor
public class BookmarkStore: ObservableObject {
    @Published public var bookmarks: [ServerBookmark] = []
    @Published public var isScanningLan: Bool = false
    @Published public var scanProgress: Double = 0.0

    private let saveKey = "saved_server_bookmarks"

    public init() {
        load()
        if bookmarks.isEmpty {
            // Provide helpful default template
            bookmarks = [
                ServerBookmark(
                    name: "本機 Windows 電腦",
                    host: "192.168.1.100",
                    port: 5000,
                    code: "",
                    lastConnected: nil,
                    isFavorite: true,
                    preferredMode: "trackpad"
                )
            ]
            save()
        }
    }

    public func save() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([ServerBookmark].self, from: data) {
            self.bookmarks = decoded
        }
    }

    public func add(_ bookmark: ServerBookmark) {
        bookmarks.append(bookmark)
        save()
    }

    public func update(_ bookmark: ServerBookmark) {
        if let idx = bookmarks.firstIndex(where: { $0.id == bookmark.id }) {
            bookmarks[idx] = bookmark
            save()
        }
    }

    public func delete(at offsets: IndexSet) {
        bookmarks.remove(atOffsets: offsets)
        save()
    }

    public func recordConnected(id: UUID) {
        if let idx = bookmarks.firstIndex(where: { $0.id == id }) {
            bookmarks[idx].lastConnected = Date()
            save()
        }
    }

    // Fast local subnet scanner (checking ports 5000-5005 on typical LAN)
    public func scanLocalSubnet(basePrefix: String = "192.168.1.") {
        guard !isScanningLan else { return }
        isScanningLan = true
        scanProgress = 0.0

        Task.detached(priority: .userInitiated) {
            let session = URLSession(configuration: .ephemeral)
            let total = 254
            var foundIps: [String] = []

            for i in 1...total {
                let ip = "\(basePrefix)\(i)"
                if let url = URL(string: "http://\(ip):5000/info") {
                    var req = URLRequest(url: url)
                    req.timeoutInterval = 0.25
                    if let (_, response) = try? await session.data(for: req),
                       let http = response as? HTTPURLResponse, http.statusCode == 200 || http.statusCode == 403 {
                        foundIps.append(ip)
                    }
                }
                let currentProgress = Double(i) / Double(total)
                await MainActor.run {
                    self.scanProgress = currentProgress
                }
            }

            await MainActor.run {
                for ip in foundIps {
                    if !self.bookmarks.contains(where: { $0.host == ip }) {
                        self.bookmarks.append(ServerBookmark(
                            name: "自動搜尋 (\(ip))",
                            host: ip,
                            port: 5000,
                            code: "",
                            preferredMode: "trackpad"
                        ))
                    }
                }
                self.save()
                self.isScanningLan = false
            }
        }
    }
}
