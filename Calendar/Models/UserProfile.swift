//
//  UserProfile.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//
import Foundation

struct UserProfile: Codable {
    var wakeUpHour: Int
    var wakeUpMinute: Int
    var sleepHour: Int
    var sleepMinute: Int
    var calendarType: CalendarType
}
