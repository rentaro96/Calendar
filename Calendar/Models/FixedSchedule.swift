//
//  FixedSchedule.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//

import Foundation

struct FixedSchedule: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var weekday: Int
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var category: FixedScheduleCategory
}
