//
//  OnboardingViewModel.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//

import Foundation
internal import Combine
internal import SwiftUI

final class OnboardingViewModel: ObservableObject {
    // MARK: - UserProfile入力用
    @Published var wakeUpHour: Int = 6
    @Published var wakeUpMinute: Int = 30

    @Published var sleepHour: Int = 23
    @Published var sleepMinute: Int = 0

    @Published var focusStartHour: Int = 19
    @Published var focusEndHour: Int = 21

    @Published var weakStartHour: Int = 22
    @Published var weakEndHour: Int = 23

    @Published var preferredStudyMinutes: Int = 30
    @Published var calendarType: CalendarType = .apple

    // MARK: - FixedSchedule入力用
    @Published var fixedSchedules: [FixedSchedule] = []

    func addFixedSchedule(
        title: String,
        weekday: Int,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        category: FixedScheduleCategory
    ) {
        let newSchedule = FixedSchedule(
            title: title,
            weekday: weekday,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            category: category
        )

        fixedSchedules.append(newSchedule)
    }

    func removeFixedSchedule(at offsets: IndexSet) {
        fixedSchedules.remove(atOffsets: offsets)
    }

    func saveAll() {
        let profile = UserProfile(
            wakeUpHour: wakeUpHour,
            wakeUpMinute: wakeUpMinute,
            sleepHour: sleepHour,
            sleepMinute: sleepMinute,
            focusStartHour: focusStartHour,
            focusEndHour: focusEndHour,
            weakStartHour: weakStartHour,
            weakEndHour: weakEndHour,
            preferredStudyMinutes: preferredStudyMinutes,
            calendarType: calendarType
        )

        LocalStorageService.shared.saveUserProfile(profile)
        LocalStorageService.shared.saveFixedSchedules(fixedSchedules)
    }
}
