//
//  ScheduleEngine.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//

import Foundation

final class ScheduleEngine {
    private let freeTimeFinder = FreeTimeFinder()

    func makeSchedule(
        for task: TaskItem,
        profile: UserProfile,
        schedules: [FixedSchedule],
        selectedDate: Date? = nil,
        additionalBusySlots: [TimeSlot] = []
    ) -> [ScheduledBlock] {
        if task.canSplit {
            return makeSplitSchedule(
                for: task,
                profile: profile,
                schedules: schedules,
                additionalBusySlots: additionalBusySlots
            )
        } else {
            return makeSingleSchedule(
                for: task,
                profile: profile,
                schedules: schedules,
                selectedDate: selectedDate,
                additionalBusySlots: additionalBusySlots
            )
        }
    }

    // MARK: - Single

    private func makeSingleSchedule(
        for task: TaskItem,
        profile: UserProfile,
        schedules: [FixedSchedule],
        selectedDate: Date?,
        additionalBusySlots: [TimeSlot]
    ) -> [ScheduledBlock] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDay = calendar.startOfDay(for: task.targetDate)

        guard today <= targetDay else {
            return []
        }

        let candidateDates: [Date]
        if let selectedDate {
            candidateDates = [calendar.startOfDay(for: selectedDate)]
        } else {
            candidateDates = dates(from: today, to: targetDay)
        }

        for date in candidateDates {
            let rawFreeSlots = freeSlotsForDay(
                date: date,
                profile: profile,
                schedules: schedules,
                additionalBusySlots: additionalBusySlots
            )

            let deadlineClippedSlots = clippedSlotsByDeadline(rawFreeSlots, for: date, task: task)
            let freeSlots = clippedPastSlotsIfNeeded(deadlineClippedSlots, for: date)

            let candidates = freeSlots.filter { $0.durationMinutes >= task.requiredMinutes }
            guard let matchedSlot = candidates.randomElement() else {
                continue
            }

            guard let startDate = randomStartDate(in: matchedSlot, neededMinutes: task.requiredMinutes) else {
                continue
            }

            let endDate = calendar.date(byAdding: .minute, value: task.requiredMinutes, to: startDate) ?? matchedSlot.end

            let block = ScheduledBlock(
                taskID: task.id,
                title: task.title,
                startDate: startDate,
                endDate: endDate,
                reason: singleReason(
                    task: task,
                    scheduledDate: date,
                    selectedDate: selectedDate
                )
            )

            return [block]
        }

