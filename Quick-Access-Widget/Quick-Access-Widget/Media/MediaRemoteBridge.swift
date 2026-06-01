//
//  MediaRemoteBridge.swift
//  Quick-Access-Widget
//

import Foundation

enum MRCommand: UInt32 {
    case play = 0
    case pause = 1
    case togglePlayPause = 2
    case stop = 3
    case nextTrack = 4
    case previousTrack = 5
}

enum MediaRemoteKeys {
    static let nowPlayingInfoDidChange = "kMRMediaRemoteNowPlayingInfoDidChangeNotification"
    static let playbackDidChange = "kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification"
    static let title = "kMRMediaRemoteNowPlayingInfoTitle"
    static let artist = "kMRMediaRemoteNowPlayingInfoArtist"
    static let album = "kMRMediaRemoteNowPlayingInfoAlbum"
}

final class MediaRemoteBridge {
    private var handle: UnsafeMutableRawPointer?

    typealias RegisterFunc = @convention(c) (DispatchQueue?) -> Void
    typealias UnregisterFunc = @convention(c) () -> Void
    typealias GetNowPlayingInfoFunc = @convention(c) (DispatchQueue?, @escaping (CFDictionary?) -> Void) -> Void
    typealias GetIsPlayingFunc = @convention(c) (DispatchQueue?, @escaping (Bool) -> Void) -> Void
    typealias SendCommandFunc = @convention(c) (UInt32, UnsafeRawPointer?) -> Void

    private var registerForNotifications: RegisterFunc?
    private var unregisterForNotifications: UnregisterFunc?
    private var getNowPlayingInfo: GetNowPlayingInfoFunc?
    private var getIsPlaying: GetIsPlayingFunc?
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
        getIsPlaying = loadSymbol(handle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying")
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

    func fetchNowPlayingInfo(completion: @escaping ([String: Any]) -> Void) {
        guard let getNowPlayingInfo else {
            completion([:])
            return
        }

        getNowPlayingInfo(DispatchQueue.global(qos: .userInitiated)) { info in
            let dictionary = info as? [String: Any] ?? [:]
            completion(dictionary)
        }
    }

    func fetchIsPlaying(completion: @escaping (Bool) -> Void) {
        guard let getIsPlaying else {
            completion(false)
            return
        }

        getIsPlaying(DispatchQueue.global(qos: .userInitiated)) { isPlaying in
            completion(isPlaying)
        }
    }

    func send(_ command: MRCommand) {
        sendCommand?(command.rawValue, nil)
    }

    private func loadSymbol<T>(_ handle: UnsafeMutableRawPointer, _ name: String) -> T? {
        guard let symbol = dlsym(handle, name) else { return nil }
        return unsafeBitCast(symbol, to: T.self)
    }
}
