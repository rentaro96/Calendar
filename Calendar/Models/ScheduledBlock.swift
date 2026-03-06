//
//  ScheduledBlock.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//

import Foundation

struct ScheduledBlock: Codable, Identifiable {
    var id: UUID = UUID()
    var taskID: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var reason: String
}
