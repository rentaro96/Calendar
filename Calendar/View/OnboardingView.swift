//
//  OnboardingView.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//

internal import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()

    @State private var newTitle: String = ""
    @State private var newWeekday: Int = 2
    @State private var newStartHour: Int = 8
    @State private var newStartMinute: Int = 30
    @State private var newEndHour: Int = 15
    @State private var newEndMinute: Int = 30
    @State private var newCategory: FixedScheduleCategory = .school

    var body: some View {
        NavigationStack {
            Form {
                Section("生活リズム") {
                    HStack {
                        Text("起床時間")
                        Spacer()
                        Picker("起床時間(時)", selection: $viewModel.wakeUpHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text("\(hour)時").tag(hour)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("起床時間(分)", selection: $viewModel.wakeUpMinute) {
                            ForEach([0, 10, 20, 30, 40, 50], id: \.self) { minute in
                                Text(String(format: "%02d分", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    HStack {
                        Text("就寝時間")
                        Spacer()
                        Picker("就寝時間(時)", selection: $viewModel.sleepHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text("\(hour)時").tag(hour)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("就寝時間(分)", selection: $viewModel.sleepMinute) {
                            ForEach([0, 10, 20, 30, 40, 50], id: \.self) { minute in
                                Text(String(format: "%02d分", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section("集中しやすい時間") {
                    HStack {
                        Text("開始")
                        Spacer()
                        Picker("集中開始", selection: $viewModel.focusStartHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text("\(hour)時").tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    HStack {
                        Text("終了")
                        Spacer()
                        Picker("集中終了", selection: $viewModel.focusEndHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text("\(hour)時").tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section("苦手な時間") {
                    HStack {
                        Text("開始")
                        Spacer()
                        Picker("苦手開始", selection: $viewModel.weakStartHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text("\(hour)時").tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    HStack {
                        Text("終了")
                        Spacer()
                        Picker("苦手終了", selection: $viewModel.weakEndHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text("\(hour)時").tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section("勉強設定") {
                    Picker("1回のおすすめ勉強時間", selection: $viewModel.preferredStudyMinutes) {
                        ForEach([15, 20, 30, 45, 60, 90], id: \.self) { minute in
                            Text("\(minute)分").tag(minute)
                        }
                    }

                    Picker("カレンダー種類", selection: $viewModel.calendarType) {
                        Text("Apple").tag(CalendarType.apple)
                        Text("Google").tag(CalendarType.google)
                    }
                }

                Section("固定予定を追加") {
                    TextField("予定名（学校、塾、部活など）", text: $newTitle)

                    Picker("曜日", selection: $newWeekday) {
                        Text("日").tag(1)
                        Text("月").tag(2)
                        Text("火").tag(3)
                        Text("水").tag(4)
                        Text("木").tag(5)
                        Text("金").tag(6)
                        Text("土").tag(7)
                    }

                    Picker("カテゴリ", selection: $newCategory) {
                        Text("学校").tag(FixedScheduleCategory.school)
                        Text("塾").tag(FixedScheduleCategory.cram)
                        Text("部活").tag(FixedScheduleCategory.club)
                        Text("その他").tag(FixedScheduleCategory.other)
                    }

                    HStack {
                        Text("開始")
                        Spacer()
                        Picker("開始時", selection: $newStartHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text("\(hour)時").tag(hour)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("開始分", selection: $newStartMinute) {
                            ForEach([0, 10, 20, 30, 40, 50], id: \.self) { minute in
                                Text(String(format: "%02d分", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    HStack {
                        Text("終了")
                        Spacer()
                        Picker("終了時", selection: $newEndHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text("\(hour)時").tag(hour)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("終了分", selection: $newEndMinute) {
                            ForEach([0, 10, 20, 30, 40, 50], id: \.self) { minute in
                                Text(String(format: "%02d分", minute)).tag(minute)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Button("固定予定を追加") {
                        guard !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            return
                        }

                        viewModel.addFixedSchedule(
                            title: newTitle,
                            weekday: newWeekday,
                            startHour: newStartHour,
                            startMinute: newStartMinute,
                            endHour: newEndHour,
                            endMinute: newEndMinute,
                            category: newCategory
                        )

                        newTitle = ""
                    }
                }

                Section("追加済みの固定予定") {
                    if viewModel.fixedSchedules.isEmpty {
                        Text("まだ固定予定がありません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.fixedSchedules) { schedule in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(schedule.title)
                                    .font(.headline)

                                Text("\(weekdayText(schedule.weekday)) \(timeText(hour: schedule.startHour, minute: schedule.startMinute))〜\(timeText(hour: schedule.endHour, minute: schedule.endMinute))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Text(categoryText(schedule.category))
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                        .onDelete(perform: viewModel.removeFixedSchedule)
                    }
                }

                Section {
                    Button {
                        viewModel.saveAll()
                        appState.completeOnboarding()
                    } label: {
                        Text("保存して始める")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("初期設定")
        }
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
}
