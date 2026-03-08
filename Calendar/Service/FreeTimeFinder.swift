//
//  FreeTimeFinder.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//

import Foundation

final class FreeTimeFinder {
    func findFreeTimeSlots(
        on date: Date,
        profile: UserProfile,
        schedules: [FixedSchedule]
    ) -> [TimeSlot] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let startOfDay = calendar.startOfDay(for: date)

        guard
            let dayStart = calendar.date(
                bySettingHour: profile.wakeUpHour,
                minute: profile.wakeUpMinute,
                second: 0,
                of: startOfDay
            ),
            let dayEnd = calendar.date(
                bySettingHour: profile.sleepHour,
                minute: profile.sleepMinute,
                second: 0,
                of: startOfDay
            )
        else {
            return []
        }

        if dayStart >= dayEnd {
            return []
        }

        let busySlots = schedules
            .filter { $0.weekdays.contains(weekday) }
            .compactMap { schedule in
                makeTimeSlot(from: schedule, on: startOfDay, calendar: calendar)
            }
            .filter { slot in
                slot.end > dayStart && slot.start < dayEnd
            }
            .map { slot in
                TimeSlot(
                    start: maxDate(slot.start, dayStart),
                    end: minDate(slot.end, dayEnd)
                )
            }
            .sorted { $0.start < $1.start }

        let mergedBusySlots = mergeSlots(busySlots)

        var freeSlots: [TimeSlot] = []
        var currentPointer = dayStart

        for busy in mergedBusySlots {
            if currentPointer < busy.start {
                freeSlots.append(TimeSlot(start: currentPointer, end: busy.start))
            }

            if busy.end > currentPointer {
                currentPointer = busy.end
            }
        }

        if currentPointer < dayEnd {
            freeSlots.append(TimeSlot(start: currentPointer, end: dayEnd))
        }

        return freeSlots.filter { $0.durationMinutes > 0 }
    }

    private func makeTimeSlot(
        from schedule: FixedSchedule,
        on startOfDay: Date,
        calendar: Calendar
    ) -> TimeSlot? {
        guard
            let start = calendar.date(
                bySettingHour: schedule.startHour,
                minute: schedule.startMinute,
                second: 0,
                of: startOfDay
            ),
            let end = calendar.date(
                bySettingHour: schedule.endHour,
                minute: schedule.endMinute,
                second: 0,
                of: startOfDay
            )
        else {
            return nil
        }

        guard start < end else {
            return nil
        }

        return TimeSlot(start: start, end: end)
    }

    private func mergeSlots(_ slots: [TimeSlot]) -> [TimeSlot] {
        guard !slots.isEmpty else { return [] }

        var merged: [TimeSlot] = [slots[0]]

        for slot in slots.dropFirst() {
            guard let last = merged.last else { continue }

            if slot.start <= last.end {
                merged[merged.count - 1] = TimeSlot(
                    start: last.start,
                    end: maxDate(last.end, slot.end)
                )
            } else {
                merged.append(slot)
            }
        }

        return merged
    }

    private func maxDate(_ lhs: Date, _ rhs: Date) -> Date {
        lhs > rhs ? lhs : rhs
    }

    private func minDate(_ lhs: Date, _ rhs: Date) -> Date {
        lhs < rhs ? lhs : rhs
    }
}
