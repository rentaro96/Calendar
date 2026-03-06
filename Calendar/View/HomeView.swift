//
//  HomeView.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//

internal import SwiftUI

struct HomeView: View {
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
                        Text("集中しやすい時間: \(profile.focusStartHour)時〜\(profile.focusEndHour)時")
                        Text("苦手な時間: \(profile.weakStartHour)時〜\(profile.weakEndHour)時")
                        Text("おすすめ勉強時間: \(profile.preferredStudyMinutes)分")
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

                                Text("\(weekdayText(schedule.weekday)) \(timeText(hour: schedule.startHour, minute: schedule.startMinute))〜\(timeText(hour: schedule.endHour, minute: schedule.endMinute))")
                                    .foregroundStyle(.secondary)

                                Text(categoryText(schedule.category))
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }

                Section("次にやること") {
                    Text("次は TaskInputView を作って課題を追加できるようにする")
                    Text("そのあと FreeTimeFinder と ScheduleEngine を作る")
                }

                Section {
                    Button(role: .destructive) {
                        LocalStorageService.shared.clearAll()
                        appState.resetOnboarding()
                    } label: {
                        Text("初期設定をやり直す")
                    }
                }
            }
            .navigationTitle("ホーム")
            .onAppear {
                loadData()
            }
        }
    }

    private func loadData() {
        profile = LocalStorageService.shared.loadUserProfile()
        schedules = LocalStorageService.shared.loadFixedSchedules()
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
        case .school:
            return "学校"
        case .cram:
            return "塾"
        case .club:
            return "部活"
        case .other:
            return "その他"
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
