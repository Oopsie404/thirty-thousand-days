import SwiftUI
import WidgetKit

struct ContentView: View {
    @State private var settings = TimeProgressSettings.load()
    @State private var draftName = ""
    @State private var draftStart = Date()
    @State private var draftEnd = Date().addingTimeInterval(60 * 60 * 24)

    private var snapshot: ProgressSnapshot {
        ProgressSnapshot(
            now: Date(),
            birthDate: settings.birthDate,
            lifeExpectancyYears: settings.lifeExpectancyYears
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("光阴三万")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.primary)

                LifeOverviewCard(settings: $settings, snapshot: snapshot, save: saveSettings)

                HStack(alignment: .top, spacing: 14) {
                    EventsListCard(settings: $settings, save: saveSettings)

                    AddEventCard(
                        name: $draftName,
                        startDate: $draftStart,
                        endDate: $draftEnd,
                        addEvent: addEvent
                    )
                }
            }
            .padding(22)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            settings = TimeProgressSettings.load()
        }
    }

    private func saveSettings() {
        settings = settings.normalized()
        settings.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func addEvent() {
        let cleanName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }

        let start = draftStart
        let end = max(draftEnd, draftStart.addingTimeInterval(60))
        settings.events.append(ProgressEvent(name: cleanName, startDate: start, endDate: end))
        draftName = ""
        draftStart = Date()
        draftEnd = Date().addingTimeInterval(60 * 60 * 24)
        saveSettings()
    }
}

struct SidebarView: View {
    let settings: TimeProgressSettings
    @Binding var selectedSection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 7)
                    .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                Text("光阴三万")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.purple)
            }
            .padding(.top, 28)

            SidebarButton(
                icon: "house",
                title: "人生进度",
                isSelected: selectedSection == "life"
            ) {
                selectedSection = "life"
            }

            Text("自定义事件")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.top, 6)

            SidebarStat(icon: "list.bullet", title: "所有事件", count: settings.events.count, color: .purple)
            SidebarStat(icon: "circle.fill", title: "进行中", count: eventCount(.active), color: .purple)
            SidebarStat(icon: "circle.fill", title: "已完成", count: eventCount(.completed), color: .purple)
            SidebarStat(icon: "clock", title: "未来事件", count: eventCount(.future), color: .secondary)

            Spacer()

            Button {
                selectedSection = "events"
            } label: {
                Label("添加事件", systemImage: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .controlSize(.large)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 22)
        .frame(width: 230)
        .background(.thinMaterial)
    }

    private func eventCount(_ status: EventStatus) -> Int {
        settings.events.filter { $0.status(at: Date()) == status }.count
    }
}

struct SidebarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(isSelected ? Color.purple.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .purple : .primary)
    }
}

struct SidebarStat: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 18)
            Text(title)
                .font(.system(size: 14))
            Spacer()
            Text("\(count)")
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.05), in: Capsule())
        }
        .padding(.horizontal, 10)
    }
}

struct LifeOverviewCard: View {
    @Binding var settings: TimeProgressSettings
    let snapshot: ProgressSnapshot
    let save: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            HStack(alignment: .top, spacing: 32) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("出生日期", systemImage: "calendar")
                        .font(.system(size: 13, weight: .semibold))
                    DatePicker("", selection: $settings.birthDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .onChange(of: settings.birthDate) { _, _ in save() }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 10) {
                    Label("期望寿命", systemImage: "heart")
                        .font(.system(size: 13, weight: .semibold))

                    HStack(spacing: 14) {
                        VStack(spacing: 6) {
                            Slider(
                                value: Binding(
                                    get: { Double(settings.lifeExpectancyYears) },
                                    set: { settings.lifeExpectancyYears = Int($0.rounded()) }
                                ),
                                in: 30...175,
                                step: 1
                            ) {
                                Text("期望寿命")
                            }
                            .tint(.purple)
                            .onChange(of: settings.lifeExpectancyYears) { _, _ in save() }

                            HStack {
                                Text("30岁")
                                Spacer()
                                Text("175岁")
                            }
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        }

                        TextField(
                            "寿命",
                            value: $settings.lifeExpectancyYears,
                            formatter: NumberFormatter.lifeYears
                        )
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 72)
                        .onSubmit(save)

                        Text("岁")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: 7) {
                Text("人生进度")
                    .font(.system(size: 15, weight: .semibold))

                Text(percent(snapshot.life))
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                    .monospacedDigit()

                ProgressView(value: snapshot.life)
                    .tint(.purple)
                    .scaleEffect(x: 1, y: 1.4, anchor: .center)

                Text("你的人生已完成 \(percent(snapshot.life))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 14) {
                MetricCard(icon: "calendar", title: "已来地球", value: "\(snapshot.livedDays.formatted()) 天", detail: yearsMonthsDays(fromDays: snapshot.livedDays), color: .purple)
                MetricCard(icon: "hourglass", title: "预计再停留", value: "\(snapshot.remainingDays.formatted()) 天", detail: yearsMonthsDays(fromDays: snapshot.remainingDays), color: .purple)
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08))
        }
    }
}

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let detail: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.07))
        }
    }
}

