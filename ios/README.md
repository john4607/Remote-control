# 遠端控制 iOS / iPhone 應用程式指南

本專案為「遠端控制」提供兩種在 iPhone 上的完整控制方案：

---

## 📱 方案一：高質感 iPhone Web App / PWA（最推薦・免安裝・即開即用）

無需 Mac 電腦，也無需 Apple 開發者帳號，只要使用 iPhone 的 Safari 瀏覽器，即可將其轉變為如同原生 App 般的全螢幕應用程式！

### 使用步驟：
1. **確認電腦已啟動「遠端控制」**：電腦端會顯示區網網址（例如 `http://192.168.1.100:5000/`）或對外網址。
2. **在 iPhone 上打開 Safari**：輸入上述網址並前往。
3. **加入主畫面（關鍵步驟）**：
   - 點擊 Safari 底部正中間的 **「分享 ⎋」** 按鈕。
   - 向下滑動，點選 **「加入主畫面 ⊞」**。
   - 確認名稱為「遠端控制」，點擊右上角「新增」。
4. **全螢幕獨立運行**：
   - 您的 iPhone 主螢幕上會出現專屬的藍色螢幕 App 圖示。
   - 點擊打開後，**Safari 網址列與頂底工具列會自動消失**，以 100% 全螢幕原生質感運行！
   - 輸入密碼一次後會自動保存，下次打開無需重複輸入。

### 內建強大功能：
- **雙操作模式切換**：
  - 🖱️ **虛擬觸控板模式**：手機螢幕變成筆電觸控板，手指滑動精確帶動滑鼠游標，支援輕觸左鍵、雙指輕點右鍵、雙指滑動滾輪，底部並附有專屬的大顆左右鍵！
  - 👆 **直接觸控模式**：點擊螢幕哪裡，滑鼠就點哪裡；支援長按 0.5 秒觸發右鍵（帶有震動觸感回饋）。
- **雙指平滑縮放（Pinch to Zoom）**：放大檢視桌面細節，雙指拖曳平移視角，雙擊快速復位。
- **打字輸入框**：完整支援 iPhone 原生繁體中文注音、拼音、手寫輸入法。
- **Windows 常用快捷工具箱**：
  - 一鍵觸發：`Win+D`（顯示桌面）、`Alt+Tab`（切換視窗）、`Ctrl+C`（複製）、`Ctrl+V`（貼上）、`Ctrl+Z`（復原）、`Win+L`（鎖定電腦）、`Ctrl+Shift+Esc`（工作管理員）、`Alt+F4`、`F5`。
  - 黏性組合鍵：`Ctrl`、`Alt`、`Shift`、`Win` 可保持選中狀態，方便組合操作。
- **多螢幕切換**：若電腦有多個螢幕，可一鍵切換「全部螢幕 / 螢幕 1 / 螢幕 2」。

---

## 🍎 方案二：原生 Swift / SwiftUI iOS App 專案

本資料夾內已包含完整的原生 Xcode 專案架構（`RemoteControl.xcodeproj`），支援以下兩種構建方式：

### 途徑 A：GitHub Actions 雲端自動編譯 IPA（免 Mac、完全免費）
專案中已配置 `.github/workflows/build-ios.yml`：
1. 將本專案 commit 並 push 到您的 GitHub 倉庫：`https://github.com/john4607/Remote-control`。
2. 前往 GitHub 倉庫頁面，點選上方的 **「Actions」** 分頁。
3. 點選左側的 **「Build iOS IPA」**，點擊右側 **「Run workflow」**（或只要 push 有更動 `ios/` 目錄便會自動執行）。
4. 構建完成後（約 2~3 分鐘），點擊進入該次 Run，在底部 **Artifacts** 即可下載 `RemoteControl-iOS-IPA`。
5. 解壓縮後會得到 `RemoteControl.ipa`。
6. 使用免費工具如 **AltStore**、**Sideloadly** 或 **TrollStore**，將 `.ipa` 安裝至您的 iPhone 即可！

### 途徑 B：使用 Mac 的 Xcode 開啟與安裝
1. 在 Mac 上用 Xcode 開啟 `ios/RemoteControl.xcodeproj`。
2. 用傳輸線接上 iPhone（或使用同 Wi-Fi 無線除錯）。
3. 在 Xcode 的 Target 選擇您的個人開發者帳號（Personal Team）。
4. 點擊頂部的 **Run (⌘R)**，Xcode 會直接將 App 編譯並安裝至您的 iPhone！
5. 首次安裝完成後，至 iPhone「設定」➔「一般」➔「VPN 與裝置管理」信任您的開發者憑證即可開啟。

---

## 專案結構說明
```
ios/
├── README.md                           // 本說明文件
├── RemoteControl.xcodeproj/            // 完整 Xcode 專案檔
└── RemoteControl/
    ├── RemoteControlApp.swift          // App 進入點
    ├── Info.plist                      // 權限配置 (區網搜尋 & ATS)
    ├── Models/                         // 資料模型
    │   ├── ServerBookmark.swift        // 電腦設備書籤模型
    │   ├── InputCommand.swift          // Windows 虛擬按鍵與快捷鍵
    │   └── ServerInfo.swift            // 伺服器規格與螢幕資訊
    ├── Services/                       // 服務層
    │   ├── RemoteClientService.swift   // 畫面串流與網路指令發送
    │   └── BookmarkStore.swift         // 書籤持久化與區網自動掃描
    ├── Views/                          // SwiftUI 介面
    │   ├── ContentView.swift           // 根導覽畫面
    │   ├── ServerListView.swift        // 電腦清單與快速連線首頁
    │   ├── AddServerSheet.swift        // 新增 / 編輯電腦設定
    │   ├── RemoteDesktopView.swift     // 遠端桌面即時畫面與雙手勢引擎
    │   └── KeyboardToolbarView.swift   // Windows 鍵盤與快捷工具列
    └── Assets.xcassets/                // App 圖示與主題色資產
```
