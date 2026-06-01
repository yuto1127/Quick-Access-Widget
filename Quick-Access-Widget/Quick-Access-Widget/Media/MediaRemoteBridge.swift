//
//  MediaRemoteBridge.swift
//  Quick-Access-Widget
//

import AppKit
import Foundation

enum MRCommand: UInt32 {
    case play = 0
    case pause = 1
    case togglePlayPause = 2
    case stop = 3
    case nextTrack = 4
    case previousTrack = 5
}

enum MRPlaybackState: UInt32 {
    case stopped = 0
    case playing = 1
    case paused = 2
    case interrupted = 3
}

enum MediaRemoteKeys {
    static let nowPlayingInfoDidChange = "kMRMediaRemoteNowPlayingInfoDidChangeNotification"
    static let playbackDidChange = "kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification"
    static let applicationDidChange = "kMRMediaRemoteNowPlayingApplicationDidChangeNotification"
    static let title = "kMRMediaRemoteNowPlayingInfoTitle"
    static let artist = "kMRMediaRemoteNowPlayingInfoArtist"
    static let album = "kMRMediaRemoteNowPlayingInfoAlbum"
    static let artworkData = "kMRMediaRemoteNowPlayingInfoArtworkData"
}

struct NowPlayingSnapshot {
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var artwork: NSImage?
    var playbackState: MRPlaybackState = .stopped
    var isPlaying: Bool { playbackState == .playing }

    var hasMedia: Bool {
        !title.isEmpty || !artist.isEmpty || artwork != nil
    }
}

final class MediaRemoteBridge {
    private var handle: UnsafeMutableRawPointer?

    typealias RegisterFunc = @convention(c) (DispatchQueue?) -> Void
    typealias UnregisterFunc = @convention(c) () -> Void
    typealias GetNowPlayingInfoFunc = @convention(c) (DispatchQueue?, @escaping (CFDictionary?) -> Void) -> Void
    typealias GetPlaybackStateFunc = @convention(c) (DispatchQueue?, @escaping (UInt32) -> Void) -> Void
    typealias SendCommandFunc = @convention(c) (UInt32, UnsafeRawPointer?) -> Void

    private var registerForNotifications: RegisterFunc?
    private var unregisterForNotifications: UnregisterFunc?
    private var getNowPlayingInfo: GetNowPlayingInfoFunc?
    private var getPlaybackState: GetPlaybackStateFunc?
    private var sendCommand: SendCommandFunc?

    var isAvailable: Bool { handle != nil && registerForNotifications != nil }

    init() {
        handle = dlopen(
            "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
            RTLD_LAZY
        )
        guard let handle else { return }

        registerForNotifications = loadSymbol(handle, "MRMediaRemoteRegisterForNowPlayingNotifications")
        unregisterForNotifications = loadSymbol(handle, "MRMediaRemoteUnregisterForNowPlayingNotifications")
        getNowPlayingInfo = loadSymbol(handle, "MRMediaRemoteGetNowPlayingInfo")
        getPlaybackState = loadSymbol(handle, "MRMediaRemoteGetNowPlayingApplicationPlaybackState")
        sendCommand = loadSymbol(handle, "MRMediaRemoteSendCommand")
    }

    deinit {
        if let handle {
            dlclose(handle)
        }
    }

    func registerNotifications(on queue: DispatchQueue?) {
        registerForNotifications?(queue)
    }

    func unregisterNotifications() {
        unregisterForNotifications?()
    }

    func fetchSnapshot(completion: @escaping (NowPlayingSnapshot) -> Void) {
        let group = DispatchGroup()
        var snapshot = NowPlayingSnapshot()

        group.enter()
        fetchNowPlayingInfo { info in
            snapshot.title = Self.string(from: info, keys: [MediaRemoteKeys.title, "title"])
            snapshot.artist = Self.string(from: info, keys: [MediaRemoteKeys.artist, "artist"])
            snapshot.album = Self.string(from: info, keys: [MediaRemoteKeys.album, "album"])
            snapshot.artwork = Self.artwork(from: info)
            group.leave()
        }

        group.enter()
        fetchPlaybackState { state in
            snapshot.playbackState = state
            group.leave()
        }

        group.notify(queue: .global(qos: .userInitiated)) {
            completion(snapshot)
        }
    }

    func send(_ command: MRCommand) {
        sendCommand?(command.rawValue, nil)
    }

    private func fetchNowPlayingInfo(completion: @escaping ([AnyHashable: Any]) -> Void) {
        guard let getNowPlayingInfo else {
            completion([:])
            return
        }

        getNowPlayingInfo(DispatchQueue.global(qos: .userInitiated)) { info in
            let dictionary = (info as NSDictionary?) as? [AnyHashable: Any] ?? [:]
            completion(dictionary)
        }
    }

    private func fetchPlaybackState(completion: @escaping (MRPlaybackState) -> Void) {
        guard let getPlaybackState else {
            completion(.stopped)
            return
        }

        getPlaybackState(DispatchQueue.global(qos: .userInitiated)) { rawState in
            completion(MRPlaybackState(rawValue: rawState) ?? .stopped)
        }
    }

    private static func string(from info: [AnyHashable: Any], keys: [String]) -> String {
        for key in keys {
            if let value = info[key] as? String, !value.isEmpty {
                return value
            }
            if let value = info[AnyHashable(key)] as? String, !value.isEmpty {
                return value
            }
        }

        for (key, value) in info {
            guard let keyString = key as? String else { continue }
            guard keys.contains(where: { keyString.contains($0) || $0.contains(keyString) }) else { continue }
            if let string = value as? String, !string.isEmpty {
                return string
            }
        }

        return ""
    }

    private static func artwork(from info: [AnyHashable: Any]) -> NSImage? {
        let artworkKeys = [
            MediaRemoteKeys.artworkData,
            "kMRMediaRemoteNowPlayingInfoArtworkData",
            "artworkData"
        ]

        for key in artworkKeys {
            if let data = info[key] as? Data, let image = NSImage(data: data) {
                return image
            }
            if let data = info[AnyHashable(key)] as? Data, let image = NSImage(data: data) {
                return image
            }
        }

        for (key, value) in info {
            guard let keyString = key as? String, keyString.localizedCaseInsensitiveContains("artwork") else {
                continue
            }
            if let data = value as? Data, let image = NSImage(data: data) {
                return image
            }
        }

        return nil
    }

    private func loadSymbol<T>(_ handle: UnsafeMutableRawPointer, _ name: String) -> T? {
        guard let symbol = dlsym(handle, name) else { return nil }
        return unsafeBitCast(symbol, to: T.self)
    }
}
