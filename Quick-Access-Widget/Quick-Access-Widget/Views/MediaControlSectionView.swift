//
//  MediaControlSectionView.swift
//  Quick-Access-Widget
//

import SwiftUI

struct MediaControlSectionView: View {
    @Bindable var mediaManager: MediaRemoteManager

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: mediaManager.isPlaying ? "waveform" : "waveform.slash")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(mediaManager.title)
                        .font(.headline)
                        .lineLimit(1)

                    if !mediaManager.artist.isEmpty {
                        Text(mediaManager.artist)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }

            if !mediaManager.isAvailable {
                Text("MediaRemote を利用できません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 24) {
                Button(action: mediaManager.previousTrack) {
                    Image(systemName: "backward.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(!mediaManager.isAvailable)

                Button(action: mediaManager.togglePlayPause) {
                    Image(systemName: mediaManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                }
                .buttonStyle(.plain)
                .disabled(!mediaManager.isAvailable)

                Button(action: mediaManager.nextTrack) {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(!mediaManager.isAvailable)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
