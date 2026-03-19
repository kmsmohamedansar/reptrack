import SwiftUI

@MainActor
final class ForgeNoticeCenter: ObservableObject {
    struct Notice: Identifiable, Equatable {
        let id = UUID()
        let message: String
        let kind: Kind

        enum Kind {
            case info
            case error
        }
    }

    @Published var notice: Notice?

    func showInfo(_ message: String) {
        show(message, kind: .info)
    }

    func showError(_ message: String) {
        show(message, kind: .error)
    }

    private func show(_ message: String, kind: Notice.Kind) {
        let new = Notice(message: message, kind: kind)
        notice = new
        Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 2_200_000_000)
            } catch {
                // If the task is cancelled, just stop.
                return
            }
            if notice?.id == new.id {
                notice = nil
            }
        }
    }
}

struct ForgeNoticeBanner: View {
    let notice: ForgeNoticeCenter.Notice

    var body: some View {
        HStack(spacing: ForgeTheme.spaceS) {
            Image(systemName: notice.kind == .error ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(notice.kind == .error ? .red : ForgeTheme.secondaryText)

            Text(notice.message)
                .font(.caption)
                .foregroundStyle(ForgeTheme.primaryText)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, ForgeTheme.spaceM)
        .padding(.vertical, ForgeTheme.spaceS)
        .background(
            RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous)
                .fill(ForgeTheme.cardLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RepTrackDesign.cornerRadiusSmall, style: .continuous)
                .stroke(ForgeTheme.cardLightBorder, lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(notice.kind == .error ? "Error" : "Notice")
        .accessibilityValue(notice.message)
    }
}

extension View {
    func forgeNotices(_ center: ForgeNoticeCenter) -> some View {
        overlay(alignment: .top) {
            if let notice = center.notice {
                ForgeNoticeBanner(notice: notice)
                    .padding(.horizontal, ForgeTheme.gutter)
                    .padding(.top, ForgeTheme.spaceM)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.2), value: center.notice)
            }
        }
    }
}

