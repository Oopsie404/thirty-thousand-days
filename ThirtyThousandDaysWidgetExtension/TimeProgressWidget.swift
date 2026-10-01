import SwiftUI
import WidgetKit

struct TimeProgressEntry: TimelineEntry {
    let date: Date
    let settings: TimeProgressSettings
}

struct TimeProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimeProgressEntry {
        TimeProgressEntry(date: Date(), settings: .defaults)
    }

    func getSnapshot(in context: Context, completion: @escaping (TimeProgressEntry) -> Void) {
        completion(TimeProgressEntry(date: Date(), settings: TimeProgressSettings.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimeProgressEntry>) -> Void) {
        let now = Date()
        let settings = TimeProgressSettings.load()
        let entries = (0..<12).map { offset in
            TimeProgressEntry(date: now.addingTimeInterval(Double(offset) * 5 * 60), settings: settings)
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(60 * 60))))
    }
}

struct TimeProgressWidgetView: View {
    let entry: TimeProgressEntry

    var body: some View {
        let snapshot = ProgressSnapshot(
            now: entry.date,
            birthDate: entry.settings.birthDate,
            lifeExpectancyYears: entry.settings.lifeExpectancyYears
        )
        let labels = dateLabels(for: entry.date)

        VStack(spacing: 4) {
            HStack(spacing: 12) {
                RingProgress(title: labels.year, progress: snapshot.year)
                RingProgress(title: labels.month, progress: snapshot.month)
                RingProgress(title: labels.weekday, progress: snapshot.week)
            }
            .offset(y: 3)

            LifeProgress(progress: snapshot.life)
                .frame(height: 70)
                .offset(y: -4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .containerBackground(for: .widget) {
            WidgetDarkBackground()
        }
    }
}

struct RingProgress: View {
    let title: String
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.15), lineWidth: 7)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(.white.opacity(0.72), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(percent(progress))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(.white.opacity(0.72))
            .minimumScaleFactor(0.72)
        }
        .frame(width: 74, height: 74)
        .frame(maxWidth: .infinity)
    }
}

struct LifeProgress: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            let centerX = proxy.size.width / 2

            ZStack {
                SmileArc(progress: 1)
                    .stroke(.white.opacity(0.14), style: StrokeStyle(lineWidth: 7, lineCap: .round))

                SmileArc(progress: progress)
                    .stroke(.white.opacity(0.72), style: StrokeStyle(lineWidth: 7, lineCap: .round))

                Text(percent(progress))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.72))
                    .position(x: centerX, y: 22)

                Text("Life")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .position(x: centerX, y: 64)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

struct SmileArc: Shape {
    let progress: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let start = CGPoint(x: rect.minX + 3, y: rect.minY + 36)
        let end = CGPoint(x: rect.maxX - 3, y: rect.minY + 36)
        let control = CGPoint(x: rect.midX, y: rect.minY + 74)
        let clamped = max(0, min(1, progress))
        let segments = max(2, Int(80 * clamped))

        path.move(to: start)
        for index in 1...segments {
            let t = clamped * Double(index) / Double(segments)
            let oneMinusT = 1 - t
            let x = oneMinusT * oneMinusT * start.x + 2 * oneMinusT * t * control.x + t * t * end.x
            let y = oneMinusT * oneMinusT * start.y + 2 * oneMinusT * t * control.y + t * t * end.y
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }
}

struct WidgetDarkBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.135, green: 0.135, blue: 0.135),
                Color(red: 0.055, green: 0.055, blue: 0.055)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct EventProgressEntry: TimelineEntry {
    let date: Date
    let event: ProgressEvent?
    let index: Int
}

struct EventProgressProvider: TimelineProvider {
    let index: Int

    func placeholder(in context: Context) -> EventProgressEntry {
        let now = Date()
        return EventProgressEntry(
            date: now,
            event: ProgressEvent(name: "事件\(index + 1)", startDate: now.addingTimeInterval(-3600), endDate: now.addingTimeInterval(7200)),
            index: index
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (EventProgressEntry) -> Void) {
        completion(EventProgressEntry(date: Date(), event: selectedEvent(), index: index))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EventProgressEntry>) -> Void) {
        let now = Date()
        let event = selectedEvent()
        let entries = (0..<12).map { offset in
            EventProgressEntry(date: now.addingTimeInterval(Double(offset) * 5 * 60), event: event, index: index)
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(60 * 60))))
    }

    private func selectedEvent() -> ProgressEvent? {
        let settings = TimeProgressSettings.load()
        let availableEvents = settings.events.filter { $0.status(at: Date()) != .completed }
        guard availableEvents.indices.contains(index) else { return nil }
        return availableEvents[index]
    }
}

struct EventProgressWidgetView: View {
    let entry: EventProgressEntry

    var body: some View {
        ZStack {
            if let event = entry.event {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.15), lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: event.progress(at: entry.date))
                            .stroke(.white.opacity(0.74), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        Text(percent(event.progress(at: entry.date)))
                            .font(.system(size: 21, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.76))
                            .minimumScaleFactor(0.66)
                    }
                    .frame(width: 78, height: 78)

                    Text(event.displayName)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                .padding(12)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 30, weight: .medium))
                    Text("事件\(entry.index + 1)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    Text("未设置")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.7))
            }
        }
        .containerBackground(for: .widget) {
            WidgetDarkBackground()
        }
    }
}

struct ThirtyThousandDaysWidget: Widget {
    let kind = "TimeProgressLifeWidgetV2"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimeProgressProvider()) { entry in
            TimeProgressWidgetView(entry: entry)
        }
        .configurationDisplayName("光阴三万")
        .description("显示年、月、周和人生进度。")
        .supportedFamilies([.systemMedium])
    }
}

struct EventOneProgressWidget: Widget {
    let kind = "TimeProgressEventOneWidgetV2"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EventProgressProvider(index: 0)) { entry in
            EventProgressWidgetView(entry: entry)
        }
        .configurationDisplayName("事件1进度")
        .description("显示软件里第1个自定义事件的圆形进度。")
        .supportedFamilies([.systemSmall])
    }
}

struct EventTwoProgressWidget: Widget {
    let kind = "TimeProgressEventTwoWidgetV2"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EventProgressProvider(index: 1)) { entry in
            EventProgressWidgetView(entry: entry)
        }
        .configurationDisplayName("事件2进度")
        .description("显示软件里第2个自定义事件的圆形进度。")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct ThirtyThousandDaysWidgetBundle: WidgetBundle {
    var body: some Widget {
        ThirtyThousandDaysWidget()
        EventOneProgressWidget()
        EventTwoProgressWidget()
    }
}

private func dateLabels(for date: Date) -> (year: String, month: String, weekday: String) {
    let calendar = Calendar.autoupdatingCurrent
    let year = String(calendar.component(.year, from: date))
    let month = "\(calendar.component(.month, from: date))月"
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "EEE"
    return (year, month, formatter.string(from: date))
}
