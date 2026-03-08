//
//  TimeSlot.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//

import Foundation

struct TimeSlot: Identifiable, Codable {
    var id: UUID = UUID()
    var start: Date
    var end: Date

    var durationMinutes: Int {
        max(0, Int(end.timeIntervalSince(start) / 60))
    }
}
