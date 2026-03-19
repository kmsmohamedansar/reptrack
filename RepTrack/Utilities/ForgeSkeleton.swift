import SwiftUI

struct ForgeSkeletonLine: View {
    var width: CGFloat? = nil
    var height: CGFloat = 10

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
            .fill(Color(.tertiarySystemFill))
            .frame(maxWidth: width == nil ? .infinity : width, minHeight: height, maxHeight: height)
    }
}

struct ForgeSkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.spaceM) {
            ForgeSkeletonLine(width: 160, height: 14)
            ForgeSkeletonLine(height: 12)
            ForgeSkeletonLine(width: 220, height: 12)

            HStack(spacing: ForgeTheme.spaceS) {
                ForgeSkeletonLine(width: 70, height: 10)
                ForgeSkeletonLine(width: 70, height: 10)
            }
        }
        .padding(ForgeTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .forgeCard()
        .redacted(reason: .placeholder)
    }
}

