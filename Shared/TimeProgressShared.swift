import Foundation

enum TimeProgressShared {
    static var settingsURL: URL {
        let baseURL: URL
        if Bundle.main.bundleIdentifier == "com.hang.TrueTimeProgress" {
            baseURL = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Containers/com.hang.TrueTimeProgress.Widgets/Data/Library/Application Support")
        } else {
            baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        }
        return baseURL
            .appendingPathComponent("TrueTimeProgress", isDirectory: true)
            .appendingPathComponent("settings.json")
    }
}

struct TimeProgressSettings: Codable, Equatable {
    var birthDate: Date
    var lifeExpectancyYears: Int
    var events: [ProgressEvent]

    static var defaults: TimeProgressSettings {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.year = 2000
        components.month = 1
        components.day = 1
        components.hour = 0
        components.minute = 0

        return TimeProgressSettings(
            birthDate: components.date ?? Date(timeIntervalSince1970: 869184000),
            lifeExpectancyYears: 122,
            events: []
        )
    }

    static func load() -> TimeProgressSettings {
        guard let data = try? Data(contentsOf: TimeProgressShared.settingsURL),
              let settings = try? JSONDecoder().decode(TimeProgressSettings.self, from: data) else {
            return .defaults
        }
        return settings.normalized()
    }

    func save() {
        guard let data = try? JSONEncoder().encode(normalized()) else { return }
        let url = TimeProgressShared.settingsURL
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)

        // The macOS app and its sandboxed Widget Extension have separate
        // containers, so keep the widget's copy in sync whenever the app saves.
        if Bundle.main.bundleIdentifier == "com.hang.TrueTimeProgress" {
            let widgetURL = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Containers/com.hang.TrueTimeProgress.WidgetExtension/Data/Library/Application Support")
                .appendingPathComponent("TrueTimeProgress", isDirectory: true)
                .appendingPathComponent("settings.json")
            try? FileManager.default.createDirectory(at: widgetURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? data.write(to: widgetURL, options: .atomic)
        }
    }

    func normalized() -> TimeProgressSettings {
        var copy = self
        copy.lifeExpectancyYears = max(30, min(175, copy.lifeExpectancyYears))
        return copy
    }
}

struct ProgressEvent: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var startDate: Date
    var endDate: Date

    init(id: String = UUID().uuidString, name: String, startDate: Date, endDate: Date) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.startDate = startDate
        self.endDate = endDate
    }

    var displayName: String {
        name.isEmpty ? "未命名事件" : name
    }

    func progress(at date: Date) -> Double {
        intervalProgress(now: date, start: startDate, end: endDate)
    }

    func status(at date: Date) -> EventStatus {
        if date < startDate { return .future }
        if date > endDate { return .completed }
        return .active
    }
}

enum EventStatus: String {
    case future
    case active
    case completed
}

struct ProgressSnapshot {
    let year: Double
    let month: Double
    let week: Double
    let life: Double
    let livedDays: Int
    let remainingDays: Int

    init(now: Date, birthDate: Date, lifeExpectancyYears: Int) {
        let calendar = Calendar.autoupdatingCurrent
        year = intervalProgress(now: now, start: calendar.startOfYear(for: now), end: calendar.startOfNextYear(for: now))
        month = intervalProgress(now: now, start: calendar.startOfMonth(for: now), end: calendar.startOfNextMonth(for: now))
        week = intervalProgress(now: now, start: calendar.startOfWeek(for: now), end: calendar.startOfNextWeek(for: now))

        let lifeStart = calendar.startOfDay(for: birthDate)
        let lifeEnd = calendar.date(byAdding: .year, value: max(1, lifeExpectancyYears), to: lifeStart)
            ?? lifeStart.addingTimeInterval(Double(max(1, lifeExpectancyYears)) * 365.25 * 24 * 60 * 60)
        life = intervalProgress(now: now, start: lifeStart, end: lifeEnd)
        livedDays = max(0, calendar.dateComponents([.day], from: lifeStart, to: now).day ?? 0)
        remainingDays = max(0, calendar.dateComponents([.day], from: now, to: lifeEnd).day ?? 0)
    }
}

func intervalProgress(now: Date, start: Date, end: Date) -> Double {
    let total = end.timeIntervalSince(start)
    guard total > 0 else { return 0 }
    return max(0, min(1, now.timeIntervalSince(start) / total))
}

func percent(_ value: Double, fractionDigits: Int = 1) -> String {
    String(format: "%.\(fractionDigits)f%%", value * 100)
}

extension Calendar {
    func startOfYear(for date: Date) -> Date {
        self.date(from: dateComponents([.year], from: date)) ?? date
    }

    func startOfNextYear(for date: Date) -> Date {
        self.date(byAdding: .year, value: 1, to: startOfYear(for: date)) ?? date
    }

    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }

    func startOfNextMonth(for date: Date) -> Date {
        self.date(byAdding: .month, value: 1, to: startOfMonth(for: date)) ?? date
    }

    func startOfWeek(for date: Date) -> Date {
        var calendar = self
        calendar.firstWeekday = 2
        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))
            ?? calendar.startOfDay(for: date)
    }

    func startOfNextWeek(for date: Date) -> Date {
        self.date(byAdding: .day, value: 7, to: startOfWeek(for: date)) ?? date
    }
}
