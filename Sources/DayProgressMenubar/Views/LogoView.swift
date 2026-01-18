import SwiftUI

struct LogoView: View {
    var body: some View {
        Image(systemName: "clock")
            .renderingMode(.template)
            .foregroundStyle(.primary)
    }
}
