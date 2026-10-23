import SwiftUI

public struct KeyboardToolbarView: View {
    @ObservedObject var client: RemoteClientService
    @Binding var isPresented: Bool

    @State private var inputText: String = ""
    @FocusState private var isFieldFocused: Bool

    private let generator = UIImpactFeedbackGenerator(style: .medium)

    public var body: some View {
        VStack(spacing: 12) {
            // Header handle
            HStack {
                Label("Windows 鍵盤與快捷工具", systemImage: "keyboard")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    isPresented = false
                    isFieldFocused = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 4)

            // Direct text typing row (supports Chinese IME)
            HStack(spacing: 8) {
                TextField("點此打字 (支援繁體中文輸入法)...", text: $inputText)
                    .focused($isFieldFocused)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .onSubmit {
                        submitText()
                    }

                Button(action: submitText) {
                    Text("送出")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }

            // Sticky Modifiers Row
            HStack(spacing: 8) {
                ModifierKeyButton(title: "Ctrl", isOn: client.isCtrlOn) {
                    client.toggleModifier("ctrl")
                    generator.impactOccurred()
                }
                ModifierKeyButton(title: "Alt", isOn: client.isAltOn) {
                    client.toggleModifier("alt")
                    generator.impactOccurred()
                }
                ModifierKeyButton(title: "Shift", isOn: client.isShiftOn) {
                    client.toggleModifier("shift")
                    generator.impactOccurred()
                }
                ModifierKeyButton(title: "Win", isOn: client.isWinOn) {
                    client.toggleModifier("win")
                    generator.impactOccurred()
                }
                SpecialKeyButton(title: "Esc", icon: "escape") {
                    client.tapKey(vk: WindowsVirtualKey.escape)
                    generator.impactOccurred()
                }
            }

            // Essential Navigation Row
            HStack(spacing: 8) {
                SpecialKeyButton(title: "Tab", icon: "arrow.right.to.line") {
                    client.tapKey(vk: WindowsVirtualKey.tab)
                }
                SpecialKeyButton(title: "Enter", icon: "return") {
                    client.tapKey(vk: WindowsVirtualKey.enter)
                }
                SpecialKeyButton(title: "退格", icon: "delete.left") {
                    client.tapKey(vk: WindowsVirtualKey.backspace)
                }
                SpecialKeyButton(title: "Del", icon: "delete.forward") {
                    client.tapKey(vk: WindowsVirtualKey.delete)
                }
                SpecialKeyButton(title: "空白", icon: "space") {
                    client.tapKey(vk: WindowsVirtualKey.space)
                }
            }

            // Directional Arrow Keys
            HStack(spacing: 8) {
                SpecialKeyButton(title: "←", icon: "arrow.left") {
                    client.tapKey(vk: WindowsVirtualKey.left)
                }
                SpecialKeyButton(title: "↑", icon: "arrow.up") {
                    client.tapKey(vk: WindowsVirtualKey.up)
                }
                SpecialKeyButton(title: "↓", icon: "arrow.down") {
                    client.tapKey(vk: WindowsVirtualKey.down)
                }
                SpecialKeyButton(title: "→", icon: "arrow.right") {
                    client.tapKey(vk: WindowsVirtualKey.right)
                }
                SpecialKeyButton(title: "F5", icon: "arrow.clockwise") {
                    client.tapKey(vk: WindowsVirtualKey.f5)
                }
            }

            Divider().background(Color.white.opacity(0.1))

            // Quick Combos Grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ShortcutCombo.allCombos) { combo in
                        Button(action: {
                            client.sendShortcut(combo.commands)
                            generator.impactOccurred()
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: combo.icon)
                                    .font(.system(size: 16))
                                Text(combo.title)
                                    .font(.system(size: 13, weight: .bold))
                                Text(combo.subtitle)
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 82, height: 68)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.08, green: 0.11, blue: 0.17).opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 20, y: -5)
        .onAppear {
            generator.prepare()
        }
    }

    private func submitText() {
        guard !inputText.isEmpty else { return }
        client.sendText(inputText)
        inputText = ""
        generator.impactOccurred()
    }
}

struct ModifierKeyButton: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 38)
                .background(isOn ? Color.blue : Color.white.opacity(0.1))
                .foregroundColor(.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isOn ? Color.blue.opacity(0.8) : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

struct SpecialKeyButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let ic = icon {
                    Image(systemName: ic)
                        .font(.system(size: 12))
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity, minHeight: 38)
            .background(Color.white.opacity(0.08))
            .foregroundColor(Color(white: 0.9))
            .cornerRadius(10)
        }
    }
}
