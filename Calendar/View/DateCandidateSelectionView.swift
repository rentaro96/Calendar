//
//  DateCandidateSelectionView.swift
//  SmartSchedulerApp
//
//  Created by 鈴木廉太郎 on 2026/03/06.
//

internal import SwiftUI

struct DateCandidateSelectionView: View {
    let task: TaskItem
    let candidates: [DateCandidate]
    var onDecide: (Date?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedCandidateID: UUID? = nil
    @State private var useAutomaticSelection: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection
                        taskSummarySection
                        candidateSection
                        automaticSection
                    }
                    .padding()
                }

                bottomActionButton
            }
            .navigationTitle("候補日を選ぶ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("このやることを入れやすい候補日です")
                .font(.headline)

            Text("1つ選ぶか、おまかせで自動配置できます。")
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
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var candidateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("候補日")
                .font(.headline)

            if candidates.isEmpty {
                Text("候補日が見つかりませんでした")
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(candidates) { candidate in
                    Button {
                        selectedCandidateID = candidate.id
                        useAutomaticSelection = false
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(dateOnlyText(candidate.date))
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text(candidate.label)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: selectedCandidateID == candidate.id ? "largecircle.fill.circle" : "circle")
                                .font(.title3)
                                .foregroundStyle(selectedCandidateID == candidate.id ? Color.blue : Color.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedCandidateID == candidate.id
                            ? Color.blue.opacity(0.10)
                            : Color(.secondarySystemBackground)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var automaticSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("おまかせ")
                .font(.headline)

            Button {
                useAutomaticSelection.toggle()
                if useAutomaticSelection {
                    selectedCandidateID = nil
                }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("候補からおまかせで選ぶ")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("アプリが候補日の中から自動で選びます")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: useAutomaticSelection ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(useAutomaticSelection ? Color.blue : Color.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    useAutomaticSelection
                    ? Color.blue.opacity(0.10)
                    : Color(.secondarySystemBackground)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }

    private var bottomActionButton: some View {
        VStack {
            Button {
                if useAutomaticSelection {
                    onDecide(nil)
                    dismiss()
                    return
                }

                guard let selectedCandidate = candidates.first(where: { $0.id == selectedCandidateID }) else {
                    return
                }

                onDecide(selectedCandidate.date)
                dismiss()
            } label: {
                Text("自動配置する")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!useAutomaticSelection && selectedCandidateID == nil)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
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

    private func dateTimeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }
}
