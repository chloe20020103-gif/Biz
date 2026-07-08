import SwiftUI

struct ContentView: View {
    @AppStorage("groupCount") private var group = 0
    @AppStorage("deliveryCount") private var delivery = 0
    @AppStorage("onsiteCount") private var onsite = 0
    @AppStorage("takeoutCount") private var takeout = 0
    
    private var totalSum: Int { delivery + onsite + takeout }
    
    var body: some View {
        NavigationStack {
            List {
                Section("統計總數（外送+現場+外賣）") {
                    HStack {
                        Text("合計")
                        Spacer()
                        Text("\(totalSum)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
                
                Section("預設統計") {
                    CounterRow(name: "組數", count: $group)
                    CounterRow(name: "外送", count: $delivery)
                    CounterRow(name: "現場", count: $onsite)
                    CounterRow(name: "外賣", count: $takeout)
                }
            }
            .navigationTitle("便當計數")
        }
    }
}

struct CounterRow: View {
    let name: String
    @Binding var count: Int
    @State private var inputText = ""
    
    var body: some View {
        HStack(spacing: 12) {
            Text(name)
                .font(.headline)
                .frame(width: 50, alignment: .leading)
            
            Text("\(count)")
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 50)
            
            Button {
                count = max(0, count - 1)
            } label: {
                Text("−")
                    .font(.title.bold())
                    .frame(width: 36, height: 36)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Button {
                count += 1
            } label: {
                Text("+")
                    .font(.title.bold())
                    .frame(width: 36, height: 36)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
            }
            
            TextField("輸入數字", text: $inputText)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.center)
                .frame(width: 90)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(8)
                .onSubmit {
                    applyInput()
                }
        }
    }
    
    private func applyInput() {
        guard let num = Int(inputText), num != 0 else {
            inputText = ""
            return
        }
        count = max(0, count + num)
        inputText = ""
    }
}

#Preview {
    ContentView()
}
