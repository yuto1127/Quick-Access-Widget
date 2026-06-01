//
//  GlobalHotkeyManager.swift
//  Quick-Access-Widget
//

import AppKit
import ApplicationServices
import os

final class GlobalHotkeyManager {
    var onToggle: (() -> Void)?

    private let logger = Logger(subsystem: "Local.Quick-Access-Widget", category: "Hotkey")

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var retryTimer: Timer?
    private var didShowPermissionAlert = false

    /// Globe / Fn key codes vary by keyboard; extend if needed.
    private let triggerKeyCodes: Set<Int64> = [63, 179]

    /// Fallback when Cmd+Globe/Fn is intercepted by macOS or not emitted by the keyboard.
    private let fallbackKeyCode: Int64 = 49 // Space
    private let fallbackRequiredFlags: CGEventFlags = [.maskCommand, .maskShift]

    func start() {
        requestAccessibilityPermission()
        installEventTapIfNeeded()

        guard retryTimer == nil else { return }
        retryTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.installEventTapIfNeeded()
        }
    }

    func ensureMonitoring() {
        installEventTapIfNeeded()
    }

    func stop() {
        retryTimer?.invalidate()
        retryTimer = nil
        uninstallEventTap()
    }

    private func installEventTapIfNeeded() {
        guard eventTap == nil else { return }

        guard AXIsProcessTrusted() else {
            if !didShowPermissionAlert {
                didShowPermissionAlert = true
                showAccessibilityAlert()
            }
            return
        }

        let eventMask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.tapDisabledByTimeout.rawValue)
            | (1 << CGEventType.tapDisabledByUserInput.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else {
                return Unmanaged.passUnretained(event)
            }

            let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
            return manager.handleEvent(type: type, event: event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            logger.error("CGEventTap の作成に失敗しました。アクセシビリティ権限を確認してください。")
            if !didShowPermissionAlert {
                didShowPermissionAlert = true
                showAccessibilityAlert()
            }
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
        logger.info("グローバルショートカット監視を開始しました。")
    }

    private func uninstallEventTap() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        runLoopSource = nil
        self.eventTap = nil
    }

    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        if shouldToggle(for: event) {
            DispatchQueue.main.async { [weak self] in
                self?.onToggle?()
            }
            return nil
        }

        return Unmanaged.passUnretained(event)
    }

    private func shouldToggle(for event: CGEvent) -> Bool {
        let flags = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat).boolValue

        if isRepeat { return false }

        // Cmd + Globe / Fn
        if flags.contains(.maskCommand), triggerKeyCodes.contains(keyCode) {
            return true
        }

        // Fallback: Cmd + Shift + Space
        if keyCode == fallbackKeyCode,
           fallbackRequiredFlags.isSubset(of: flags) {
            return true
        }

        return false
    }

    private func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    private func showAccessibilityAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "アクセシビリティ権限が必要です"
            alert.informativeText = """
            ウィジェットを表示するには、システム設定 → プライバシーとセキュリティ → アクセシビリティ で Quick-Access-Widget を許可してください。

            ショートカット:
            ・Cmd + Globe（または Cmd + Fn）
            ・代替: Cmd + Shift + Space

            Xcode から実行している場合は、DerivedData 内の .app に対して許可が必要なことがあります。
            """
            alert.addButton(withTitle: "システム設定を開く")
            alert.addButton(withTitle: "後で")
            if alert.runModal() == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}

private extension Int64 {
    var boolValue: Bool { self != 0 }
}
