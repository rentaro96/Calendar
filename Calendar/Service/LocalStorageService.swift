//
//  LocalStorageService.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//

import Foundation

final class LocalStorageService {
    static let shared = LocalStorageService()

    private init() {}

    private let userDefaults = UserDefaults.standard

    private let userProfileKey = "userProfileKey"
    private let fixedSchedulesKey = "fixedSchedulesKey"
    private let taskItemsKey = "taskItemsKey"

    // MARK: - UserProfile

    func saveUserProfile(_ profile: UserProfile) {
        do {
            let data = try JSONEncoder().encode(profile)
            userDefaults.set(data, forKey: userProfileKey)
        } catch {
            print("UserProfileの保存に失敗: \(error)")
        }
    }

    func loadUserProfile() -> UserProfile? {
        guard let data = userDefaults.data(forKey: userProfileKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(UserProfile.self, from: data)
        } catch {
            print("UserProfileの読み込みに失敗: \(error)")
            return nil
        }
    }

    // MARK: - FixedSchedules

    func saveFixedSchedules(_ schedules: [FixedSchedule]) {
        do {
            let data = try JSONEncoder().encode(schedules)
            userDefaults.set(data, forKey: fixedSchedulesKey)
        } catch {
            print("FixedSchedulesの保存に失敗: \(error)")
        }
    }

    func loadFixedSchedules() -> [FixedSchedule] {
        guard let data = userDefaults.data(forKey: fixedSchedulesKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([FixedSchedule].self, from: data)
        } catch {
            print("FixedSchedulesの読み込みに失敗: \(error)")
            return []
        }
    }

    // MARK: - TaskItems

    func saveTaskItems(_ tasks: [TaskItem]) {
        do {
            let data = try JSONEncoder().encode(tasks)
            userDefaults.set(data, forKey: taskItemsKey)
        } catch {
            print("TaskItemsの保存に失敗: \(error)")
        }
    }

    func loadTaskItems() -> [TaskItem] {
        guard let data = userDefaults.data(forKey: taskItemsKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([TaskItem].self, from: data)
        } catch {
            print("TaskItemsの読み込みに失敗: \(error)")
            return []
        }
    }

    // MARK: - Delete All

    func clearAll() {
        userDefaults.removeObject(forKey: userProfileKey)
        userDefaults.removeObject(forKey: fixedSchedulesKey)
        userDefaults.removeObject(forKey: taskItemsKey)
    }
}
