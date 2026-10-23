import SwiftUI

public struct ContentView: View {
    @StateObject private var store = BookmarkStore()
    @StateObject private var client = RemoteClientService()

    public init() {}

    public var body: some View {
        ZStack {
            if client.isConnected {
                RemoteDesktopView(client: client)
            } else {
                ServerListView(store: store, client: client)
            }

            // Connecting Loading Overlay
            if client.isConnecting {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.6)
                        Text("正在連線至電腦...")
                            .font(.headline)
                            .foregroundColor(.white)
                        Button("取消連線") {
                            client.disconnect()
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                    }
                    .padding(28)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.1, green: 0.13, blue: 0.2))
                    )
                }
            }
        }
        .alert("連線失敗", isPresented: Binding<Bool>(
            get: { client.errorMessage != nil },
            set: { if !$0 { client.errorMessage = nil } }
        )) {
            Button("確定", role: .cancel) { client.errorMessage = nil }
        } message: {
            Text(client.errorMessage ?? "未知錯誤")
        }
    }
}
