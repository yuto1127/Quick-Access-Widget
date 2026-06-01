//
//  MediaRemoteManager.swift
//  Quick-Access-Widget
//

import AppKit
import Foundation

@MainActor
@Observable
final class MediaRemoteManager {
    var title = "再生中のメディアなし"
    var artist = ""
    var album = ""
    var artwork: NSImage?
    var isPlaying = false
    var hasActiveMedia = false
    var isAvailable = false

    private let bridge = MediaRemoteBridge()
    private var observers: [NSObjectProtocol] = []
    private var pollTimer: Timer?

    func startObserving() {
        isAvailable = bridge.isAvailable
        guard isAvailable else { return }

        bridge.registerNotifications(on: DispatchQueue.main)

        let notificationNames = [
            MediaRemoteKeys.nowPlayingInfoDidChange,
            MediaRemoteKeys.playbackDidChange,
            MediaRemoteKeys.applicationDidChange
        ]

        observers = notificationNames.map { name in
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name(name),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.refreshAll()
            }
        }

        startPolling()
        refreshAll()
    }

    func stopObserving() {
        pollTimer?.invalidate()
        pollTimer = nil
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers = []
    }

    func togglePlayPause() {
        bridge.send(.togglePlayPause)
        scheduleRefresh()
    }

    func nextTrack() {
        bridge.send(.nextTrack)
        scheduleRefresh()
    }

    func previousTrack() {
        bridge.send(.previousTrack)
        scheduleRefresh()
    }

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshAll()
            }
        }
        pollTimer?.tolerance = 0.3
    }

    private func scheduleRefresh() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            refreshAll()
        }
    }

    private func refreshAll() {
        bridge.fetchSnapshot { [weak self] snapshot in
            Task { @MainActor in
                self?.apply(snapshot)
            }
        }
    }

    private func apply(_ snapshot: NowPlayingSnapshot) {
        hasActiveMedia = snapshot.hasMedia
        isPlaying = snapshot.isPlaying
        artwork = snapshot.artwork

        if snapshot.hasMedia {
            title = snapshot.title.isEmpty ? "不明なタイトル" : snapshot.title
            artist = snapshot.artist
            album = snapshot.album
        } else {
            title = "再生中のメディアなし"
            artist = ""
            album = ""
        }
    }
}
