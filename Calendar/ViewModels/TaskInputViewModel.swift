//
//  TaskInputViewModel.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//

import Foundation
internal import Combine

final class TaskInputViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var category: FixedScheduleCategory = .study
    @Published var targetDate: Date = Date()
    @Published var requiredMinutes: Int = 60
    @Published var canSplit: Bool = false
    @Published var splitCount: Int = 2
    @Published var priority: Int = 3
    @Published var memo: String = ""

    func saveTask() -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            return false
        }

        let task = TaskItem(
            title: trimmedTitle,
            category: category,
            targetDate: targetDate,
            requiredMinutes: requiredMinutes,
            canSplit: canSplit,
            splitCount: canSplit ? splitCount : 1,
            priority: priority,
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        var existingTasks = LocalStorageService.shared.loadTaskItems()
        existingTasks.append(task)
        LocalStorageService.shared.saveTaskItems(existingTasks)

        return true
    }
}
