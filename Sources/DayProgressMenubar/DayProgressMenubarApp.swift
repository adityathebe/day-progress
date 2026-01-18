import SwiftUI

@main
struct DayProgressMenubarApp: App {
    @StateObject private var progress = DayProgressViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(progress: progress)
        } label: {
            MenuBarProgressView(
                progress: progress.progressValue,
                percentText: progress.menuBarLabel
            )
        }
        .menuBarExtraStyle(.menu)
    }
}
