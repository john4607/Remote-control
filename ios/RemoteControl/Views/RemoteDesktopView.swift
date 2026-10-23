import SwiftUI

public struct RemoteDesktopView: View {
    @ObservedObject var client: RemoteClientService
    @State private var showKeyboard: Bool = false
    @State private var showControls: Bool = true

    // Gestures state
    @State private var currentMagnification: CGFloat = 1.0
    @State private var baseMagnification: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero
    @State private var baseOffset: CGSize = .zero

    // Direct touch gesture tracking
    @State private var lastDragLocation: CGPoint? = nil
    @State private var isLongPressing: Bool = false

    private let haptic = UIImpactFeedbackGenerator(style: .medium)
    private let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { proxy in
                let screenSize = proxy.size

                ZStack {
                    // Desktop Image Canvas
                    if let frame = client.currentFrame {
                        Image(uiImage: frame)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: screenSize.width, height: screenSize.height)
                            .scaleEffect(baseMagnification * currentMagnification)
                            .offset(x: baseOffset.width + currentOffset.width,
                                    y: baseOffset.height + currentOffset.height)
                    } else {
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(1.4)
                            Text("正在載入遠端桌面畫面...")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }

                    // Gesture Interaction Surface
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            // Pinch to zoom
                            MagnificationGesture()
                                .onChanged { value in
                                    currentMagnification = value
                                }
                                .onEnded { value in
                                    baseMagnification = max(1.0, min(4.0, baseMagnification * value))
                                    currentMagnification = 1.0
                                    if baseMagnification == 1.0 {
                                        baseOffset = .zero
                                        currentOffset = .zero
                                    }
                                }
                        )
                        .gesture(
                            client.controlMode == .trackpad ? trackpadDragGesture(size: screenSize) : directTouchDragGesture(size: screenSize)
                        )
                        .onTapGesture(count: 2) {
                            // Double tap: toggle 2x zoom or reset
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if baseMagnification > 1.2 {
                                    baseMagnification = 1.0
                                    baseOffset = .zero
                                } else {
                                    baseMagnification = 2.0
                                }
                            }
                            haptic.impactOccurred()
                        }
                }
            }

            // Top Floating Capsule Bar
            VStack {
                if showControls {
                    topFloatingBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()

                // Bottom Dock in Trackpad mode
                if client.controlMode == .trackpad && showControls && !showKeyboard {
                    trackpadBottomDock
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showControls)
            .animation(.easeInOut(duration: 0.2), value: client.controlMode)

            // Slide-up Keyboard Drawer
            if showKeyboard {
                VStack {
                    Spacer()
                    KeyboardToolbarView(client: client, isPresented: $showKeyboard)
                }
                .transition(.move(edge: .bottom))
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showKeyboard)
            }
        }
        .statusBarHidden(!showControls)
        .navigationBarHidden(true)
        .onAppear {
            haptic.prepare()
            heavyHaptic.prepare()
        }
    }

    // MARK: - Gestures

    private func trackpadDragGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if let last = lastDragLocation {
                    let dx = Double(value.location.x - last.x) * client.trackpadSensitivity * 6.5
                    let dy = Double(value.location.y - last.y) * client.trackpadSensitivity * 6.5
                    let newX = max(0, min(10000, client.cursorX + dx))
                    let newY = max(0, min(10000, client.cursorY + dy))
                    client.sendMouse(action: 1, button: 1, x: Int(newX), y: Int(newY), wheel: 0)
                }
                lastDragLocation = value.location
            }
            .onEnded { value in
                // If it was a quick tap with minimal movement: left click
                let moved = hypot(value.translation.width, value.translation.height)
                if moved < 6 {
                    let x = Int(client.cursorX)
                    let y = Int(client.cursorY)
                    client.sendMouse(action: 2, button: 1, x: x, y: y)
                    client.sendMouse(action: 3, button: 1, x: x, y: y)
                    haptic.impactOccurred()
                }
                lastDragLocation = nil
            }
    }

    private func directTouchDragGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if baseMagnification > 1.05 {
                    // When zoomed in, panning the view
                    currentOffset = value.translation
                } else {
                    // Direct touch mouse drag
                    let norm = toNormalized(point: value.location, in: size)
                    client.sendMouse(action: 1, button: 1, x: norm.x, y: norm.y)
                }
            }
            .onEnded { value in
                if baseMagnification > 1.05 {
                    baseOffset.width += currentOffset.width
                    baseOffset.height += currentOffset.height
                    currentOffset = .zero
                } else {
                    let moved = hypot(value.translation.width, value.translation.height)
                    let norm = toNormalized(point: value.location, in: size)
                    if moved < 6 {
                        // Click
                        client.sendMouse(action: 2, button: 1, x: norm.x, y: norm.y)
                        client.sendMouse(action: 3, button: 1, x: norm.x, y: norm.y)
                        haptic.impactOccurred()
                    }
                }
            }
    }

    private func toNormalized(point: CGPoint, in size: CGSize) -> (x: Int, y: Int) {
        guard size.width > 0 && size.height > 0 else { return (5000, 5000) }
        let nx = Int((point.x / size.width) * 10000)
        let ny = Int((point.y / size.height) * 10000)
        return (max(0, min(10000, nx)), max(0, min(10000, ny)))
    }

    // MARK: - Subviews

    private var topFloatingBar: some View {
        HStack(spacing: 8) {
            // Disconnect button
            Button(action: {
                client.disconnect()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }

            // Stats Indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 7, height: 7)
                Text("\(client.fps) FPS • \(client.latencyMs)ms")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(white: 0.9))
            }
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(Color.white.opacity(0.08))
            .cornerRadius(15)

            Spacer()

            // Monitor Switch Menu
            Menu {
                Button("全部顯示 (-1)") { client.sendCommand("p -1") }
                ForEach(0..<client.monitorCount, id: \.self) { idx in
                    Button("螢幕 \(idx + 1)") {
                        client.sendCommand("p \(idx)")
                    }
                }
            } label: {
                Label(client.currentMonitor == -1 ? "全部" : "螢幕 \(client.currentMonitor + 1)", systemImage: "display")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(15)
            }

            // Zoom Reset button
            Button(action: {
                withAnimation(.spring()) {
                    client.resetZoom()
                    baseMagnification = 1.0
                    baseOffset = .zero
                    currentOffset = .zero
                }
                haptic.impactOccurred()
            }) {
                Image(systemName: baseMagnification > 1.1 ? "arrow.down.right.and.arrow.up.left" : "magnifyingglass")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            // Mode Toggle button
            Button(action: {
                withAnimation {
                    client.controlMode = (client.controlMode == .trackpad) ? .direct : .trackpad
                }
                haptic.impactOccurred()
            }) {
                Image(systemName: client.controlMode.icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(client.controlMode == .trackpad ? Color.blue : Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            // Keyboard Toggle button
            Button(action: {
                showKeyboard.toggle()
                haptic.impactOccurred()
            }) {
                Image(systemName: "keyboard")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(showKeyboard ? Color.blue : Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(red: 0.06, green: 0.08, blue: 0.15).opacity(0.85))
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
        )
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private var trackpadBottomDock: some View {
        HStack(spacing: 10) {
            // Left Click Button
            Button(action: {}) {
                Text("滑鼠左鍵")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: 50)
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.7), Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(14)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        let x = Int(client.cursorX)
                        let y = Int(client.cursorY)
                        client.sendMouse(action: 2, button: 1, x: x, y: y)
                        haptic.impactOccurred()
                    }
                    .onEnded { _ in
                        let x = Int(client.cursorX)
                        let y = Int(client.cursorY)
                        client.sendMouse(action: 3, button: 1, x: x, y: y)
                    }
            )

            // Scroll Strip
            HStack(spacing: 4) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 11))
                Text("滾輪")
                    .font(.system(size: 13, weight: .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 11))
            }
            .foregroundColor(.gray)
            .frame(width: 80, height: 50)
            .background(Color.white.opacity(0.08))
            .cornerRadius(14)
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        let dy = value.translation.height
                        if abs(dy) > 10 {
                            let wheel = dy < 0 ? 120 : -120
                            let x = Int(client.cursorX)
                            let y = Int(client.cursorY)
                            client.sendMouse(action: 4, button: 0, x: x, y: y, wheel: wheel)
                        }
                    }
            )

            // Right Click Button
            Button(action: {}) {
                Text("右鍵")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 80, maxHeight: 50)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(14)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        let x = Int(client.cursorX)
                        let y = Int(client.cursorY)
                        client.sendMouse(action: 2, button: 2, x: x, y: y)
                        heavyHaptic.impactOccurred()
                    }
                    .onEnded { _ in
                        let x = Int(client.cursorX)
                        let y = Int(client.cursorY)
                        client.sendMouse(action: 3, button: 2, x: x, y: y)
                    }
            )
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }
}
