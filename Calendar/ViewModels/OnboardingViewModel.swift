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
    @Published var wakeUpHour: Int = 6
    @Published var wakeUpMinute: Int = 30

    @Published var sleepHour: Int = 23
    @Published var sleepMinute: Int = 0

    @Published var calendarType: CalendarType = .apple

    @Published var fixedSchedules: [FixedSchedule] = []

    func addFixedSchedule(
        title: String,
        weekdays: [Int],
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        category: FixedScheduleCategory
    ) {
        let newSchedule = FixedSchedule(
            title: title,
            weekdays: weekdays,
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
            calendarType: calendarType
        )

        LocalStorageService.shared.saveUserProfile(profile)
        LocalStorageService.shared.saveFixedSchedules(fixedSchedules)
    }
}
