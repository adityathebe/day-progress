import Combine
import Foundation
import ServiceManagement

@MainActor
final class DayProgressViewModel: ObservableObject {
    @Published private(set) var progressValue: Double = 0
    @Published private(set) var percentString = "--"
    @Published private(set) var elapsedString = "--"
    @Published private(set) var remainingString = "--"
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var isUpdating = false
    @Published private(set) var launchAtLoginEnabled = false
    @Published private(set) var launchAtLoginStatus: LaunchAtLoginStatus = .unknown
    @Published private(set) var launchAtLoginError: String?
    @Published private(set) var progressMode: ProgressMode = {
        let raw = UserDefaults.standard.string(forKey: "progressMode") ?? ""
        return ProgressMode(rawValue: raw) ?? .daylight
    }()

    // Location state surfaced to the view
    @Published private(set) var locationError: String?
    @Published private(set) var isWaitingForLocation = false

    private let locationService = LocationService()
    private var locationCancellable: AnyCancellable?
    private var timer: Timer?
    private let refreshInterval: TimeInterval = 60

    init() {
        reloadLaunchAtLoginStatus()

        // Re-snapshot whenever a location fix arrives
        locationCancellable = locationService.$coordinate
            .dropFirst()
            .sink { [weak self] _ in
                self?.updateSnapshot()
                self?.updateLocationState()
            }

        if progressMode == .daylight {
            locationService.requestLocation()
        }

        refresh(force: true)
        startTimer()
    }

    deinit {
        timer?.invalidate()
    }

    var menuBarLabel: String {
        percentString == "--" ? "Day" : percentString
    }

    /// Display label for the mode picker — Daylight shows live sunrise/sunset times once location is known.
    func modeDisplayName(for mode: ProgressMode) -> String {
        switch mode {
        case .workHours:
            return mode.displayName
        case .daylight:
            guard let coordinate = locationService.coordinate,
                let solar = SolarCalculator.solarTimes(for: Date(), coordinate: coordinate)
            else {
                return mode.displayName  // "Daylight (sunrise–sunset)" until location arrives
            }
            let rise = Self.formatTime(solar.sunrise)
            let set  = Self.formatTime(solar.sunset)
            return "Daylight (\(rise)–\(set))"
        }
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

    func setProgressMode(_ mode: ProgressMode) {
        guard mode != progressMode else { return }
        progressMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "progressMode")
        if mode == .daylight {
            locationService.requestLocation()
        }
        updateSnapshot()
        updateLocationState()
    }

    // MARK: - Private

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

        let snapshot = DayProgressCalculator.snapshot(
            mode: progressMode,
            coordinate: locationService.coordinate
        )

        progressValue = snapshot.progress
        percentString = "  \(snapshot.percent)%"
        elapsedString = Self.formatDuration(snapshot.elapsed)
        remainingString = Self.formatDuration(snapshot.remaining)
        lastUpdated = Date()
    }

    private func updateLocationState() {
        guard progressMode == .daylight else {
            locationError = nil
            isWaitingForLocation = false
            return
        }
        locationError = locationService.locationError
        isWaitingForLocation = locationService.coordinate == nil && locationService.locationError == nil
    }

    private static func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
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
}

// MARK: - LaunchAtLoginStatus

enum LaunchAtLoginStatus: String {
    case enabled
    case notRegistered
    case requiresApproval
    case notFound
    case unknown

    init(status: SMAppService.Status) {
        switch status {
        case .enabled:           self = .enabled
        case .notRegistered:     self = .notRegistered
        case .requiresApproval:  self = .requiresApproval
        case .notFound:          self = .notFound
        @unknown default:        self = .unknown
        }
    }
}
