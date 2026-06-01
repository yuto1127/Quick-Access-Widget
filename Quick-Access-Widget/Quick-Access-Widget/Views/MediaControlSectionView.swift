//
//  MediaControlSectionView.swift
//  Quick-Access-Widget
//

import SwiftUI

struct MediaControlSectionView: View {
    @Bindable var mediaManager: MediaRemoteManager

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("メディア")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ZStack {
                artworkBackground

                LinearGradient(
                    colors: [
                        Color.black.opacity(mediaManager.hasActiveMedia ? 0.55 : 0.35),
                        Color.black.opacity(mediaManager.hasActiveMedia ? 0.75 : 0.45)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(spacing: 8) {
                    mediaInfo
                    playbackControls
                }
                .padding(10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var artworkBackground: some View {
        if let artwork = mediaManager.artwork {
            Image(nsImage: artwork)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .opacity(0.45)
                .blur(radius: 1)
                .transition(.opacity.animation(.easeInOut(duration: 0.4)))
                .id(artwork.hash)
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.25), Color.gray.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var mediaInfo: some View {
        VStack(spacing: 4) {
            if mediaManager.isPlaying {
                Image(systemName: "waveform")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
                    .symbolEffect(.variableColor.iterative, options: .repeating)
            }

            Text(mediaManager.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .animation(.easeInOut(duration: 0.25), value: mediaManager.title)

            if !mediaManager.artist.isEmpty {
                Text(mediaManager.artist)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .animation(.easeInOut(duration: 0.25), value: mediaManager.artist)
            }

            if !mediaManager.canControl {
                Text("制御不可")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private var playbackControls: some View {
            HStack(spacing: 16) {
            transportButton(systemName: "backward.fill", action: mediaManager.previousTrack)

            Button(action: mediaManager.togglePlayPause) {
                ZStack {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 30))
                        .opacity(mediaManager.isPlaying ? 0 : 1)
                        .scaleEffect(mediaManager.isPlaying ? 0.6 : 1)

                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 30))
                        .opacity(mediaManager.isPlaying ? 1 : 0)
                        .scaleEffect(mediaManager.isPlaying ? 1 : 0.6)
                }
                .foregroundStyle(.white)
                .animation(.spring(response: 0.32, dampingFraction: 0.72), value: mediaManager.isPlaying)
            }
            .buttonStyle(.plain)
                .disabled(!mediaManager.canControl)

            transportButton(systemName: "forward.fill", action: mediaManager.nextTrack)
        }
        .frame(maxWidth: .infinity)
    }

    private func transportButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
        }
        .buttonStyle(.plain)
            .disabled(!mediaManager.canControl)
    }
}
