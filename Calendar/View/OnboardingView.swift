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
    @State private var selectedWeekdays: Set<Int> = []
    @State private var newStartHour: Int = 8
    @State private var newStartMinute: Int = 30
    @State private var newEndHour: Int = 15
    @State private var newEndMinute: Int = 30
    @State private var newCategory: FixedScheduleCategory = .study

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("使うカレンダー")
                            .font(.headline)

                        Text("連携したいカレンダーを選ぶ")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Picker("カレンダー種類", selection: $viewModel.calendarType) {
                            Text("Appleカレンダー").tag(CalendarType.apple)
                            Text("Googleカレンダー").tag(CalendarType.google)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 8)
                }

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

                Section("固定予定を追加") {
                    TextField("予定名（学校、仕事、病院、ジムなど）", text: $newTitle)

                    Picker("カテゴリ", selection: $newCategory) {
                        Text("勉強").tag(FixedScheduleCategory.study)
                        Text("仕事").tag(FixedScheduleCategory.work)
                        Text("用事").tag(FixedScheduleCategory.personal)
                        Text("趣味").tag(FixedScheduleCategory.hobby)
                        Text("家族").tag(FixedScheduleCategory.family)
                        Text("運動").tag(FixedScheduleCategory.exercise)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("曜日を選択（複数可）")
                            .font(.subheadline)

                        weekdaySelectionGrid
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
                        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)

                        guard !trimmedTitle.isEmpty else { return }
                        guard !selectedWeekdays.isEmpty else { return }

                        viewModel.addFixedSchedule(
                            title: trimmedTitle,
                            weekdays: selectedWeekdays.sorted(),
                            startHour: newStartHour,
                            startMinute: newStartMinute,
                            endHour: newEndHour,
                            endMinute: newEndMinute,
                            category: newCategory
                        )

                        newTitle = ""
                        selectedWeekdays = []
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

                                Text("\(weekdayListText(schedule.weekdays))  \(timeText(hour: schedule.startHour, minute: schedule.startMinute))〜\(timeText(hour: schedule.endHour, minute: schedule.endMinute))")
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
                        Text("保存する")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("初期設定")
        }
    }

    private var weekdaySelectionGrid: some View {
        HStack(spacing: 8) {
            ForEach(weekdayItems, id: \.value) { item in
                Button {
                    toggleWeekday(item.value)
                } label: {
                    Text(item.label)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedWeekdays.contains(item.value) ? Color.blue : Color.gray.opacity(0.15))
                        .foregroundStyle(selectedWeekdays.contains(item.value) ? Color.white : Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var weekdayItems: [(label: String, value: Int)] {
        [
            ("日", 1),
            ("月", 2),
            ("火", 3),
            ("水", 4),
            ("木", 5),
            ("金", 6),
            ("土", 7)
        ]
    }

    private func toggleWeekday(_ weekday: Int) {
        if selectedWeekdays.contains(weekday) {
            selectedWeekdays.remove(weekday)
        } else {
            selectedWeekdays.insert(weekday)
        }
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
}
