import SwiftUI

public struct ServerListView: View {
    @ObservedObject var store: BookmarkStore
    @ObservedObject var client: RemoteClientService

    @State private var showAddSheet: Bool = false
    @State private var editingBookmark: ServerBookmark? = nil
    @State private var quickIp: String = ""
    @State private var quickCode: String = ""

    private let haptic = UIImpactFeedbackGenerator(style: .medium)

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.05, blue: 0.09).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header Banner
                        headerBanner

                        // LAN Scanner Card
                        lanScannerCard

                        // Saved Devices Section
                        savedDevicesSection

                        // Quick Direct Connect
                        quickConnectSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("遠端控制")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddSheet = true
                        haptic.impactOccurred()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddServerSheet(store: store)
            }
            .sheet(item: $editingBookmark) { b in
                AddServerSheet(store: store, editingBookmark: b)
            }
        }
    }

    // MARK: - Subviews

    private var headerBanner: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: [Color.blue, Color(red: 0.1, green: 0.4, blue: 0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 54, height: 54)
                    .shadow(color: .blue.opacity(0.4), radius: 10, y: 4)

                Image(systemName: "display.2")
                    .font(.system(size: 26))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Windows 遠端控制")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                Text("在 iPhone 上即時流暢控制您的電腦")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.08, green: 0.11, blue: 0.18))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }

    private var lanScannerCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "wifi")
                    .foregroundColor(.blue)
                Text("同 Wi-Fi 區域網路快速搜尋")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Spacer()
                if store.isScanningLan {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(0.8)
                } else {
                    Button("開始掃描") {
                        store.scanLocalSubnet()
                        haptic.impactOccurred()
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.blue)
                }
            }

            if store.isScanningLan {
                ProgressView(value: store.scanProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.08, green: 0.11, blue: 0.18).opacity(0.7))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }

    private var savedDevicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("儲存的電腦設備")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(store.bookmarks.count) 台")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            if store.bookmarks.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("尚未儲存任何電腦")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Button("新增電腦") { showAddSheet = true }
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.04)))
            } else {
                ForEach(store.bookmarks) { bookmark in
                    serverCard(bookmark: bookmark)
                }
            }
        }
    }

    private func serverCard(bookmark: ServerBookmark) -> some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "desktopcomputer")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(bookmark.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    if bookmark.preferredMode == "trackpad" {
                        Text("觸控板")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                    } else {
                        Text("直觸")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(6)
                    }
                }

                Text(bookmark.displayAddress)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }

            Spacer()

            // Connect Action
            Button(action: {
                store.recordConnected(id: bookmark.id)
                client.connect(bookmark: bookmark)
                haptic.impactOccurred()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11))
                    Text("連線")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.08, green: 0.11, blue: 0.18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
        .contextMenu {
            Button(action: { editingBookmark = bookmark }) {
                Label("編輯", systemImage: "pencil")
            }
            Button(role: .destructive, action: {
                if let idx = store.bookmarks.firstIndex(where: { $0.id == bookmark.id }) {
                    store.delete(at: IndexSet(integer: idx))
                }
            }) {
                Label("刪除", systemImage: "trash")
            }
        }
    }

    private var quickConnectSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速直接連線")
                .font(.headline)
                .foregroundColor(.white)

            VStack(spacing: 10) {
                TextField("IP 位址 (例如: 192.168.1.100 或 外網IP)", text: $quickIp)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                    .foregroundColor(.white)

                SecureField("臨時密碼", text: $quickCode)
                    .autocapitalization(.none)
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                    .foregroundColor(.white)

                Button(action: {
                    let b = ServerBookmark(
                        name: "臨時連線",
                        host: quickIp.trimmingCharacters(in: .whitespacesAndNewlines),
                        port: 5000,
                        code: quickCode.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    client.connect(bookmark: b)
                    haptic.impactOccurred()
                }) {
                    Text("立即連線")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .disabled(quickIp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(red: 0.08, green: 0.11, blue: 0.18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
            )
        }
    }
}
