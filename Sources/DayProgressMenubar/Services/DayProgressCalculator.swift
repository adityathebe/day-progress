import CoreLocation
import Foundation

// MARK: - Progress Mode

enum ProgressMode: String, CaseIterable {
    case daylight = "daylight"
    case workHours = "workHours"

    var displayName: String {
        switch self {
        case .daylight: return "Daylight (sunrise–sunset)"
        case .workHours: return "Work Hours (10am–8pm)"
        }
    }
}

// MARK: - Snapshot

struct DayProgressSnapshot {
    let progress: Double
    let percent: Int
    let elapsed: TimeInterval
    let remaining: TimeInterval
    let start: Date
    let end: Date
    let displayEnd: Date
}

// MARK: - Calculator

enum DayProgressCalculator {
    /// Work day: 10:00 AM – 8:00 PM
    private static let workDayStartHour = 10
    private static let workDayEndHour = 20

    static func snapshot(
        mode: ProgressMode,
        coordinate: CLLocationCoordinate2D? = nil,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> DayProgressSnapshot {
        switch mode {
        case .daylight:
            return daylightSnapshot(now: now, coordinate: coordinate, calendar: calendar)
        case .workHours:
            return workHoursSnapshot(now: now, calendar: calendar)
        }
    }

    // MARK: - Private

    private static func daylightSnapshot(
        now: Date, coordinate: CLLocationCoordinate2D?, calendar: Calendar
    ) -> DayProgressSnapshot {
        guard let coordinate,
            let solar = SolarCalculator.solarTimes(for: now, coordinate: coordinate)
        else {
            // No location yet, or polar region — show 0 as a neutral placeholder
            return emptySnapshot(anchor: calendar.startOfDay(for: now))
        }
        return makeSnapshot(now: now, start: solar.sunrise, end: solar.sunset,
                            displayEnd: solar.sunset)
    }

    private static func workHoursSnapshot(now: Date, calendar: Calendar) -> DayProgressSnapshot {
        let dayStart = calendar.startOfDay(for: now)

        var startComps = calendar.dateComponents([.year, .month, .day], from: dayStart)
        startComps.hour = workDayStartHour
        startComps.minute = 0
        startComps.second = 0

        var endComps = calendar.dateComponents([.year, .month, .day], from: dayStart)
        endComps.hour = workDayEndHour
        endComps.minute = 0
        endComps.second = 0

        guard let start = calendar.date(from: startComps),
            let end = calendar.date(from: endComps)
        else {
            return emptySnapshot(anchor: dayStart)
        }

        return makeSnapshot(now: now, start: start, end: end, displayEnd: end)
    }

    private static func makeSnapshot(now: Date, start: Date, end: Date, displayEnd: Date)
        -> DayProgressSnapshot
    {
        let total = end.timeIntervalSince(start)
        let elapsed = min(max(now.timeIntervalSince(start), 0), total)
        let remaining = max(0, end.timeIntervalSince(now))
        let progress = total > 0 ? elapsed / total : 0
        let percent = Int((progress * 100).rounded())

        return DayProgressSnapshot(
            progress: min(max(progress, 0), 1),
            percent: min(max(percent, 0), 100),
            elapsed: elapsed,
            remaining: remaining,
            start: start,
            end: end,
            displayEnd: displayEnd
        )
    }

    private static func emptySnapshot(anchor: Date) -> DayProgressSnapshot {
        DayProgressSnapshot(
            progress: 0, percent: 0, elapsed: 0, remaining: 0,
            start: anchor, end: anchor, displayEnd: anchor)
    }
}
