import Foundation
import UIKit
import Combine

public enum ControlMode: String, CaseIterable, Identifiable {
    case trackpad = "trackpad"
    case direct = "direct"

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .trackpad: return "虛擬觸控板"
        case .direct: return "直接觸控"
        }
    }
    public var icon: String {
        switch self {
        case .trackpad: return "computermouse"
        case .direct: return "hand.tap"
        }
    }
}

@MainActor
public class RemoteClientService: ObservableObject {
    @Published public var isConnected: Bool = false
    @Published public var isConnecting: Bool = false
    @Published public var errorMessage: String? = nil

    @Published public var currentFrame: UIImage? = nil
    @Published public var fps: Int = 0
    @Published public var latencyMs: Int = 0
    @Published public var monitorCount: Int = 1
    @Published public var currentMonitor: Int = -1
    @Published public var serverInfo: ServerInfo? = nil

    @Published public var controlMode: ControlMode = .trackpad
    @Published public var zoomScale: CGFloat = 1.0
    @Published public var panOffset: CGSize = .zero
    @Published public var trackpadSensitivity: Double = 1.0

    // Sticky Modifier Key States
    @Published public var isCtrlOn: Bool = false
    @Published public var isAltOn: Bool = false
    @Published public var isShiftOn: Bool = false
    @Published public var isWinOn: Bool = false

    private var currentBookmark: ServerBookmark? = nil
    private var streamTask: Task<Void, Never>? = nil
    private var session: URLSession

