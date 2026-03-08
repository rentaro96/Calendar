//
//  CalendarService.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//

import Foundation
import EventKit

final class CalendarService {
    static let shared = CalendarService()

    private let eventStore = EKEventStore()
    private let appCalendarTitle = "SmartScheduler"

    private init() {}

    // MARK: - Authorization

    func requestCalendarAccess() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .fullAccess:
            return true

        case .writeOnly:
            // このアプリは既存予定を読んで除外したいので、
            // writeOnly だけでは足りない
            return false

        case .notDetermined:
            do {
                return try await eventStore.requestFullAccessToEvents()
            } catch {
                print("カレンダー権限リクエスト失敗: \(error)")
                return false
            }

        case .denied, .restricted:
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Existing Events

    func fetchExistingEvents(from startDate: Date, to endDate: Date) -> [EKEvent] {
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )

        return eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
    }

    func fetchExistingBusyTimeSlots(from startDate: Date, to endDate: Date) -> [TimeSlot] {
        fetchExistingEvents(from: startDate, to: endDate)
            .compactMap { event in
                guard let start = event.startDate, let end = event.endDate, start < end else {
                    return nil
                }
                return TimeSlot(start: start, end: end)
            }
    }

    // MARK: - App Calendar

    func findOrCreateAppCalendar() throws -> EKCalendar {
        if let existing = eventStore.calendars(for: .event).first(where: { $0.title == appCalendarTitle }) {
            return existing
        }

        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = appCalendarTitle

        // iCloud / CalDAV / local の順で使えそうな source を探す
        if let source = preferredSource() {
            newCalendar.source = source
        } else {
            throw CalendarServiceError.calendarSourceNotFound
        }

        try eventStore.saveCalendar(newCalendar, commit: true)
        return newCalendar
    }

    private func preferredSource() -> EKSource? {
        let sources = eventStore.sources

        if let iCloud = sources.first(where: { $0.sourceType == .calDAV }) {
            return iCloud
        }

        if let local = sources.first(where: { $0.sourceType == .local }) {
            return local
        }

        return sources.first
    }

    // MARK: - Save Events

    func saveScheduledBlock(_ block: ScheduledBlock) async throws -> String {
        let calendar = try findOrCreateAppCalendar()

        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = block.title
        event.startDate = block.startDate
        event.endDate = block.endDate
        event.notes = """
        Created by SmartScheduler
        taskID: \(block.taskID.uuidString)
        reason: \(block.reason)
        """

        try eventStore.save(event, span: .thisEvent, commit: true)
        return event.eventIdentifier ?? ""
    }

    func saveScheduledBlocks(_ blocks: [ScheduledBlock]) async throws -> [String] {
        let calendar = try findOrCreateAppCalendar()
        var identifiers: [String] = []

        for block in blocks {
            let event = EKEvent(eventStore: eventStore)
            event.calendar = calendar
            event.title = block.title
            event.startDate = block.startDate
            event.endDate = block.endDate
            event.notes = """
            Created by SmartScheduler
            taskID: \(block.taskID.uuidString)
            reason: \(block.reason)
            """

            try eventStore.save(event, span: .thisEvent, commit: false)
            if let id = event.eventIdentifier {
                identifiers.append(id)
            }
        }

        try eventStore.commit()
        return identifiers
    }
}

// MARK: - Error

enum CalendarServiceError: LocalizedError {
    case calendarSourceNotFound

    var errorDescription: String? {
        switch self {
        case .calendarSourceNotFound:
            return "保存先に使えるカレンダーソースが見つかりませんでした。"
        }
    }
}
