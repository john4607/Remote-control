import Foundation

public struct ServerBookmark: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var host: String
    public var port: Int
    public var code: String
    public var lastConnected: Date?
    public var isFavorite: Bool
    public var preferredMode: String // "trackpad" or "direct"

    public init(
        id: UUID = UUID(),
        name: String = "我的電腦",
        host: String = "192.168.1.100",
        port: Int = 5000,
        code: String = "",
        lastConnected: Date? = nil,
        isFavorite: Bool = false,
        preferredMode: String = "trackpad"
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.code = code
        self.lastConnected = lastConnected
        self.isFavorite = isFavorite
        self.preferredMode = preferredMode
    }

    public var baseUrl: URL? {
        var cleanHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanHost.lowercased().hasPrefix("http://") && !cleanHost.lowercased().hasPrefix("https://") {
            cleanHost = "http://\(cleanHost)"
        }
        if let url = URL(string: cleanHost) {
            var comp = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if comp?.port == nil && port > 0 {
                comp?.port = port
            }
            return comp?.url
        }
        return nil
    }

    public var displayAddress: String {
        let clean = host.replacingOccurrences(of: "http://", with: "").replacingOccurrences(of: "https://", with: "")
        return "\(clean):\(port)"
    }
}
