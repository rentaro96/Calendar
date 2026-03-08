//
//  DateCandidateGenerator.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//

import Foundation

final class DateCandidateGenerator {
    private let freeTimeFinder = FreeTimeFinder()

    func generateCandidates(
        for task: TaskItem,
        profile: UserProfile,
        schedules: [FixedSchedule]
    ) -> [DateCandidate] {
        guard !task.canSplit else {
            return []
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDate = calendar.startOfDay(for: task.targetDate)

        guard today <= endDate else {
            return []
        }

        var validDates: [Date] = []
        var currentDate = today

        while currentDate <= endDate {
            let freeSlots = freeTimeFinder.findFreeTimeSlots(
                on: currentDate,
                profile: profile,
                schedules: schedules
            )

            let hasEnoughSlot = freeSlots.contains { $0.durationMinutes >= task.requiredMinutes }

            if hasEnoughSlot {
                validDates.append(currentDate)
            }

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        guard !validDates.isEmpty else {
            return []
        }

        let pickedDates = pickUpToFourDates(from: validDates)

        return pickedDates.enumerated().map { index, date in
            DateCandidate(
                date: date,
                label: makeLabel(for: index, date: date, comparedTo: today, targetDate: endDate)
            )
        }
    }

    private func pickUpToFourDates(from dates: [Date]) -> [Date] {
        if dates.count <= 4 {
            return dates
        }

        let lastIndex = dates.count - 1

        let indexSet: Set<Int> = [
            0,
            max(0, lastIndex / 3),
            max(0, (lastIndex * 2) / 3),
            lastIndex
        ]

        let sortedIndexes = indexSet.sorted()

        return sortedIndexes.map { dates[$0] }
    }

    private func makeLabel(
        for index: Int,
        date: Date,
        comparedTo today: Date,
        targetDate: Date
    ) -> String {
        let calendar = Calendar.current

        if calendar.isDate(date, inSameDayAs: today) {
            return "今日の候補"
        }

        if calendar.isDate(date, inSameDayAs: targetDate) {
            return "完成希望日に近い候補"
        }

        switch index {
        case 0:
            return "早めに進める候補"
        case 1:
            return "バランスのよい候補"
        case 2:
            return "余裕を持てる候補"
        default:
            return "おすすめ候補"
        }
    }
}
