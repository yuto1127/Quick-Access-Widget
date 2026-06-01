//
//  AppDelegate.swift
//  Quick-Access-Widget
//

import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let mediaManager = MediaRemoteManager()
    private lazy var panelController = OverlayPanelController(mediaManager: mediaManager)
    private lazy var hotkeyManager = GlobalHotkeyManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        hotkeyManager.onToggle = { [weak self] in
            self?.panelController.toggle()
        }
        hotkeyManager.start()
        mediaManager.startObserving()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        hotkeyManager.ensureMonitoring()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
