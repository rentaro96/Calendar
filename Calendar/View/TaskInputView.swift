internal import SwiftUI

struct TaskInputView: View {
    @Environment(\.dismiss) private var dismiss
        @StateObject private var viewModel = TaskInputViewModel()

        @State private var showValidationAlert = false
        @State private var validationMessage = "入力内容を確認してね。"

        @State private var profile: UserProfile?
        @State private var fixedSchedules: [FixedSchedule] = []

        @State private var draftTask: TaskItem?
        @State private var generatedCandidates: [DateCandidate] = []
        //@State private var generatedBlocks: [ScheduledBlock] = []
    
    @State private var previewPayload: SchedulePreviewPayload?

        @State private var showCandidateSelectionView = false
        //@State private var showSchedulePreviewView = false
        @State private var isPreparingSchedule = false
        @State private var selectedDateForPreview: Date? = nil

        var onSave: (() -> Void)?

        private let candidateGenerator = DateCandidateGenerator()
        private let scheduleEngine = ScheduleEngine()

    var body: some View {
        NavigationStack {
            Form {
                Section("やることの基本情報") {
                    TextField("やること名", text: $viewModel.title)

                    Picker("カテゴリ", selection: $viewModel.category) {
                        Text("勉強").tag(FixedScheduleCategory.study)
                        Text("仕事").tag(FixedScheduleCategory.work)
                        Text("用事").tag(FixedScheduleCategory.personal)
                        Text("趣味").tag(FixedScheduleCategory.hobby)
                        Text("家族").tag(FixedScheduleCategory.family)
                        Text("運動").tag(FixedScheduleCategory.exercise)
                    }
                }

                Section("完成したい時期") {
                    DatePicker(
                        "いつまでに完成させたいか",
                        selection: $viewModel.targetDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    Picker("必要時間", selection: $viewModel.requiredMinutes) {
                        ForEach([15, 30, 45, 60, 90, 120, 180, 240], id: \.self) { minute in
                            Text("\(minute)分").tag(minute)
                        }
                    }
                }

                Section("分割設定") {
                    Toggle("分割して進める", isOn: $viewModel.canSplit)

                    if viewModel.canSplit {
                        Picker("何回に分けたいか", selection: $viewModel.splitCount) {
                            ForEach([2, 3, 4, 5, 6], id: \.self) { count in
                                Text("\(count)回").tag(count)
                            }
                        }

                        Text("分割して進める設定のため、完成希望日までの空き時間に合わせて自動で複数日に配置します。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("優先度") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("自分の中でどれくらい優先したいかを星5で設定")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        PriorityStarPickerView(priority: $viewModel.priority)

                        Text("現在の優先度: \(starText(viewModel.priority))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("メモ") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("このメモ欄は、今後AIによる予定分析やおすすめ提案に活用されます。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("たとえば「集中が必要」「外出前に終わらせたい」「体力を使う」などを書いておくと、あとでAIが予定を分析しやすくなります。")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $viewModel.memo)
                            .frame(minHeight: 120)
                    }
                }

                Section {
                    Button {
                        prepareNextFlow()
                    } label: {
                        if isPreparingSchedule {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("次へ")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isPreparingSchedule)
                }
            }
            .navigationTitle("やること追加")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadSetupData()
            }
            .alert("確認してね", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
            .fullScreenCover(isPresented: $showCandidateSelectionView) {
                if let draftTask {
                    DateCandidateSelectionView(
                        task: draftTask,
                        candidates: generatedCandidates
                    ) { selectedDate in
                        selectedDateForPreview = selectedDate
                        makePreviewSchedule(for: draftTask, selectedDate: selectedDate)
                    }
                }
            }
            .fullScreenCover(item: $previewPayload) { payload in
                SchedulePreviewView(
                    task: payload.task,
                    scheduledBlocks: payload.blocks
                ) {
                    saveDraftTaskToLocal()
                    onSave?()
                    dismiss()
                }
            }
        }
    }

    private func loadSetupData() {
        profile = LocalStorageService.shared.loadUserProfile()
        fixedSchedules = LocalStorageService.shared.loadFixedSchedules()
    }

    private func prepareNextFlow() {
        let trimmedTitle = viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            validationMessage = "やること名を入力してね。"
            showValidationAlert = true
            return
        }

        guard let profile else {
            validationMessage = "先に初期設定を完了してね。"
            showValidationAlert = true
            return
        }

        let task = TaskItem(
            title: trimmedTitle,
            category: viewModel.category,
            targetDate: viewModel.targetDate,
            requiredMinutes: viewModel.requiredMinutes,
            canSplit: viewModel.canSplit,
            splitCount: viewModel.canSplit ? viewModel.splitCount : 1,
            priority: viewModel.priority,
            memo: viewModel.memo.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        draftTask = task
        isPreparingSchedule = true

        if task.canSplit {
            makePreviewSchedule(for: task, selectedDate: nil)
        } else {
            let candidates = candidateGenerator.generateCandidates(
                for: task,
                profile: profile,
                schedules: fixedSchedules
            )

            isPreparingSchedule = false

            if candidates.isEmpty {
                validationMessage = "完成したい日までに入れられそうな候補日が見つかりませんでした。必要時間や日付を見直してみてね。"
                showValidationAlert = true
                return
            }

            generatedCandidates = candidates
            showCandidateSelectionView = true
        }
    }

    private func makePreviewSchedule(for task: TaskItem, selectedDate: Date?) {
        guard let profile else {
            validationMessage = "プロフィールが読み込めませんでした。"
            showValidationAlert = true
            return
        }

        let blocks = scheduleEngine.makeSchedule(
            for: task,
            profile: profile,
            schedules: fixedSchedules,
            selectedDate: selectedDate,
            additionalBusySlots: []
        )

        print("blocks count:", blocks.count)
        for block in blocks {
            print("block:", block.title, block.startDate, block.endDate)
        }

        isPreparingSchedule = false
        previewPayload = SchedulePreviewPayload(task: task, blocks: blocks)
    }

    private func saveDraftTaskToLocal() {
        guard let draftTask else { return }

        var existingTasks = LocalStorageService.shared.loadTaskItems()
        existingTasks.append(draftTask)
        LocalStorageService.shared.saveTaskItems(existingTasks)
    }

    private func starText(_ value: Int) -> String {
        String(repeating: "★", count: value) + String(repeating: "☆", count: max(0, 5 - value))
    }
    
    struct PriorityStarPickerView: View {
        @Binding var priority: Int

        var body: some View {
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { index in
                    Button {
                        priority = index
                    } label: {
                        Image(systemName: index <= priority ? "star.fill" : "star")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

import Foundation

struct SchedulePreviewPayload: Identifiable {
    let id = UUID()
    let task: TaskItem
    let blocks: [ScheduledBlock]
}
