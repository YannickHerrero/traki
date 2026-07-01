import SwiftUI
import TrakiKit

/// The translucent bottom tab bar: four icon+label items, a top hairline, and a
/// blurred fill that bleeds under the home indicator. The active item uses
/// `palette.text`, idle items `palette.dim`.
///
/// The blur is today's stand-in for iOS 26 Liquid Glass; when the deployment
/// target moves up, only this fill needs to adopt the glass material.
struct TrakiTabBar: View {
    @Environment(\.palette) private var palette
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 22, weight: .semibold))
                        Text(tab.title)
                            .font(.barlow(10.5, .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(selection == tab ? palette.text : palette.dim)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 10)
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
        .background {
            palette.tabbar
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            palette.hair.frame(height: 1)
        }
    }
}
