import AppKit
import SwiftUI

struct MenuContentView: View {
    @ObservedObject var progress: DayProgressViewModel

    var body: some View {
        Group {
            Text("Elapsed: \(progress.elapsedString)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Remaining: \(progress.remainingString)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Toggle("Launch at Login", isOn: launchAtLoginBinding)

            if progress.launchAtLoginStatus == .requiresApproval {
                Text("Approve in System Settings -> General -> Login Items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = progress.launchAtLoginError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button("Quit Day Progress") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .onAppear {
            progress.refresh(force: true)
            progress.reloadLaunchAtLoginStatus()
        }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { progress.launchAtLoginEnabled },
            set: { progress.setLaunchAtLogin($0) }
        )
    }
}
