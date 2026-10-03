import Cocoa
import Foundation
import Darwin
import IOKit.ps
import IOKit.pwr_mgt

// MARK: - Constants & Metadata
let APP_NAME = "nosleep-mac"
let APP_VERSION = "2.0.0"

// MARK: - Battery Helper
struct BatteryStatus {
    let percent: Int
    let isAC: Bool
    let isCharging: Bool
    
    var displayText: String {
        let stateStr = isCharging ? "充電中" : (isAC ? "電源接続" : "バッテリー")
        return "\(percent)% (\(stateStr))"
    }
}

func getCurrentBatteryStatus() -> BatteryStatus? {
    guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
          let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
        return nil
    }
    for source in sources {
        guard let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else { continue }
        if let type = desc[kIOPSTypeKey as String] as? String, type == (kIOPSInternalBatteryType as String) {
            let cap = desc[kIOPSCurrentCapacityKey as String] as? Int ?? 0
            let isCharging = (desc[kIOPSIsChargingKey as String] as? Bool) ?? false
            let pState = desc[kIOPSPowerSourceStateKey as String] as? String ?? ""
            let isAC = (pState == (kIOPSACPowerValue as String)) || isCharging
            return BatteryStatus(percent: cap, isAC: isAC, isCharging: isCharging)
        }
    }
    return nil
}

// MARK: - Brand Icon Generators
func generateBrandDockIcon() -> NSImage {
    let size = NSSize(width: 256, height: 256)
    let image = NSImage(size: size)
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let rect = CGRect(x: 16, y: 16, width: 224, height: 224)
    let bgPath = NSBezierPath(roundedRect: NSRect(origin: rect.origin, size: rect.size), xRadius: 52, yRadius: 52)

    let gradient = NSGradient(
        starting: NSColor(calibratedRed: 0.08, green: 0.09, blue: 0.13, alpha: 1.0),
        ending: NSColor(calibratedRed: 0.02, green: 0.03, blue: 0.05, alpha: 1.0)
    )
    gradient?.draw(in: bgPath, angle: -45)

    bgPath.lineWidth = 1.5
    NSColor(calibratedRed: 0.28, green: 0.34, blue: 0.48, alpha: 0.55).setStroke()
    bgPath.stroke()

    ctx.saveGState()
    ctx.translateBy(x: 128, y: 128)

    // クレセントアーク
    let moonPath = NSBezierPath()
    moonPath.appendArc(withCenter: NSPoint(x: -8, y: 0), radius: 54, startAngle: 60, endAngle: 300, clockwise: false)
    moonPath.appendArc(withCenter: NSPoint(x: 14, y: 0), radius: 46, startAngle: 285, endAngle: 75, clockwise: true)
    moonPath.close()

    let moonGradient = NSGradient(
        starting: NSColor(calibratedRed: 0.30, green: 0.60, blue: 0.95, alpha: 0.95),
        ending: NSColor(calibratedRed: 0.15, green: 0.35, blue: 0.75, alpha: 0.90)
    )
    moonGradient?.draw(in: moonPath, angle: 90)

    // 覚醒スパーク (4-point star)
    let sparkPath = NSBezierPath()
    let sparkRadius: CGFloat = 26
    let innerRadius: CGFloat = 7
    let center = NSPoint(x: 20, y: 4)

    for i in 0..<8 {
        let angle = CGFloat(i) * CGFloat.pi / 4.0
        let r = (i % 2 == 0) ? sparkRadius : innerRadius
        let pt = NSPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
        if i == 0 {
            sparkPath.move(to: pt)
        } else {
            sparkPath.line(to: pt)
        }
    }
    sparkPath.close()

    ctx.setShadow(offset: .zero, blur: 18, color: NSColor(calibratedRed: 0.3, green: 0.8, blue: 1.0, alpha: 0.85).cgColor)
    NSColor(calibratedRed: 0.90, green: 0.96, blue: 1.0, alpha: 1.0).setFill()
    sparkPath.fill()

    ctx.restoreGState()
    image.unlockFocus()
    return image
}

