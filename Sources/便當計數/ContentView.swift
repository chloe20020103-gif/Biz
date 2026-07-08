import SwiftUI

// 單筆變動紀錄
struct HistoryItem: Identifiable, Codable {
    let id = UUID()
    let oldValue: Int
    let change: Int
    let newValue: Int
    let time: String
    let note: String
}

// 單個統計專案
struct CounterProject: Identifiable, Codable {
    let id = UUID()
    var name: String
    var count: Int
    var history: [HistoryItem]
}

struct ContentView: View {
    @AppStorage("projectData") private var projectData: Data = Data()
    @State private var customProjects: [CounterProject] = [] // 手動新增的專案
    @State private var newProjectName = ""
    @State private var inputValues: [UUID: String] = [:]
    @State private var showHistory = false
    @State private var selectedProject: CounterProject?
    
    // 🔒 固定預設4個專案（順序鎖定）
    private let defaultProjects: [CounterProject] = [
        CounterProject(name: "組數", count: 0, history: []),
        CounterProject(name: "外送", count: 0, history: []),
        CounterProject(name: "現場", count: 0, history: []),
        CounterProject(name: "外賣", count: 0, history: [])
    ]
    
    // 自動計算總數：外送 + 現場 + 外賣
    private var totalSum: Int {
        let delivery = getDefaultCount(name: "外送")
        let onSite = getDefaultCount(name: "現場")
        let takeout = getDefaultCount(name: "外賣")
        return delivery + onSite + takeout
    }
    
    // 讀取預設專案的儲存數值
    @AppStorage("defaultGroup") private var groupCount: Int = 0
    @AppStorage("defaultDelivery") private var deliveryCount: Int = 0
    @AppStorage("defaultOnsite") private var onsiteCount: Int = 0
    @AppStorage("defaultTakeout") private var takeoutCount: Int = 0
    
    // 讀取預設專案的變動紀錄
    @AppStorage("historyGroup") private var groupHistoryData: Data = Data()
    @AppStorage("historyDelivery") private var deliveryHistoryData: Data = Data()
    @AppStorage("historyOnsite") private var onsiteHistoryData: Data = Data()
    @AppStorage("historyTakeout") private var takeoutHistoryData: Data = Data()
    
    init() {
        // 讀取手動新增的專案
        if let decoded = try? JSONDecoder().decode([CounterProject].self, from: projectData) {
            _customProjects = State(initialValue: decoded)
        }
    }
    
    // 取得預設專案目前數值
    private func getDefaultCount(name: String) -> Int {
        switch name {
        case "組數": return groupCount
        case "外送": return deliveryCount
        case "現場": return onsiteCount
        case "外賣": return takeoutCount
        default: return 0
        }
    }
    
    // 取得預設專案的變動紀錄
    private func getDefaultHistory(name: String) -> [HistoryItem] {
        let data: Data
        switch name {
        case "組數": data = groupHistoryData
        case "外送": data = deliveryHistoryData
        case "現場": data = onsiteHistoryData
        case "外賣": data = takeoutHistoryData
        default: return []
        }
        return (try? JSONDecoder().decode([HistoryItem].self, from: data)) ?? []
    }
    
    // 儲存預設專案的變動紀錄
    private func saveHistory(name: String, history: [HistoryItem]) {
        guard let encoded = try? JSONEncoder().encode(history) else { return }
        switch name {
        case "組數": groupHistoryData = encoded
        case "外送": deliveryHistoryData = encoded
        case "現場": onsiteHistoryData = encoded
        case "外賣": takeoutHistoryData = encoded
        default: break
        }
    }
    
    // 儲存手動新增專案
    private func saveCustomProjects() {
        if let encoded = try? JSONEncoder().encode(customProjects) {
            projectData = encoded
        }
    }
    
    // 取得目前時間
    private func getTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 🔢 總數顯示
                Section("統計總數（外送+現場+外賣）") {
                    HStack {
                        Text("合計")
                            .font(.headline)
                        Spacer()
                        Text("\(totalSum)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                }
                
                // 🔒 固定預設專案區
                Section("預設統計") {
                    ForEach(defaultProjects) { project in
                        DefaultProjectRow(
                            projectName: project.name,
                            currentCount: Binding(
                                get: { getDefaultCount(name: project.name) },
                                set: { newValue in
                                    switch project.name {
                                    case "組數": groupCount = newValue
                                    case "外送": deliveryCount = newValue
                                    case "現場": onsiteCount = newValue
                                    case "外賣": takeoutCount = newValue
                                    default: break
                                    }
                                }
                            ),
                            history: Binding(
                                get: { getDefaultHistory(name: project.name) },
                                set: { saveHistory(name: project.name, history: $0) }
                            ),
                            inputValues: $inputValues,
                            onViewHistory: { selectedProject = project; showHistory = true }
                        )
                        .padding(.vertical, 4)
                    }
                }
                
                // ➕ 手動新增專案區
                Section("新增自訂專案") {
                    HStack {
                        TextField("輸入專案名稱", text: $newProjectName)
                        Button("新增") {
                            guard !newProjectName.isEmpty else { return }
                            customProjects.append(CounterProject(name: newProjectName, count: 0, history: []))
                            newProjectName = ""
                            saveCustomProjects()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                // 📋 自訂專案列表
                if !customProjects.isEmpty {
                    Section("自訂專案") {
                        ForEach($customProjects) { $project in
                            CustomProjectRow(
                                project: $project,
                                inputValues: $inputValues,
                                onViewHistory: { selectedProject = project; showHistory = true },
                                onDelete: {
                                    if let idx = customProjects.firstIndex(where: { $0.id == project.id }) {
                                        customProjects.remove(at: idx)
                                        saveCustomProjects()
                                    }
                                }
                            )
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("營業累計統計")
            .sheet(isPresented: $showHistory) {
                HistoryView(project: $selectedProject)
            }
        }
    }
}

// MARK: - 預設專案列元件
struct DefaultProjectRow: View {
    let projectName: String
    @Binding var currentCount: Int
    @Binding var history: [HistoryItem]
    @Binding var inputValues: [UUID: String]
    let onViewHistory: () -> Void
    private let tempId = UUID() // 唯一識別用
    
    private func getTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Text(projectName)
                .font(.headline)
                .frame(width: 50, alignment: .leading)
            
            Text("\(currentCount)")
                .font(.system(size: 22, weight: .semibold))
                .frame(width: 50)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(8)
            
            Button(action: {
                let old = currentCount
                let change = -1
                currentCount = max(0, old + change)
                addHistory(old: old, change: change, note: "點擊減1")
            }) {
                Text("−")
                    .font(.title.bold())
                    .frame(width: 36, height: 36)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                let old = currentCount
                let change = 1
                currentCount += change
                addHistory(old: old, change: change, note: "點擊加1")
            }) {
                Text("+")
                    .font(.title.bold())
                    .frame(width: 36, height: 36)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            TextField("輸入數字", text: Binding(
                get: { inputValues[tempId] ?? "" },
                set: { inputValues[tempId] = $0 }
            ))
            .keyboardType(.numbersAndPunctuation)
            .multilineTextAlignment(.center)
            .frame(width: 80)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .onSubmit {
                applyInputChange()
            }
            
            Button("紀錄", action: onViewHistory)
                .font(.caption)
                .buttonStyle(.bordered)
        }
    }
    
    private func apply
