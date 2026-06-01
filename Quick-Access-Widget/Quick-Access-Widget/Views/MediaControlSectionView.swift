//
//  MediaControlSectionView.swift
//  Quick-Access-Widget
//

import SwiftUI

struct MediaControlSectionView: View {
    @Bindable var mediaManager: MediaRemoteManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("メディア")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Image(systemName: mediaManager.isPlaying ? "waveform" : "waveform.slash")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(mediaManager.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                if !mediaManager.artist.isEmpty {
                    Text(mediaManager.artist)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
            }

            if !mediaManager.isAvailable {
                Text("MediaRemote 不可")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            HStack(spacing: 16) {
                Button(action: mediaManager.previousTrack) {
                    Image(systemName: "backward.fill")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .disabled(!mediaManager.isAvailable)

                Button(action: mediaManager.togglePlayPause) {
                    Image(systemName: mediaManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 26))
                }
                .buttonStyle(.plain)
                .disabled(!mediaManager.isAvailable)

                Button(action: mediaManager.nextTrack) {
                    Image(systemName: "forward.fill")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .disabled(!mediaManager.isAvailable)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
