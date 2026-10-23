import Foundation

public enum MouseAction: Int {
    case move = 1
    case down = 2
    case up = 3
    case wheel = 4
}

public enum MouseButton: Int {
    case left = 1
    case right = 2
    case middle = 3
}

public struct WindowsVirtualKey {
    public static let backspace = 8
    public static let tab = 9
    public static let enter = 13
    public static let shift = 16
    public static let control = 17
    public static let alt = 18
    public static let escape = 27
    public static let space = 32
    public static let pageUp = 33
    public static let pageDown = 34
    public static let end = 35
    public static let home = 36
    public static let left = 37
    public static let up = 38
    public static let right = 39
    public static let down = 40
    public static let delete = 46
    public static let win = 91
    public static let f1 = 112
    public static let f2 = 113
    public static let f3 = 114
    public static let f4 = 115
    public static let f5 = 116
    public static let f6 = 117
    public static let f7 = 118
    public static let f8 = 119
    public static let f9 = 120
    public static let f10 = 121
    public static let f11 = 122
    public static let f12 = 123
    public static let keyA = 65
    public static let keyC = 67
    public static let keyD = 68
    public static let keyL = 76
    public static let keyV = 86
    public static let keyZ = 90
}

public struct ShortcutCombo: Identifiable {
    public let id = UUID()
    public let title: String
    public let subtitle: String
    public let icon: String
    public let commands: [String]

    public static let allCombos: [ShortcutCombo] = [
        ShortcutCombo(title: "Win + D", subtitle: "顯示桌面", icon: "menubar.dock.rectangle", commands: [
            "k 1 91", "k 1 68", "k 0 68", "k 0 91"
        ]),
        ShortcutCombo(title: "Alt + Tab", subtitle: "切換視窗", icon: "square.on.square", commands: [
            "k 1 18", "k 1 9", "k 0 9", "k 0 18"
        ]),
        ShortcutCombo(title: "Ctrl + C", subtitle: "複製", icon: "doc.on.doc", commands: [
            "k 1 17", "k 1 67", "k 0 67", "k 0 17"
        ]),
        ShortcutCombo(title: "Ctrl + V", subtitle: "貼上", icon: "doc.on.clipboard", commands: [
            "k 1 17", "k 1 86", "k 0 86", "k 0 17"
        ]),
        ShortcutCombo(title: "Ctrl + Z", subtitle: "復原", icon: "arrow.uturn.backward", commands: [
            "k 1 17", "k 1 90", "k 0 90", "k 0 17"
        ]),
        ShortcutCombo(title: "Ctrl + A", subtitle: "全選", icon: "selection.pin.in.out", commands: [
            "k 1 17", "k 1 65", "k 0 65", "k 0 17"
        ]),
        ShortcutCombo(title: "Win + L", subtitle: "鎖定螢幕", icon: "lock", commands: [
            "k 1 91", "k 1 76", "k 0 76", "k 0 91"
        ]),
        ShortcutCombo(title: "工作管理員", subtitle: "Ctrl+Shift+Esc", icon: "chart.bar.xaxis", commands: [
            "k 1 17", "k 1 16", "k 1 27", "k 0 27", "k 0 16", "k 0 17"
        ]),
        ShortcutCombo(title: "Alt + F4", subtitle: "關閉視窗", icon: "xmark.circle", commands: [
            "k 1 18", "k 1 115", "k 0 115", "k 0 18"
        ]),
        ShortcutCombo(title: "重新整理", subtitle: "F5", icon: "arrow.clockwise", commands: [
            "k 1 116", "k 0 116"
        ]),
        ShortcutCombo(title: "安全登入", subtitle: "Ctrl+Alt+Del", icon: "shield.checkered", commands: [
            "k 1 17", "k 1 18", "k 1 46", "k 0 46", "k 0 18", "k 0 17"
        ])
    ]
}
