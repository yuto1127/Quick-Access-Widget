//
//  DateTimeSectionView.swift
//  Quick-Access-Widget
//

import SwiftUI

struct DateTimeSectionView: View {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Self.dateFormatter.string(from: context.date))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text(Self.weekdayFormatter.string(from: context.date))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer(minLength: 8)

                Text(Self.timeFormatter.string(from: context.date))
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity)
        }
    }
}
