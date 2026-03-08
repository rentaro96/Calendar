internal import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var profile: UserProfile?
    @State private var schedules: [FixedSchedule] = []

    var body: some View {
        NavigationStack {
            List {
                Section("プロフィール") {
                    if let profile {
                        Text("起床時間: \(timeText(hour: profile.wakeUpHour, minute: profile.wakeUpMinute))")
                        Text("就寝時間: \(timeText(hour: profile.sleepHour, minute: profile.sleepMinute))")
                        Text("カレンダー: \(calendarText(profile.calendarType))")
                    } else {
                        Text("プロフィールが保存されていません")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("固定予定") {
                    if schedules.isEmpty {
                        Text("固定予定がありません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(schedules) { schedule in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(schedule.title)
                                    .font(.headline)

                                Text("\(weekdayListText(schedule.weekdays)) \(timeText(hour: schedule.startHour, minute: schedule.startMinute))〜\(timeText(hour: schedule.endHour, minute: schedule.endMinute))")
                                    .foregroundStyle(.secondary)

                                Text(categoryText(schedule.category))
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        LocalStorageService.shared.clearAll()
                        appState.resetOnboarding()
                        dismiss()
                    } label: {
                        Text("初期設定を変更")
                    }
                }
            }
            .navigationTitle("設定")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadData()
            }
        }
    }

    private func loadData() {
        profile = LocalStorageService.shared.loadUserProfile()
        schedules = LocalStorageService.shared.loadFixedSchedules()
    }

    private func weekdayListText(_ weekdays: [Int]) -> String {
        weekdays.map { weekdayText($0) }.joined(separator: "・")
    }

    private func weekdayText(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "日"
        case 2: return "月"
        case 3: return "火"
        case 4: return "水"
        case 5: return "木"
        case 6: return "金"
        case 7: return "土"
        default: return "-"
        }
    }

    private func timeText(hour: Int, minute: Int) -> String {
        String(format: "%02d:%02d", hour, minute)
    }

    private func categoryText(_ category: FixedScheduleCategory) -> String {
        switch category {
        case .study:
            return "勉強"
        case .work:
            return "仕事"
        case .personal:
            return "用事"
        case .hobby:
            return "趣味"
        case .family:
            return "家族"
        case .exercise:
            return "運動"
        }
    }

    private func calendarText(_ type: CalendarType) -> String {
        switch type {
        case .apple:
            return "Apple"
        case .google:
            return "Google"
        }
    }
}
