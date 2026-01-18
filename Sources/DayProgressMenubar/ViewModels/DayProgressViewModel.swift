import Foundation
import ServiceManagement

@MainActor
final class DayProgressViewModel: ObservableObject {
    @Published private(set) var progressValue: Double = 0
    @Published private(set) var percentString = "--"
    @Published private(set) var elapsedString = "--"
    @Published private(set) var remainingString = "--"
    @Published private(set) var weekProgressValue: Double = 0
    @Published private(set) var weekPercentString = "--"
    @Published private(set) var weekElapsedString = "--"
    @Published private(set) var weekRemainingString = "--"
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var isUpdating = false
    @Published private(set) var launchAtLoginEnabled = false
    @Published private(set) var launchAtLoginStatus: LaunchAtLoginStatus = .unknown
    @Published private(set) var launchAtLoginError: String?

    private var timer: Timer?
    private let refreshInterval: TimeInterval = 60

    init() {
        reloadLaunchAtLoginStatus()
        refresh(force: true)
        startTimer()
    }

    deinit {
        timer?.invalidate()
    }

    var menuBarLabel: String {
        if percentString == "--" {
            return "Day"
        }
        return percentString
    }

    func refresh(force: Bool) {
        if !force, let lastUpdated, Date().timeIntervalSince(lastUpdated) < refreshInterval {
            return
        }
        updateSnapshot()
    }

    func reloadLaunchAtLoginStatus() {
        let status = LaunchAtLoginService.status
        launchAtLoginEnabled = status == .enabled
        launchAtLoginStatus = LaunchAtLoginStatus(status: status)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        guard enabled != launchAtLoginEnabled else { return }
        launchAtLoginError = LaunchAtLoginService.setEnabled(enabled)
        reloadLaunchAtLoginStatus()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh(force: false)
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func updateSnapshot() {
        isUpdating = true
        defer { isUpdating = false }

        let snapshot = DayProgressCalculator.snapshot()
        let weekSnapshot = DayProgressCalculator.weekSnapshot()

        progressValue = snapshot.progress
        percentString = "  \(snapshot.percent)%"
        elapsedString = Self.formatDuration(snapshot.elapsed)
        remainingString = Self.formatDuration(snapshot.remaining)

        weekProgressValue = weekSnapshot.progress
        weekPercentString = "\(weekSnapshot.percent)%"
        weekElapsedString = Self.formatDuration(weekSnapshot.elapsed)
        weekRemainingString = Self.formatDuration(weekSnapshot.remaining)

        lastUpdated = Date()
    }

    private static func formatDuration(_ interval: TimeInterval) -> String {
        let totalMinutes = max(0, Int(interval.rounded(.down) / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            let hourLabel = hours == 1 ? "hr" : "hrs"
            return "\(hours) \(hourLabel) \(minutes) min"
        }

        return "\(minutes) min"
    }

    private static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}

enum LaunchAtLoginStatus: String {
    case enabled
    case notRegistered
    case requiresApproval
    case notFound
    case unknown

    init(status: SMAppService.Status) {
        switch status {
        case .enabled:
            self = .enabled
        case .notRegistered:
            self = .notRegistered
        case .requiresApproval:
            self = .requiresApproval
        case .notFound:
            self = .notFound
        @unknown default:
            self = .unknown
        }
    }
}
