//
//  SuggestedPlan.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//

import Foundation

struct SuggestedPlan: Codable, Identifiable {
    var id: UUID = UUID()
    var taskID: UUID
    var recommendedMinutesPerSession: Int
    var recommendedTimeType: TimeType
    var recommendedPriorityOrder: Int
    var reason: String
}
