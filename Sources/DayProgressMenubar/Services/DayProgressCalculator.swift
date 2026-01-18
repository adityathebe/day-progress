import Foundation

struct DayProgressSnapshot {
    let progress: Double
    let percent: Int
    let elapsed: TimeInterval
    let remaining: TimeInterval
    let start: Date
    let end: Date
    let displayEnd: Date
}

struct WeekProgressSnapshot {
    let progress: Double
    let percent: Int
    let elapsed: TimeInterval
    let remaining: TimeInterval
    let start: Date
    let end: Date
    let displayEnd: Date
}

enum DayProgressCalculator {
    static func snapshot(now: Date = Date(), calendar: Calendar = .current) -> DayProgressSnapshot {
        let start = calendar.startOfDay(for: now)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            return DayProgressSnapshot(
                progress: 0,
                percent: 0,
                elapsed: 0,
                remaining: 0,
                start: start,
                end: start,
                displayEnd: start
            )
        }

        let total = end.timeIntervalSince(start)
        let elapsed = min(max(now.timeIntervalSince(start), 0), total)
        let remaining = max(0, end.timeIntervalSince(now))
        let progress = total > 0 ? elapsed / total : 0
        let percent = Int((progress * 100).rounded())
        let displayEnd = calendar.date(byAdding: .second, value: -1, to: end) ?? end

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

    static func weekSnapshot(now: Date = Date(), calendar: Calendar = .current) -> WeekProgressSnapshot {
        // Get the start of the week (Sunday or Monday depending on calendar)
        var weekCalendar = calendar
        weekCalendar.firstWeekday = 2 // Start week on Monday

        guard let start = weekCalendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            let fallbackStart = calendar.startOfDay(for: now)
            return WeekProgressSnapshot(
                progress: 0,
                percent: 0,
                elapsed: 0,
                remaining: 0,
                start: fallbackStart,
                end: fallbackStart,
                displayEnd: fallbackStart
            )
        }

        guard let end = weekCalendar.date(byAdding: .weekOfYear, value: 1, to: start) else {
            return WeekProgressSnapshot(
                progress: 0,
                percent: 0,
                elapsed: 0,
                remaining: 0,
                start: start,
                end: start,
                displayEnd: start
            )
        }

        let total = end.timeIntervalSince(start)
        let elapsed = min(max(now.timeIntervalSince(start), 0), total)
        let remaining = max(0, end.timeIntervalSince(now))
        let progress = total > 0 ? elapsed / total : 0
        let percent = Int((progress * 100).rounded())
        let displayEnd = calendar.date(byAdding: .second, value: -1, to: end) ?? end

        return WeekProgressSnapshot(
            progress: min(max(progress, 0), 1),
            percent: min(max(percent, 0), 100),
            elapsed: elapsed,
            remaining: remaining,
            start: start,
            end: end,
            displayEnd: displayEnd
        )
    }
}