    // Virtual mouse position (0..10000)
    public var cursorX: Double = 5000
    public var cursorY: Double = 5000

    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 4.0
        config.timeoutIntervalForResource = 8.0
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        self.session = URLSession(configuration: config)
    }

    public func connect(bookmark: ServerBookmark) {
        guard !isConnected && !isConnecting else { return }
        self.currentBookmark = bookmark
        self.isConnecting = true
        self.errorMessage = nil

        if let mode = ControlMode(rawValue: bookmark.preferredMode) {
            self.controlMode = mode
        }

        Task {
            await doConnect()
        }
    }

    private func doConnect() async {
        guard let bookmark = currentBookmark, let baseUrl = bookmark.baseUrl else {
            self.errorMessage = "連線位址無效"
            self.isConnecting = false
            return
        }

        // Test credentials with /info endpoint
        let infoUrl = baseUrl.appendingPathComponent("info")
        var components = URLComponents(url: infoUrl, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "code", value: bookmark.code)]

        guard let testUrl = components?.url else {
            self.errorMessage = "網址結構錯誤"
            self.isConnecting = false
            return
        }

        do {
            let (data, response) = try await session.data(from: testUrl)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 403 {
                    self.errorMessage = "密碼不正確"
                    self.isConnecting = false
                    return
                } else if http.statusCode != 200 {
                    self.errorMessage = "伺服器回應錯誤 (\(http.statusCode))"
                    self.isConnecting = false
                    return
                }
            }

            if let info = try? JSONDecoder().decode(ServerInfo.self, from: data) {
                self.serverInfo = info
                self.monitorCount = max(1, info.monitors)
                self.currentMonitor = info.currentMonitor
            }

            self.isConnected = true
            self.isConnecting = false
            UIApplication.shared.isIdleTimerDisabled = true

            startStreaming()
        } catch {
            self.errorMessage = "連線失敗：\(error.localizedDescription)"
            self.isConnecting = false
        }
    }

    public func disconnect() {
        streamTask?.cancel()
        streamTask = nil
        isConnected = false
        isConnecting = false
        currentFrame = nil
        fps = 0
        latencyMs = 0
        zoomScale = 1.0
        panOffset = .zero
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func startStreaming() {
        streamTask?.cancel()
        streamTask = Task.detached(priority: .userInteractive) { [weak self] in
            var frameCount = 0
            var lastFpsTime = Date()
            var emaPing: Double = 25.0

            while !Task.isCancelled {
                guard let self = self else { break }
                let (connected, bookmark) = await MainActor.run {
                    (self.isConnected, self.currentBookmark)
                }
                guard connected, let bookmark = bookmark, let baseUrl = bookmark.baseUrl else { break }

                let frameUrl = baseUrl.appendingPathComponent("frame.jpg")
                var comp = URLComponents(url: frameUrl, resolvingAgainstBaseURL: false)
                let nowMs = Int(Date().timeIntervalSince1970 * 1000)
                comp?.queryItems = [
                    URLQueryItem(name: "code", value: bookmark.code),
                    URLQueryItem(name: "t", value: "\(nowMs)")
                ]

                guard let finalUrl = comp?.url else {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    continue
                }

                let reqStart = Date()
                do {
                    let (data, response) = try await self.session.data(from: finalUrl)
                    let reqTime = Date().timeIntervalSince(reqStart) * 1000
                    emaPing = emaPing * 0.7 + reqTime * 0.3

                    if let http = response as? HTTPURLResponse, http.statusCode == 200,
                       let image = UIImage(data: data) {
                        frameCount += 1
                        let now = Date()
                        var calculatedFps: Int? = nil
                        let elapsed = now.timeIntervalSince(lastFpsTime)
                        if elapsed >= 1.0 {
                            calculatedFps = Int(Double(frameCount) / elapsed)
                            frameCount = 0
                            lastFpsTime = now
                        }

                        let pingVal = Int(emaPing)
                        await MainActor.run {
                            self.currentFrame = image
                            if let newFps = calculatedFps {
                                self.fps = newFps
                            }
                            self.latencyMs = pingVal
                        }
                    } else if let http = response as? HTTPURLResponse, http.statusCode == 403 {
                        await MainActor.run {
                            self.errorMessage = "密碼過期或不符"
                            self.disconnect()
                        }
                        break
                    }
                } catch {
                    if Task.isCancelled { break }
                    try? await Task.sleep(nanoseconds: 200_000_000)
                }

                // Adaptive frame pacing (~30-60 FPS)
                try? await Task.sleep(nanoseconds: 30_000_000)
            }
        }
    }

    // MARK: - Input Sending

    public func sendCommand(_ text: String) {
        guard let bookmark = currentBookmark, let baseUrl = bookmark.baseUrl else { return }
        var inUrl = baseUrl.appendingPathComponent("in")
        var comp = URLComponents(url: inUrl, resolvingAgainstBaseURL: false)
        comp?.queryItems = [URLQueryItem(name: "code", value: bookmark.code)]
        guard let finalUrl = comp?.url else { return }

        var req = URLRequest(url: finalUrl)
        req.httpMethod = "POST"
        req.httpBody = text.data(using: .utf8)
        req.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")

        Task.detached(priority: .userInteractive) {
            _ = try? await self.session.data(for: req)
        }
    }

    public func sendMouse(action: Int, button: Int, x: Int, y: Int, wheel: Int = 0) {
        let clX = max(0, min(10000, x))
        let clY = max(0, min(10000, y))
        cursorX = Double(clX)
        cursorY = Double(clY)
        sendCommand("m \(action) \(button) 1 \(clX) \(clY) \(wheel)")
    }

    public func sendKey(vk: Int, down: Bool) {
        sendCommand("k \(down ? 1 : 0) \(vk)")
    }

    public func tapKey(vk: Int) {
        sendCommand("k 1 \(vk)\nk 0 \(vk)")
    }

    public func sendText(_ text: String) {
        guard !text.isEmpty else { return }
        sendCommand("t \(text)")
    }

    public func sendShortcut(_ commands: [String]) {
        let batch = commands.joined(separator: "\n")
        sendCommand(batch)
    }

    public func toggleModifier(_ modifier: String) {
        switch modifier.lowercased() {
        case "ctrl":
            isCtrlOn.toggle()
            sendKey(vk: WindowsVirtualKey.control, down: isCtrlOn)
        case "alt":
            isAltOn.toggle()
            sendKey(vk: WindowsVirtualKey.alt, down: isAltOn)
        case "shift":
            isShiftOn.toggle()
            sendKey(vk: WindowsVirtualKey.shift, down: isShiftOn)
        case "win":
            isWinOn.toggle()
            sendKey(vk: WindowsVirtualKey.win, down: isWinOn)
        default:
            break
        }
    }

    public func cycleMonitor() {
        let next = (currentMonitor + 2) % (monitorCount + 1) - 1
        currentMonitor = next
        sendCommand("p \(next)")
    }

    public func resetZoom() {
        zoomScale = 1.0
        panOffset = .zero
    }
}
