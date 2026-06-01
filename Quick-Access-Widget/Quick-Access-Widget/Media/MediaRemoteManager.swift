//
//  MediaRemoteManager.swift
//  Quick-Access-Widget
//

import Foundation

@MainActor
@Observable
final class MediaRemoteManager {
    var title = "再生中のメディアなし"
    var artist = ""
    var isPlaying = false
    var isAvailable = false

    private let bridge = MediaRemoteBridge()
    private var observers: [NSObjectProtocol] = []

    func startObserving() {
        isAvailable = bridge.isAvailable
        guard isAvailable else { return }

        bridge.registerNotifications(on: .main)

        let infoObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name(MediaRemoteKeys.nowPlayingInfoDidChange),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshNowPlaying()
            }
        }

        let playbackObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name(MediaRemoteKeys.playbackDidChange),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshPlaybackState()
            }
        }

        observers = [infoObserver, playbackObserver]
        refreshNowPlaying()
    }

    func togglePlayPause() {
        bridge.send(.togglePlayPause)
    }

    func nextTrack() {
        bridge.send(.nextTrack)
    }

    func previousTrack() {
        bridge.send(.previousTrack)
    }

    private func refreshNowPlaying() {
        bridge.fetchNowPlayingInfo { [weak self] info in
            Task { @MainActor in
                guard let self else { return }
                let newTitle = info[MediaRemoteKeys.title] as? String ?? ""
                let newArtist = info[MediaRemoteKeys.artist] as? String ?? ""

                if newTitle.isEmpty && newArtist.isEmpty {
                    self.title = "再生中のメディアなし"
                    self.artist = ""
                } else {
                    self.title = newTitle.isEmpty ? "不明なタイトル" : newTitle
                    self.artist = newArtist
                }
            }
        }
    }

    private func refreshPlaybackState() {
        bridge.fetchIsPlaying { [weak self] playing in
            Task { @MainActor in
                self?.isPlaying = playing
            }
        }
    }
}
