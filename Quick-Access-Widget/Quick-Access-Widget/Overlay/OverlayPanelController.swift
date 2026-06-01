//
//  OverlayPanelController.swift
//  Quick-Access-Widget
//

import AppKit
import SwiftUI

@MainActor
final class OverlayPanelController {
    private let mediaManager: MediaRemoteManager
    private var panel: OverlayPanel?
    private var screenObserver: NSObjectProtocol?
    private var localKeyMonitor: Any?

    private var isVisible = false

    init(mediaManager: MediaRemoteManager) {
        self.mediaManager = mediaManager
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateFrame()
            }
        }
    }

    deinit {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        let panel = panel ?? makePanel()
        self.panel = panel
        updateFrame()
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        startLocalKeyMonitor()
        isVisible = true
    }

    func hide() {
        stopLocalKeyMonitor()
        panel?.orderOut(nil)
        isVisible = false
    }

    private func makePanel() -> OverlayPanel {
        let dashboard = WidgetDashboardView(mediaManager: mediaManager)
        let hostingView = NSHostingView(rootView: dashboard)
        hostingView.autoresizingMask = [.width, .height]
        return OverlayPanel(contentView: hostingView)
    }

    private func updateFrame() {
        guard let panel else { return }

        let screen = NSScreen.main?.visibleFrame ?? .zero
        let width = screen.width * 0.26
        let height = screen.height * 0.20
        let x = screen.midX - width / 2
        let y = screen.maxY - height - 36

        panel.setFrame(
            NSRect(x: x, y: y, width: width, height: height),
            display: true
        )
        panel.contentView?.frame = panel.contentView?.superview?.bounds ?? panel.frame
    }

    private func startLocalKeyMonitor() {
        stopLocalKeyMonitor()
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }
            self?.hide()
            return nil
        }
    }

    private func stopLocalKeyMonitor() {
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
        }
        localKeyMonitor = nil
    }
}
