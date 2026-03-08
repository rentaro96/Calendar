//
//  TaskItem.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//

import Foundation

struct TaskItem: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var category: FixedScheduleCategory
    var targetDate: Date
    var requiredMinutes: Int
    var canSplit: Bool
    var splitCount: Int
    var priority: Int
    var memo: String
    var isCompleted: Bool = false
}
