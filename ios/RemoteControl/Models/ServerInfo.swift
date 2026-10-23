import Foundation

public struct ServerInfo: Codable {
    public let ok: Bool
    public let monitors: Int
    public let currentMonitor: Int
    public let width: Int
    public let height: Int
    public let version: String

    public init(
        ok: Bool = true,
        monitors: Int = 1,
        currentMonitor: Int = -1,
        width: Int = 1920,
        height: Int = 1080,
        version: String = "1.0.32"
    ) {
        self.ok = ok
        self.monitors = monitors
        self.currentMonitor = currentMonitor
        self.width = width
        self.height = height
        self.version = version
    }
}