struct EventsListCard: View {
    @Binding var settings: TimeProgressSettings
    let save: () -> Void

    var body: some View {
        let now = Date()
        let activeEvents = settings.events.filter { $0.status(at: now) != .completed }
        let completedEvents = settings.events.filter { $0.status(at: now) == .completed }

        VStack(alignment: .leading, spacing: 12) {
            Text("自定义事件")
                .font(.system(size: 16, weight: .semibold))

            if activeEvents.isEmpty {
                ContentUnavailableView("还没有进行中的事件", systemImage: "list.bullet.rectangle", description: Text("右侧添加后，可以在小号事件小组件里选择。"))
                    .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(activeEvents.enumerated()), id: \.element.id) { index, event in
                        EventRow(
                            event: event,
                            number: index + 1,
                            showsStatus: true,
                            moveUp: index > 0 ? { move(event, toward: activeEvents[index - 1]) } : nil,
                            moveDown: index + 1 < activeEvents.count ? { move(event, toward: activeEvents[index + 1]) } : nil
                        ) {
                            settings.events.removeAll { $0.id == event.id }
                            save()
                        }
                    }
                }
            }

            if !completedEvents.isEmpty {
                Divider().padding(.vertical, 4)
                Text("已完成事件")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.purple)
                VStack(spacing: 8) {
                    ForEach(Array(completedEvents.enumerated()), id: \.element.id) { index, event in
                        EventRow(event: event, number: index + 1, showsStatus: false, moveUp: nil, moveDown: nil) {
                            settings.events.removeAll { $0.id == event.id }
                            save()
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08))
        }
    }

    private func move(_ event: ProgressEvent, toward other: ProgressEvent) {
        guard let from = settings.events.firstIndex(where: { $0.id == event.id }),
              let to = settings.events.firstIndex(where: { $0.id == other.id }) else { return }
        settings.events.swapAt(from, to)
        save()
    }
}

struct EventRow: View {
    let event: ProgressEvent
    let number: Int
    let showsStatus: Bool
    let moveUp: (() -> Void)?
    let moveDown: (() -> Void)?
    let delete: () -> Void

    private var progress: Double { event.progress(at: Date()) }

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.purple)
                .frame(width: 34, height: 34)
                .background(Color.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(event.displayName)
                    .font(.system(size: 14, weight: .semibold))
                Text("\(event.startDate.formatted(date: .numeric, time: .shortened)) ~ \(event.endDate.formatted(date: .numeric, time: .shortened))")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            ProgressView(value: progress)
                .tint(.purple)
                .frame(width: 120)

            if showsStatus {
                VStack(alignment: .leading, spacing: 3) {
                    Text(statusText)
                        .font(.system(size: 12, weight: .semibold))
                    Text(percent(progress))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.purple)
                .frame(width: 58, alignment: .leading)
            } else {
                Text("100%")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.purple)
                    .frame(width: 58, alignment: .leading)
            }

            HStack(spacing: 3) {
                if let moveUp { Button { moveUp() } label: { Image(systemName: "chevron.up") } }
                if let moveDown { Button { moveDown() } label: { Image(systemName: "chevron.down") } }
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.purple)

            Button(role: .destructive, action: delete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(10)
        .background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.07))
        }
    }

    private var status: EventStatus { event.status(at: Date()) }
    private var statusText: String {
        switch status {
        case .future: return "未来"
        case .active: return "进行中"
        case .completed: return "已完成"
        }
    }
}

struct AddEventCard: View {
    @Binding var name: String
    @Binding var startDate: Date
    @Binding var endDate: Date
    let addEvent: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("添加事件")
                .font(.system(size: 16, weight: .semibold))

            VStack(alignment: .leading, spacing: 7) {
                Text("事件名")
                    .font(.system(size: 12, weight: .semibold))
                TextField("例如：创业计划、健身计划、学习目标...", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("开始时间")
                    .font(.system(size: 12, weight: .semibold))
                DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .datePickerStyle(.compact)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("结束时间")
                    .font(.system(size: 12, weight: .semibold))
                DatePicker("", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .datePickerStyle(.compact)
            }

            Spacer(minLength: 12)

            HStack(spacing: 12) {
                Button("清空") {
                    name = ""
                    startDate = Date()
                    endDate = Date().addingTimeInterval(60 * 60 * 24)
                }
                .frame(maxWidth: .infinity)

                Button("保存") {
                    addEvent()
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .frame(maxWidth: .infinity)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 380, alignment: .topLeading)
        .frame(minHeight: 330, alignment: .topLeading)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08))
        }
    }
}

private extension NumberFormatter {
    static let lifeYears: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = 30
        formatter.maximum = 175
        return formatter
    }()
}

private func yearsMonthsDays(fromDays days: Int) -> String {
    let years = days / 365
    let months = (days % 365) / 30
    let rest = (days % 365) % 30
    return "\(years)年\(months)个月\(rest)天"
}