func generateBrandMenuBarIcon(isWarning: Bool = false) -> NSImage {
    let size = NSSize(width: 18, height: 18)
    let image = NSImage(size: size)
    image.lockFocus()

    if isWarning {
        let tri = NSBezierPath()
        tri.move(to: NSPoint(x: 9, y: 15))
        tri.line(to: NSPoint(x: 16.5, y: 3))
        tri.line(to: NSPoint(x: 1.5, y: 3))
        tri.close()
        NSColor.black.setFill()
        tri.fill()
        
        let line = NSBezierPath()
        line.move(to: NSPoint(x: 9, y: 11))
        line.line(to: NSPoint(x: 9, y: 7))
        line.lineWidth = 1.6
        line.lineCapStyle = .round
        NSColor.white.setStroke()
        line.stroke()

        let dot = NSBezierPath(ovalIn: NSRect(x: 8.2, y: 4.2, width: 1.6, height: 1.6))
        NSColor.white.setFill()
        dot.fill()
    } else {
        let moonPath = NSBezierPath()
        moonPath.appendArc(withCenter: NSPoint(x: 7.5, y: 9.0), radius: 6.8, startAngle: 65, endAngle: 295, clockwise: false)
        moonPath.appendArc(withCenter: NSPoint(x: 10.5, y: 9.0), radius: 5.8, startAngle: 280, endAngle: 80, clockwise: true)
        moonPath.close()

        NSColor.black.setFill()
        moonPath.fill()

        let sparkPath = NSBezierPath()
        let center = NSPoint(x: 11.2, y: 9.2)
        let outerR: CGFloat = 3.6
        let innerR: CGFloat = 1.1

        for i in 0..<8 {
            let angle = CGFloat(i) * CGFloat.pi / 4.0
            let r = (i % 2 == 0) ? outerR : innerR
            let pt = NSPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
            if i == 0 {
                sparkPath.move(to: pt)
            } else {
                sparkPath.line(to: pt)
            }
        }
        sparkPath.close()
        sparkPath.fill()
    }

    image.unlockFocus()
    image.isTemplate = true
    return image
}

