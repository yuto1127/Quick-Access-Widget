//
//  WidgetDashboardView.swift
//  Quick-Access-Widget
//

import SwiftUI

struct WidgetDashboardView: View {
    let mediaManager: MediaRemoteManager

    var body: some View {
        VStack(spacing: 10) {
            DateTimeSectionView()

            Divider()

            HStack(alignment: .top, spacing: 10) {
                FileShelfSectionView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                MediaControlSectionView(mediaManager: mediaManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
