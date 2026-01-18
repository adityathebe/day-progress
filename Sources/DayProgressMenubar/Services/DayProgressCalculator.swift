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
}
