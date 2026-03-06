//
//  AppState.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//

import Foundation
internal import SwiftUI
internal import Combine

final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool = false

    init() {
        loadInitialState()
    }

    func loadInitialState() {
        hasCompletedOnboarding = LocalStorageService.shared.loadUserProfile() != nil
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}
