internal import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState

    @State private var tasks: [TaskItem] = []

    @State private var showTaskInputView = false
    @State private var showSettingsView = false

    var body: some View {
        NavigationStack {
            List {
                Section("やること一覧") {
                    if tasks.isEmpty {
                        Text("まだやることがありません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(tasks.sorted(by: { $0.targetDate < $1.targetDate })) { task in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(task.title)
                                        .font(.headline)

                                    Spacer()

                                    Text(categoryText(task.category))
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.blue.opacity(0.12))
                                        .clipShape(Capsule())
                                }

                                Text("完成したい日: \(dateTimeText(task.targetDate))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Text("必要時間: \(task.requiredMinutes)分")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                if task.canSplit {
                                    Text("分割: \(task.splitCount)回で進めたい")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("分割: しない")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Text("優先度: \(starText(task.priority))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                if !task.memo.isEmpty {
                                    Text("メモ: \(task.memo)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteTasks)
                    }
                }

                Section("次にやること") {
                    Text("次は空き時間を探す FreeTimeFinder を作る")
                    Text("そのあと ScheduleEngine で自動配置につなげる")
                }
            }
            .navigationTitle("ホーム")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettingsView = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .onAppear {
                loadData()
            }
            .sheet(isPresented: $showTaskInputView) {
                TaskInputView {
                    loadData()
                }
            }
            .sheet(isPresented: $showSettingsView) {
                SettingsView()
                    .environmentObject(appState)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    showTaskInputView = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("やることを追加")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .padding(.top, 8)
                .background(.ultraThinMaterial)
            }
        }
    }

    private func loadData() {
        tasks = LocalStorageService.shared.loadTaskItems()
    }

    private func deleteTasks(at offsets: IndexSet) {
        let sortedTasks = tasks.sorted(by: { $0.targetDate < $1.targetDate })
        var newTasks = sortedTasks
        newTasks.remove(atOffsets: offsets)
        tasks = newTasks
        LocalStorageService.shared.saveTaskItems(newTasks)
    }

    private func dateTimeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }

    private func starText(_ value: Int) -> String {
        String(repeating: "★", count: value) + String(repeating: "☆", count: max(0, 5 - value))
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
}
