//
//  AppleScriptNowPlaying.swift
//  Quick-Access-Widget
//

import AppKit
import Foundation

enum ScriptPlayerKind: String {
    case spotify = "Spotify"
    case music = "Music"
}

struct ScriptNowPlaying {
    var kind: ScriptPlayerKind
    var title: String
    var artist: String
    var album: String
    var isPlaying: Bool
    var artwork: NSImage?
}

enum AppleScriptNowPlaying {
    static func debugFetchErrors() -> String? {
        // Try Spotify first, then Music, and return the first error message we see.
        if isRunning(bundleId: "com.spotify.client", appName: "Spotify") {
            let out = run(command: .spotify, script: "player state as string")
            if let err = out.errorMessage { return "Spotify: \(err)" }
        }
        if isRunning(bundleId: "com.apple.Music", appName: "Music") {
            let out = run(command: .music, script: "player state as string")
            if let err = out.errorMessage { return "Music: \(err)" }
        }
        return nil
    }

    static func fetchPreferred() -> ScriptNowPlaying? {
        // Prefer the player that is actively playing.
        let spotify = fetchSpotify()
        let music = fetchMusic()

        if let s = spotify, s.isPlaying { return s }
        if let m = music, m.isPlaying { return m }
        return spotify ?? music
    }

    static func playPause(prefer kind: ScriptPlayerKind?) {
        if let kind {
            run(command: kind, script: "playpause")
            return
        }
        // Try both.
        _ = run(command: .spotify, script: "playpause")
        _ = run(command: .music, script: "playpause")
    }

    static func nextTrack(prefer kind: ScriptPlayerKind?) {
        if let kind {
            run(command: kind, script: "next track")
            return
        }
        _ = run(command: .spotify, script: "next track")
        _ = run(command: .music, script: "next track")
    }

    static func previousTrack(prefer kind: ScriptPlayerKind?) {
        if let kind {
            run(command: kind, script: "previous track")
            return
        }
        _ = run(command: .spotify, script: "previous track")
        _ = run(command: .music, script: "previous track")
    }

    // MARK: - Spotify

    private static func fetchSpotify() -> ScriptNowPlaying? {
        guard isRunning(bundleId: "com.spotify.client", appName: "Spotify") else { return nil }

        let stateOut = run(command: .spotify, script: "player state as string")
        let state = stateOut.stringValue
        let isPlaying = (state == "playing")

        let titleOut = run(command: .spotify, script: "name of current track")
        let artistOut = run(command: .spotify, script: "artist of current track")
        let albumOut = run(command: .spotify, script: "album of current track")
        let artworkOut = run(command: .spotify, script: "artwork url of current track")

        let title = titleOut.stringValue
        let artist = artistOut.stringValue
        let album = albumOut.stringValue
        let artworkURLString = artworkOut.stringValue.isEmpty ? nil : artworkOut.stringValue

        // If automation permission is missing, AppleScript returns an error; surface it via empty metadata.
        let anyError = [stateOut, titleOut, artistOut, albumOut, artworkOut].compactMap(\.errorMessage).first
        if anyError != nil {
            return ScriptNowPlaying(
                kind: .spotify,
                title: "",
                artist: "",
                album: "",
                isPlaying: false,
                artwork: nil
            )
            // NOTE: Error message will be surfaced by MediaRemoteManager debugStatus.
        }

        let artwork: NSImage?
        if let artworkURLString,
           let url = URL(string: artworkURLString),
           let image = NSImage(contentsOf: url) {
            artwork = image
        } else {
            artwork = nil
        }

        return ScriptNowPlaying(
            kind: .spotify,
            title: title,
            artist: artist,
            album: album,
            isPlaying: isPlaying,
            artwork: artwork
        )
    }

    // MARK: - Music

    private static func fetchMusic() -> ScriptNowPlaying? {
        guard isRunning(bundleId: "com.apple.Music", appName: "Music") else { return nil }

        let stateOut = run(command: .music, script: "player state as string")
        let state = stateOut.stringValue
        let isPlaying = (state == "playing")

        let titleOut = run(command: .music, script: "name of current track")
        let artistOut = run(command: .music, script: "artist of current track")
        let albumOut = run(command: .music, script: "album of current track")

        let title = titleOut.stringValue
        let artist = artistOut.stringValue
        let album = albumOut.stringValue

        // Artwork data can fail depending on track; tolerate nil.
        let artworkOut = run(command: .music, script: "try\n  data of artwork 1 of current track\non error\n  return \"\"\nend try")
        let artworkData = artworkOut.dataValue
        let artwork = artworkData.flatMap { NSImage(data: $0) }

        let anyError = [stateOut, titleOut, artistOut, albumOut, artworkOut].compactMap(\.errorMessage).first
        if anyError != nil {
            return ScriptNowPlaying(kind: .music, title: "", artist: "", album: "", isPlaying: false, artwork: nil)
        }

        return ScriptNowPlaying(
            kind: .music,
            title: title,
            artist: artist,
            album: album,
            isPlaying: isPlaying,
            artwork: artwork
        )
    }

    // MARK: - Helpers

    private static func isRunning(bundleId: String, appName: String) -> Bool {
        if !NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).isEmpty {
            return true
        }
        // bundle id が取得できない環境向けのフォールバック
        return NSWorkspace.shared.runningApplications.contains { app in
            app.localizedName == appName
        }
    }

    private struct ScriptOutput {
        var value: Any?
        var errorMessage: String?

        var stringValue: String {
            (value as? String) ?? ""
        }

        var dataValue: Data? {
            value as? Data
        }
    }

    private static func run(command: ScriptPlayerKind, script: String) -> ScriptOutput {
        let source = """
        tell application \"\(command.rawValue)\"
          if it is running then
            \(script)
          else
            return \"\"
          end if
        end tell
        """

        var error: NSDictionary?
        let appleScript = NSAppleScript(source: source)
        let output = appleScript?.executeAndReturnError(&error)
        if let error {
            let message = (error[NSAppleScript.errorMessage] as? String)
                ?? (error[NSAppleScript.errorNumber] as? NSNumber).map { "\($0)" }
                ?? "unknown"
            return ScriptOutput(value: nil, errorMessage: message)
        }
        return ScriptOutput(value: coerce(output), errorMessage: nil)
    }

    private static func coerce(_ desc: NSAppleEventDescriptor?) -> Any? {
        guard let desc else { return nil }

        // string
        if let s = desc.stringValue, !s.isEmpty { return s }

        // data
        if desc.descriptorType == typeData {
            return desc.data
        }

        // number
        if desc.descriptorType == typeSInt32 {
            return desc.int32Value
        }
        if desc.descriptorType == typeIEEE64BitFloatingPoint {
            return desc.doubleValue
        }

        return desc.stringValue
    }
}