        return []
    }

    // MARK: - Split

    private func makeSplitSchedule(
        for task: TaskItem,
        profile: UserProfile,
        schedules: [FixedSchedule],
        additionalBusySlots: [TimeSlot]
    ) -> [ScheduledBlock] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDay = calendar.startOfDay(for: task.targetDate)

        guard today <= targetDay else {
            return []
        }

        guard task.splitCount > 1 else {
            return makeSingleSchedule(
                for: task,
                profile: profile,
                schedules: schedules,
                selectedDate: nil,
                additionalBusySlots: additionalBusySlots
            )
        }

        let sessionMinutesList = splitMinutes(total: task.requiredMinutes, count: task.splitCount)
        let candidateDates = dates(from: today, to: targetDay)

        var result: [ScheduledBlock] = []
        var sessionIndex = 0

        for date in candidateDates {
            guard sessionIndex < sessionMinutesList.count else { break }

            let rawFreeSlots = freeSlotsForDay(
                date: date,
                profile: profile,
                schedules: schedules,
                additionalBusySlots: additionalBusySlots
            )

            let deadlineClippedSlots = clippedSlotsByDeadline(rawFreeSlots, for: date, task: task)
            let freeSlots = clippedPastSlotsIfNeeded(deadlineClippedSlots, for: date)

            let neededMinutes = sessionMinutesList[sessionIndex]

            guard let matchedSlot = freeSlots.first(where: { $0.durationMinutes >= neededMinutes }) else {
                continue
            }

            let startDate = matchedSlot.start
            let endDate = calendar.date(byAdding: .minute, value: neededMinutes, to: startDate) ?? matchedSlot.end

            let block = ScheduledBlock(
                taskID: task.id,
                title: splitTitle(for: task, index: sessionIndex + 1, total: sessionMinutesList.count),
                startDate: startDate,
                endDate: endDate,
                reason: splitReason(
                    task: task,
                    sessionIndex: sessionIndex + 1,
                    totalSessions: sessionMinutesList.count
                )
            )

            result.append(block)
            sessionIndex += 1
        }

        // 必要回数ぶん置けなかったら失敗扱い
        guard result.count == sessionMinutesList.count else {
            return []
        }

        return result
    }

    // MARK: - Free Slots

    private func freeSlotsForDay(
        date: Date,
        profile: UserProfile,
        schedules: [FixedSchedule],
        additionalBusySlots: [TimeSlot]
    ) -> [TimeSlot] {
        let dailyFreeSlots = freeTimeFinder.findFreeTimeSlots(
            on: date,
            profile: profile,
            schedules: schedules
        )

        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return dailyFreeSlots
        }

        let busyOnThatDay = additionalBusySlots
            .filter { $0.end > dayStart && $0.start < dayEnd }
            .map {
                TimeSlot(
                    start: maxDate($0.start, dayStart),
                    end: minDate($0.end, dayEnd)
                )
            }
            .filter { $0.durationMinutes > 0 }

        guard !busyOnThatDay.isEmpty else {
            return dailyFreeSlots
        }

        return subtractBusySlots(from: dailyFreeSlots, busySlots: busyOnThatDay)
    }

    private func subtractBusySlots(from freeSlots: [TimeSlot], busySlots: [TimeSlot]) -> [TimeSlot] {
        let mergedBusySlots = mergeSlots(busySlots)
        var result: [TimeSlot] = freeSlots

        for busy in mergedBusySlots {
            result = result.flatMap { freeSlot in
                subtractOneBusySlot(from: freeSlot, busy: busy)
            }
        }

        return result.filter { $0.durationMinutes > 0 }.sorted { $0.start < $1.start }
    }

    private func subtractOneBusySlot(from freeSlot: TimeSlot, busy: TimeSlot) -> [TimeSlot] {
        if busy.end <= freeSlot.start || busy.start >= freeSlot.end {
            return [freeSlot]
        }

        if busy.start <= freeSlot.start && busy.end >= freeSlot.end {
            return []
        }

        if busy.start <= freeSlot.start {
            return [TimeSlot(start: busy.end, end: freeSlot.end)].filter { $0.durationMinutes > 0 }
        }

        if busy.end >= freeSlot.end {
            return [TimeSlot(start: freeSlot.start, end: busy.start)].filter { $0.durationMinutes > 0 }
        }

        let left = TimeSlot(start: freeSlot.start, end: busy.start)
        let right = TimeSlot(start: busy.end, end: freeSlot.end)

        return [left, right].filter { $0.durationMinutes > 0 }
    }

    private func mergeSlots(_ slots: [TimeSlot]) -> [TimeSlot] {
        let sorted = slots.sorted { $0.start < $1.start }
        guard let first = sorted.first else { return [] }

        var merged: [TimeSlot] = [first]

        for slot in sorted.dropFirst() {
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

    // MARK: - Helpers

    private func dates(from start: Date, to end: Date) -> [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        var current = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)

        while current <= endDay {
            dates.append(current)

            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else {
                break
            }
            current = next
        }

        return dates
    }
    
    private func clippedPastSlotsIfNeeded(
        _ slots: [TimeSlot],
        for date: Date
    ) -> [TimeSlot] {
        let calendar = Calendar.current
        let now = Date()

        guard calendar.isDate(date, inSameDayAs: now) else {
            return slots
        }

        return slots.compactMap { slot in
            let clippedStart = maxDate(slot.start, now)
            guard clippedStart < slot.end else { return nil }
            return TimeSlot(start: clippedStart, end: slot.end)
        }
    }

    private func splitMinutes(total: Int, count: Int) -> [Int] {
        guard count > 0 else { return [] }

        let base = total / count
        let remainder = total % count

        return (0..<count).map { index in
            base + (index < remainder ? 1 : 0)
        }
    }

    private func splitTitle(for task: TaskItem, index: Int, total: Int) -> String {
        "\(task.title) (\(index)/\(total))"
    }

    private func singleReason(
        task: TaskItem,
        scheduledDate: Date,
        selectedDate: Date?
    ) -> String {
        let calendar = Calendar.current

        if let selectedDate, calendar.isDate(selectedDate, inSameDayAs: scheduledDate) {
            return "選択した候補日の空き時間に、必要時間 \(task.requiredMinutes) 分が収まるよう配置しました。"
        } else {
            return "完成希望日までの中で、必要時間 \(task.requiredMinutes) 分が最初に収まる空き時間へ自動配置しました。"
        }
    }

    private func splitReason(
        task: TaskItem,
        sessionIndex: Int,
        totalSessions: Int
    ) -> String {
        return "分割設定があるため、\(totalSessions) 回に分けて完成希望日までの空き時間へ自動配置しました。（\(sessionIndex) 回目）"
    }

    private func maxDate(_ lhs: Date, _ rhs: Date) -> Date {
        lhs > rhs ? lhs : rhs
    }

    private func minDate(_ lhs: Date, _ rhs: Date) -> Date {
        lhs < rhs ? lhs : rhs
    }
    
    private func clippedSlotsByDeadline(
        _ slots: [TimeSlot],
        for date: Date,
        task: TaskItem
    ) -> [TimeSlot] {
        let calendar = Calendar.current

        guard calendar.isDate(date, inSameDayAs: task.targetDate) else {
            return slots
        }

        return slots.compactMap { slot in
            let clippedEnd = minDate(slot.end, task.targetDate)
            guard slot.start < clippedEnd else { return nil }
            return TimeSlot(start: slot.start, end: clippedEnd)
        }
    }
    
    private func randomStartDate(
        in slot: TimeSlot,
        neededMinutes: Int
    ) -> Date? {
        let calendar = Calendar.current
        let latestStart = calendar.date(byAdding: .minute, value: -neededMinutes, to: slot.end)

        guard let latestStart, slot.start <= latestStart else {
            return nil
        }

        let totalMinutes = Int(latestStart.timeIntervalSince(slot.start) / 60)
        guard totalMinutes >= 0 else { return nil }

        // 5分単位でランダム
        let stepCount = totalMinutes / 5
        let randomStep = Int.random(in: 0...max(0, stepCount))
        return calendar.date(byAdding: .minute, value: randomStep * 5, to: slot.start)
    }
}
