//
//  AppEnums.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//

import Foundation

enum CalendarType: String, Codable, CaseIterable {
    case apple
    case google
}

enum FixedScheduleCategory: String, Codable, CaseIterable {
    case study
    case work
    case personal
    case hobby
    case family
    case exercise
}

enum TimeType: String, Codable {
    case morning
    case afternoon
    case evening
    case night
}
