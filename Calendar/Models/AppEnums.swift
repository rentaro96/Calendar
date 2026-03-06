//
//  AppEnums.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//

import Foundation

enum CalendarType: String, Codable {
    case apple
    case google
}

enum FixedScheduleCategory: String, Codable {
    case school
    case cram
    case club
    case other
}

enum TimeType: String, Codable {
    case morning
    case afternoon
    case evening
    case night
}
