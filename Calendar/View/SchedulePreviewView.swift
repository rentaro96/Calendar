//
//  SchedulePreviewView.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//

internal import SwiftUI

struct SchedulePreviewView: View {
    let task: TaskItem
    let scheduledBlocks: [ScheduledBlock]

    @Environment(\.dismiss) private var dismiss

    @State private var isSaving = false
    @State private var showSaveSuccessAlert = false
    @State private var showSaveErrorAlert = false
    @State private var errorMessage = ""

    var onSaved: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection
                        taskSummarySection
                        previewSection
                    }
                    .padding()
                }

                bottomSaveButton
            }
            .navigationTitle("自動配置プレビュー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .alert("保存しました", isPresented: $showSaveSuccessAlert) {
                Button("OK") {
                    onSaved?()
                    dismiss()
                }
            } message: {
                Text("Appleカレンダーに予定を追加しました。")
            }
            .alert("保存できませんでした", isPresented: $showSaveErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("この内容でカレンダーに追加できます")
                .font(.headline)

            Text("配置結果を確認してから保存できます。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var taskSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("やること")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(task.title)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Spacer()

                    Text(categoryText(task.category))
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Capsule())
                }

                Text("完成したい日: \(dateTimeText(task.targetDate))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("必要時間: \(task.requiredMinutes)分")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("優先度: \(starText(task.priority))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if task.canSplit {
                    Text("分割: \(task.splitCount)回で進める")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("分割: しない")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("配置結果")
                .font(.headline)

            if scheduledBlocks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("配置できる時間が見つかりませんでした")
                        .font(.headline)

                    Text("完成したい日までに入る空き時間が足りない可能性があります。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(scheduledBlocks.sorted(by: { $0.startDate < $1.startDate })) { block in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dateOnlyText(block.startDate))
                                    .font(.headline)

                                Text("\(timeOnlyText(block.startDate)) 〜 \(timeOnlyText(block.endDate))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }

                        Text(block.title)
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("理由: \(block.reason)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    private var bottomSaveButton: some View {
        VStack(spacing: 10) {
            Button {
                saveToCalendar()
            } label: {
                if isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                } else {
                    Text("この内容でカレンダーに追加")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaving || scheduledBlocks.isEmpty)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }

    private func saveToCalendar() {
        guard !scheduledBlocks.isEmpty else { return }

        isSaving = true

        Task {
            let granted = await CalendarService.shared.requestCalendarAccess()

            guard granted else {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "カレンダーへのアクセス権限がありません。設定アプリで許可を確認してね。"
                    showSaveErrorAlert = true
                }
                return
            }

            do {
                _ = try await CalendarService.shared.saveScheduledBlocks(scheduledBlocks)

                await MainActor.run {
                    isSaving = false
                    showSaveSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showSaveErrorAlert = true
                }
            }
        }
    }

    private func categoryText(_ category: FixedScheduleCategory) -> String {
        switch category {
        case .study:
            return "勉強"
        case .work:
            return "仕事"
        case .personal:
            return "用事"
        case .hobby:
            return "趣味"
        case .family:
            return "家族"
        case .exercise:
            return "運動"
        }
    }

    private func starText(_ value: Int) -> String {
        String(repeating: "★", count: value) + String(repeating: "☆", count: max(0, 5 - value))
    }

    private func dateOnlyText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(EEE)"
        return formatter.string(from: date)
    }

    private func timeOnlyText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func dateTimeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }
}
