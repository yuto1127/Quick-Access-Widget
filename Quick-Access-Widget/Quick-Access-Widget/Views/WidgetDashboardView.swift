//
//  WidgetDashboardView.swift
//  Quick-Access-Widget
//

import SwiftUI

struct WidgetDashboardView: View {
    let mediaManager: MediaRemoteManager

    var body: some View {
        VStack(spacing: 16) {
            DateTimeSectionView()
            Divider()
            MediaControlSectionView(mediaManager: mediaManager)
            Divider()
            FileShelfSectionView()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
