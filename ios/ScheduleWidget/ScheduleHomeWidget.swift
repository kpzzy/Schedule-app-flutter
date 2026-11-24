import AppIntents
import SwiftUI
import WidgetKit

enum ScheduleWidgetMode: String, AppEnum {
    case daily, weekly, monthly

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "보기 방식")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .daily: DisplayRepresentation(title: "일간"),
        .weekly: DisplayRepresentation(title: "주간"),
        .monthly: DisplayRepresentation(title: "월간")
    ]
}

struct ChooseScheduleView: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "보기 방식 선택"

    @Parameter(title: "보기 방식", default: .daily)
    var mode: ScheduleWidgetMode
}

struct ScheduleWidgetEntry: TimelineEntry {
    let date: Date
    let mode: ScheduleWidgetMode
    let data: WidgetSnapshot?
}

private var widgetCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.firstWeekday = 2
    calendar.timeZone = .autoupdatingCurrent
    return calendar
}

struct ScheduleWidgetTimeline: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ScheduleWidgetEntry {
        ScheduleWidgetEntry(date: Date(), mode: .daily, data: nil)
    }

    func snapshot(for configuration: ChooseScheduleView, in context: Context) async -> ScheduleWidgetEntry {
        ScheduleWidgetEntry(date: Date(), mode: configuration.mode, data: WidgetSnapshotStore.read())
    }

    func timeline(for configuration: ChooseScheduleView, in context: Context) async -> Timeline<ScheduleWidgetEntry> {
        let now = Date()
        let calendar = widgetCalendar
        let midnight = calendar.startOfDay(for: now)
        let data = WidgetSnapshotStore.read()
        var entries = [ScheduleWidgetEntry(date: now, mode: configuration.mode, data: data)]
        for offset in 1...2 {
            if let day = calendar.date(byAdding: .day, value: offset, to: midnight) {
                entries.append(ScheduleWidgetEntry(date: day, mode: configuration.mode, data: data))
            }
        }
        let refresh = calendar.date(byAdding: .day, value: 3, to: midnight) ?? now.addingTimeInterval(3600)
        return Timeline(entries: entries, policy: .after(refresh))
    }
}

private struct ScheduleWidgetView: View {
    let entry: ScheduleWidgetEntry
    @Environment(\.widgetFamily) private var family

    private let weekdays = ["월", "화", "수", "목", "금", "토", "일"]
    private var calendar: Calendar { widgetCalendar }
    private var today: Date { calendar.startOfDay(for: entry.date) }
    private var monday: Date { offset(today, by: -weekdayIndex(today)) }
    private var month: Date { calendar.dateInterval(of: .month, for: today)?.start ?? today }
    private var limit: Int { family == .systemLarge ? 7 : family == .systemMedium ? 3 : 2 }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(heading)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            if let count {
                Text(count == 0 ? "예정된 일정 없음" : "일정 \(count)개")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .privacySensitive()
                details
                    .privacySensitive()
            } else {
                Text("앱을 열어 일정을 불러오세요")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var heading: String {
        switch entry.mode {
        case .daily: return "일간 · \(shortDate(today))"
        case .weekly:
            return family == .systemSmall ? "주간 · \(shortDate(today))" :
                "주간 · \(shortDate(monday))–\(shortDate(offset(monday, by: 6)))"
        case .monthly: return "월간 · \(calendar.component(.month, from: month))월"
        }
    }

    private var count: Int? {
        switch entry.mode {
        case .daily: return entry.data?.days[key(today)]?.count
        case .weekly: return entry.data?.weeks[key(monday)]
        case .monthly: return entry.data?.months[String(key(month).prefix(7))]
        }
    }

    @ViewBuilder private var details: some View {
        switch entry.mode {
        case .daily:
            let items = Array((entry.data?.days[key(today)]?.items ?? []).prefix(limit))
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                HStack(spacing: 5) {
                    Text(item.lead).foregroundStyle(.secondary)
                    Text(item.title).strikethrough(item.done)
                }
                .font(.caption2)
                .lineLimit(1)
            }
        case .weekly:
            if family == .systemSmall {
                let first = min(weekdayIndex(today), 7 - limit)
                dateList((first..<(first + limit)).map { offset(monday, by: $0) })
            } else {
                gridRow(start: monday, showWeekday: true)
                if family == .systemLarge {
                    dateList((0..<7).map { offset(monday, by: $0) }.filter { dayCount($0) > 0 })
                }
            }
        case .monthly:
            if family == .systemLarge {
                let first = offset(month, by: -weekdayIndex(month))
                HStack(spacing: 2) {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day).frame(maxWidth: .infinity)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                ForEach(0..<6, id: \.self) { row in
                    gridRow(start: offset(first, by: row * 7), monthOnly: true)
                }
            } else {
                let end = calendar.range(of: .day, in: .month, for: today)?.count ?? 0
                let remaining = max(0, end - calendar.component(.day, from: today) + 1)
                dateList(Array((0..<remaining).map { offset(today, by: $0) }.filter { dayCount($0) > 0 }.prefix(limit)))
            }
        }
    }

    private func dateList(_ dates: [Date]) -> some View {
        ForEach(dates, id: \.self) { date in
            HStack {
                Text("\(shortDate(date)) (\(weekdays[weekdayIndex(date)]))")
                Spacer(minLength: 2)
                Text("\(dayCount(date))개").foregroundStyle(.secondary)
            }
            .font(.caption2)
            .lineLimit(1)
        }
    }

    private func gridRow(start: Date, showWeekday: Bool = false, monthOnly: Bool = false) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<7, id: \.self) { index in
                let date = offset(start, by: index)
                let inMonth = calendar.isDate(date, equalTo: month, toGranularity: .month)
                VStack(spacing: 1) {
                    if !monthOnly || inMonth {
                        Text(showWeekday ? weekdays[index] : "\(calendar.component(.day, from: date))")
                        Text(dayCount(date) > 0 || showWeekday ? "\(dayCount(date))" : " ")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption2)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 31)
                .background {
                    if calendar.isDate(date, inSameDayAs: today) {
                        RoundedRectangle(cornerRadius: 7).fill(.green.opacity(0.2))
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(shortDate(date)), 일정 \(dayCount(date))개")
                .accessibilityHidden(monthOnly && !inMonth)
            }
        }
    }

    private func dayCount(_ date: Date) -> Int { entry.data?.days[key(date)]?.count ?? 0 }

    private func key(_ date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    private func shortDate(_ date: Date) -> String {
        "\(calendar.component(.month, from: date))/\(calendar.component(.day, from: date))"
    }

    private func weekdayIndex(_ date: Date) -> Int { (calendar.component(.weekday, from: date) + 5) % 7 }

    private func offset(_ date: Date, by days: Int) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }
}

@main
struct ScheduleHomeWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: WidgetSnapshotStore.kind, intent: ChooseScheduleView.self, provider: ScheduleWidgetTimeline()) { entry in
            ScheduleWidgetView(entry: entry)
        }
        .configurationDisplayName("하루 계획")
        .description("일간·주간·월간 일정을 홈 화면에서 확인하세요.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
