//
//  MediaRemoteManager.swift
//  Quick-Access-Widget
//

import AppKit
import Foundation
import MediaPlayer

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
    var canControl = false

    private let bridge = MediaRemoteBridge()
    private var observers: [NSObjectProtocol] = []
    private var pollTimer: Timer?

    private var useMediaRemote = false

    func startObserving() {
        useMediaRemote = bridge.isAvailable

        if useMediaRemote {
            isAvailable = true
            canControl = true
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
        } else {
            // MediaRemote が使えない場合：MPNowPlayingInfoCenter から表示だけフォールバック
            isAvailable = true
            canControl = false
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
        if useMediaRemote {
            bridge.send(.togglePlayPause)
        }
        scheduleRefresh()
    }

    func nextTrack() {
        if useMediaRemote {
            bridge.send(.nextTrack)
        }
        scheduleRefresh()
    }

    func previousTrack() {
        if useMediaRemote {
            bridge.send(.previousTrack)
        }
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
        if useMediaRemote {
            bridge.fetchSnapshot { [weak self] snapshot in
                Task { @MainActor in
                    self?.apply(snapshot)
                }
            }
        } else {
            applyFromNowPlayingInfoCenter()
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

    private func applyFromNowPlayingInfoCenter() {
        let info = MPNowPlayingInfoCenter.default().nowPlayingInfo

        let newTitle = info?[MPMediaItemPropertyTitle] as? String
        let newArtist = info?[MPMediaItemPropertyArtist] as? String
        let playbackRateNumber = info?[MPNowPlayingInfoPropertyPlaybackRate] as? NSNumber
        let playbackRate = playbackRateNumber?.doubleValue ?? 0
        isPlaying = playbackRate > 0

        if let titleStr = newTitle, !titleStr.isEmpty {
            title = titleStr
        } else if isPlaying {
            title = "再生中"
        } else {
            title = "再生中のメディアなし"
        }

        artist = newArtist ?? ""
        album = ""

        if let artworkItem = info?[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork {
            artwork = artworkItem.image(at: CGSize(width: 240, height: 240))
        } else {
            artwork = nil
        }

        hasActiveMedia = isPlaying || !(title.isEmpty && artist.isEmpty) || artwork != nil
        isAvailable = hasActiveMedia
    }
}