// MARK: - Main Application Controller
class NoSleepApp: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var statusMenu: NSMenu!
    var statusHeaderItem: NSMenuItem!
    var remainingTimeMenuItem: NSMenuItem!
    var batteryMenuItem: NSMenuItem!
    
    // Timer & Target end time (Wall-clock based)
    var dispatchTimer: DispatchSourceTimer?
    var initialDuration: Int
    var totalSeconds: Int
    var targetEndTime: Date
    var remainingSeconds: Int
    
    // Power & App Nap Assertions
    var activityToken: NSObjectProtocol?
    var systemSleepAssertionID: IOPMAssertionID = 0
    var idleSleepAssertionID: IOPMAssertionID = 0
    
    var isInteractiveTTY: Bool = false
    var origTermios = termios()
    var isRawModeActive: Bool = false
    var isCleaningUp: Bool = false
    var hasWarned3Min: Bool = false
    var lastBatteryCheck = Date.distantPast

    init(seconds: Int) {
        self.initialDuration = seconds
        self.totalSeconds = seconds
        self.remainingSeconds = seconds
        self.targetEndTime = Date().addingTimeInterval(TimeInterval(seconds))
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. App Nap 防止とカーネルアサーションの確立 (最重要!)
        acquirePowerAssertions()
        
        setupSignals()
        setupTerminal()
        setupDock()
        setupMenuBar()
        startDispatchTimer()
        startKeyboardMonitor()
        
        printStartupBanner()
        
        let m = remainingSeconds / 60
        let timeStr = m > 0 ? "\(m)分間" : "\(remainingSeconds)秒間"
        sendNotification(
            title: "✦ Mac No-Sleep 有効 (\(timeStr))",
            message: "蓋を閉じてもスリープしません。Dockやメニューバー、[q]キーで解除できます。"
        )
        
        renderTerminal()
    }

    // MARK: - Power & App Nap Assertions (Core Fix)
    func acquirePowerAssertions() {
        // A. App Nap の完全無効化
        let options: ProcessInfo.ActivityOptions = [
            .userInitiated,
            .idleSystemSleepDisabled,
            .latencyCritical,
            .automaticTerminationDisabled,
            .suddenTerminationDisabled
        ]
        activityToken = ProcessInfo.processInfo.beginActivity(options: options, reason: "Mac No-Sleep Active Session")

        // B. OS カーネルレベルのシステムスリープ阻止アサーション
        var sysID: IOPMAssertionID = 0
        let sysResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "Mac No-Sleep Clamshell Prevention" as CFString,
            &sysID
        )
        if sysResult == kIOReturnSuccess {
            self.systemSleepAssertionID = sysID
        }

        // C. アイドルスリープ阻止アサーション
        var idleID: IOPMAssertionID = 0
        let idleResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "Mac No-Sleep Idle Sleep Prevention" as CFString,
            &idleID
        )
        if idleResult == kIOReturnSuccess {
            self.idleSleepAssertionID = idleID
        }
    }

    func releasePowerAssertions() {
        if systemSleepAssertionID != 0 {
            IOPMAssertionRelease(systemSleepAssertionID)
            systemSleepAssertionID = 0
        }
        if idleSleepAssertionID != 0 {
            IOPMAssertionRelease(idleSleepAssertionID)
            idleSleepAssertionID = 0
        }
        if let token = activityToken {
            ProcessInfo.processInfo.endActivity(token)
            activityToken = nil
        }
    }

    // MARK: - Dock Setup
    func setupDock() {
        NSApp.applicationIconImage = generateBrandDockIcon()
        updateDockBadge()
    }

    func updateDockBadge() {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        if remainingSeconds > 60 {
            NSApp.dockTile.badgeLabel = "\(m)m"
        } else if remainingSeconds > 0 {
            NSApp.dockTile.badgeLabel = "\(s)s"
        } else {
            NSApp.dockTile.badgeLabel = ""
        }
        NSApp.dockTile.display()
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        let status = NSMenuItem(title: "✦ スリープ防止中 (残り \(m)分\(s)秒)", action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        
        menu.addItem(NSMenuItem.separator())
        
        let add15 = NSMenuItem(title: "+ 15分延長", action: #selector(add15Minutes), keyEquivalent: "")
        add15.target = self
        menu.addItem(add15)
        
        let quit = NSMenuItem(title: "× スリープ防止を解除して終了", action: #selector(quitFromMenu), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)
        
        return menu
    }

    // MARK: - Menu Bar Setup
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateMenuBar()

        statusMenu = NSMenu()

        // 1. Status Header
        statusHeaderItem = NSMenuItem(title: "✦ スリープ防止: 有効 (蓋閉じOK)", action: nil, keyEquivalent: "")
        statusHeaderItem.isEnabled = false
        statusMenu.addItem(statusHeaderItem)

        // 2. Remaining Time
        remainingTimeMenuItem = NSMenuItem(title: formattedRemainingMenuTitle(), action: nil, keyEquivalent: "")
        remainingTimeMenuItem.isEnabled = false
        statusMenu.addItem(remainingTimeMenuItem)

        // 3. Battery Info
        let initialBattStr = getCurrentBatteryStatus()?.displayText ?? "取得中"
        batteryMenuItem = NSMenuItem(title: "バッテリー: \(initialBattStr)", action: nil, keyEquivalent: "")
        batteryMenuItem.isEnabled = false
        statusMenu.addItem(batteryMenuItem)

        statusMenu.addItem(NSMenuItem.separator())

        // 4. Extension Actions
        let add15 = NSMenuItem(title: "+ 15分延長", action: #selector(add15Minutes), keyEquivalent: "")
        add15.target = self
        statusMenu.addItem(add15)

        let add30 = NSMenuItem(title: "+ 30分延長", action: #selector(add30Minutes), keyEquivalent: "")
        add30.target = self
        statusMenu.addItem(add30)

        let add60 = NSMenuItem(title: "+ 1時間延長", action: #selector(add60Minutes), keyEquivalent: "")
        add60.target = self
        statusMenu.addItem(add60)

        statusMenu.addItem(NSMenuItem.separator())

        // 5. Quit Action
        let quitItem = NSMenuItem(title: "× スリープ防止を解除して終了", action: #selector(quitFromMenu), keyEquivalent: "q")
        quitItem.target = self
        statusMenu.addItem(quitItem)

        statusItem.menu = statusMenu
    }

    func updateMenuBar() {
        guard let button = statusItem.button else { return }
        let isWarning = remainingSeconds <= 180
        button.image = generateBrandMenuBarIcon(isWarning: isWarning)
        button.imagePosition = .imageLeading

        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        let timeStr = String(format: "%02d:%02d", m, s)
        button.title = " \(timeStr)"
    }

    func formattedRemainingMenuTitle() -> String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let endStr = formatter.string(from: targetEndTime)
        return "残り時間: \(m)分\(s)秒 (終了予定: \(endStr))"
    }

    func updateUI() {
        updateMenuBar()
        remainingTimeMenuItem.title = formattedRemainingMenuTitle()
        if let batt = getCurrentBatteryStatus() {
            batteryMenuItem.title = "バッテリー: \(batt.displayText)"
        }
        updateDockBadge()
    }

    @objc func add15Minutes() {
        addTime(seconds: 15 * 60)
    }

    @objc func add30Minutes() {
        addTime(seconds: 30 * 60)
    }

    @objc func add60Minutes() {
        addTime(seconds: 60 * 60)
    }

    func addTime(seconds: Int) {
        targetEndTime = targetEndTime.addingTimeInterval(TimeInterval(seconds))
        totalSeconds += seconds
        remainingSeconds = max(0, Int(targetEndTime.timeIntervalSinceNow))
        hasWarned3Min = false
        updateUI()
        renderTerminal()
        let minutes = seconds / 60
        sendNotification(title: "✦ Mac No-Sleep 延長", message: "スリープ防止時間を +\(minutes)分 延長しました（残り: \(remainingSeconds / 60)分）")
    }

    @objc func quitFromMenu() {
        stopAndQuit(reason: "画面メニューから解除が選択されました")
    }

    // MARK: - GCD DispatchSourceTimer (Does NOT sleep on lid close)
    func startDispatchTimer() {
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.schedule(deadline: .now() + 1.0, repeating: 1.0, leeway: .milliseconds(50))
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            // 実時間 (Wall-clock time) と正確に同期！蓋を閉じていた時間も確実に進む
            let nowRemaining = Int(self.targetEndTime.timeIntervalSinceNow)
            self.remainingSeconds = max(0, nowRemaining)
            
            self.updateUI()
            self.renderTerminal()

            // 1. タイマー満了判定
            if self.remainingSeconds <= 0 {
                self.dispatchTimer?.cancel()
                self.dispatchTimer = nil
                self.stopAndQuit(reason: "タイマーが満了したため、スリープ防止モードを自動解除しました")
                return
            }

            // 2. 残り3分警告通知
            if self.remainingSeconds <= 180 && !self.hasWarned3Min {
                self.hasWarned3Min = true
                self.sendNotification(title: "✧ Mac No-Sleep まもなく終了", message: "スリープ防止モードの終了まであと3分です。延長する場合はDockやメニューから操作してください。")
            }

            // 3. バッテリー過放電防止ガード
            if Date().timeIntervalSince(self.lastBatteryCheck) >= 10 {
                self.lastBatteryCheck = Date()
                if let batt = getCurrentBatteryStatus() {
                    if !batt.isAC && batt.percent <= 10 {
                        self.dispatchTimer?.cancel()
                        self.dispatchTimer = nil
                        self.stopAndQuit(reason: "バッテリー残量が \(batt.percent)% に低下したため、安全のためスリープ防止を自動解除しました")
                        return
                    }
                }
            }
        }
        self.dispatchTimer = timer
        timer.resume()
    }

    // MARK: - Terminal Setup & 1-Line In-Place Rendering
    func setupTerminal() {
        isInteractiveTTY = (isatty(STDIN_FILENO) != 0) && (isatty(STDOUT_FILENO) != 0)
        if isInteractiveTTY {
            tcgetattr(STDIN_FILENO, &origTermios)
            var raw = origTermios
            raw.c_lflag &= ~tcflag_t(ECHO | ICANON)
            tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
            isRawModeActive = true
            print("\u{1B}[?25l", terminator: "")
            fflush(stdout)
        }
    }

    func restoreTerminal() {
        if isRawModeActive {
            print("\u{1B}[?25h", terminator: "")
            tcsetattr(STDIN_FILENO, TCSAFLUSH, &origTermios)
            isRawModeActive = false
            fflush(stdout)
        }
    }

    func printStartupBanner() {
        guard isInteractiveTTY else { return }
        let cyan = "\u{1B}[36m"
        let bold = "\u{1B}[1m"
        let reset = "\u{1B}[0m"
        let gray = "\u{1B}[90m"
        
        print("\n  \(bold)\(cyan)✦ Mac No-Sleep  [LID-AWAKE: ON]\(reset)")
        print("    \(gray)Macの蓋（クラムシェル）を閉じてもスリープしません\(reset)")
        print("    \(gray)Dock、メニューバー、通知でも状況を確認・解除できます\(reset)")
        print("    \(gray)操作: [q] 解除  /  [+] 15分延長  /  [Ctrl+C] 終了\(reset)\n")
        fflush(stdout)
    }

    func renderTerminal() {
        guard isInteractiveTTY else {
            if remainingSeconds % 300 == 0 || remainingSeconds == initialDuration {
                let m = remainingSeconds / 60
                print("[\(APP_NAME)] 残り時間: 約 \(m) 分")
            }
            return
        }

        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        let timeRemainingStr = String(format: "%02d:%02d", m, s)
        let totalM = totalSeconds / 60
        let totalS = totalSeconds % 60
        let totalStr = String(format: "%02d:%02d", totalM, totalS)

        let progress = totalSeconds > 0 ? Double(totalSeconds - remainingSeconds) / Double(totalSeconds) : 1.0
        let percent = Int(progress * 100)
        let barWidth = 14
        let filledCount = min(barWidth, max(0, Int(Double(barWidth) * progress)))
        let emptyCount = barWidth - filledCount
        let bar = String(repeating: "━", count: filledCount) + String(repeating: "─", count: emptyCount)

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let endStr = formatter.string(from: targetEndTime)

        let battInfo = getCurrentBatteryStatus()?.displayText ?? "取得中"

        let bold = "\u{1B}[1m"
        let reset = "\u{1B}[0m"
        let gray = "\u{1B}[90m"
        let clearLine = "\u{1B}[2K"

        let statusColor: String
        let statusBadge: String
        if remainingSeconds <= 60 {
            statusColor = "\u{1B}[31m" // Red
            statusBadge = "▲ CRIT"
        } else if remainingSeconds <= 180 {
            statusColor = "\u{1B}[33m" // Yellow
            statusBadge = "✧ WARN"
        } else {
            statusColor = "\u{1B}[36m" // Cyan
            statusBadge = "✦ AWAKE"
        }

        let line = "\r\(clearLine)  \(bold)\(statusColor)\(statusBadge)\(reset)  \(bold)\(timeRemainingStr)\(reset)/\(totalStr)  [\(statusColor)\(bar)\(reset)] \(String(format: "%2d%%", percent))  │  \(endStr) 終了  │  \(battInfo)  │  \(gray)q: 解除\(reset)"
        
        print(line, terminator: "")
        fflush(stdout)
    }

    // MARK: - Keyboard Monitoring
    func startKeyboardMonitor() {
        guard isInteractiveTTY else { return }
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            var buf = [UInt8](repeating: 0, count: 1)
            while true {
                let count = read(STDIN_FILENO, &buf, 1)
                if count > 0 {
                    let char = buf[0]
                    if char == 113 || char == 81 {
                        DispatchQueue.main.async {
                            self?.stopAndQuit(reason: "キーボード入力 [q] により解除されました")
                        }
                        break
                    }
                    if char == 43 {
                        DispatchQueue.main.async {
                            self?.addTime(seconds: 15 * 60)
                        }
                    }
                    if char == 3 {
                        DispatchQueue.main.async {
                            self?.stopAndQuit(reason: "キーボード入力 [Ctrl+C] により解除されました")
                        }
                        break
                    }
                }
            }
        }
    }

    // MARK: - Signals
    func setupSignals() {
        signal(SIGINT) { _ in
            DispatchQueue.main.async {
                sharedAppInstance?.stopAndQuit(reason: "シグナル (SIGINT) を受信したため解除されました")
            }
        }
        signal(SIGTERM) { _ in
            DispatchQueue.main.async {
                sharedAppInstance?.stopAndQuit(reason: "シグナル (SIGTERM) を受信したため解除されました")
            }
        }
    }

    // MARK: - Shutdown & Cleanup
    func stopAndQuit(reason: String) {
        guard !isCleaningUp else { return }
        isCleaningUp = true

        dispatchTimer?.cancel()
        dispatchTimer = nil

        // パワーアサーション解放
        releasePowerAssertions()

        restoreTerminal()

        let green = "\u{1B}[32m"
        let bold = "\u{1B}[1m"
        let reset = "\u{1B}[0m"
        print("\r\u{1B}[2K\n\n  \(bold)\(green)✓ \(reason)\(reset)")
        print("    スリープ防止モードを終了します。電源設定はランチャーが復元します。\n")
        fflush(stdout)

        sendNotification(title: "✦ Mac No-Sleep 解除", message: reason)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NSApp.terminate(nil)
        }
    }

    func sendNotification(title: String, message: String) {
        let escapedMsg = message.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
        let script = "display notification \"\(escapedMsg)\" with title \"\(escapedTitle)\" sound name \"Glass\""
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        try? task.run()
    }
}

var sharedAppInstance: NoSleepApp?

// MARK: - Program Entry
let args = CommandLine.arguments.dropFirst()
let duration: Int
if args.isEmpty {
    duration = DurationParser.defaultDuration
} else if args.count == 1, let argument = args.first {
    switch DurationParser.parse(argument) {
    case .success(let seconds):
        duration = seconds
    case .failure(let error):
        fputs("Error: \(error.message)\n", stderr)
        exit(2)
    }
} else {
    fputs("Error: 指定できる時間は1つです。--help を参照してください。\n", stderr)
    exit(2)
}
let app = NSApplication.shared
app.setActivationPolicy(.regular)

let noSleepApp = NoSleepApp(seconds: duration)
sharedAppInstance = noSleepApp
app.delegate = noSleepApp
app.run()
