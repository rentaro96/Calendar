//
//  DateCandidate.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//

import Foundation

struct DateCandidate: Identifiable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var label: String
}
