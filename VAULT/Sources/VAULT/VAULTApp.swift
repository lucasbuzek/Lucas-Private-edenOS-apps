import SwiftUI

@main
struct VAULTApp: App {
    @StateObject private var storage = VaultStore()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            RootView(storage: storage)
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active { storage.lock() }
                }
        }
    }
}

struct RootView: View {
    @ObservedObject var storage: VaultStore
    @State private var primary = ""
    @State private var alternate = ""
    @State private var unlockPIN = ""
    @State private var showEditor = false
    @State private var accountName = ""
    @State private var accountBalance = ""

    var body: some View {
        NavigationStack {
            Group {
                if !storage.configured {
                    Form {
                        Section("Create encrypted local workspace") {
                            SecureField("Primary PIN (8+ characters)", text: $primary)
                            SecureField("Optional alternative PIN", text: $alternate)
                            Button("Create VAULT") {
                                storage.initialize(personalPIN: primary, samplePIN: alternate)
                                primary = ""; alternate = ""
                            }
                        }
                        Section {
                            Text("This is an offline engineering candidate. It is not a bank, does not connect to accounts, and does not yet implement recovery exports or bank emergency contacts.")
                                .font(.footnote)
                        }
                    }
                } else if !storage.unlocked {
                    Form {
                        Section("Unlock") {
                            SecureField("PIN", text: $unlockPIN)
                                .textContentType(.password)
                            Button("Unlock") {
                                storage.unlock(pin: unlockPIN)
                                unlockPIN = ""
                            }
                        }
                    }
                } else {
                    List {
                        Section("Accounts") {
                            if storage.accounts.isEmpty {
                                Text("No accounts. Add a personal record.")
                                    .foregroundStyle(.secondary)
                            }
                            ForEach(storage.accounts) { account in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(account.name).font(.headline)
                                        Text("Personal record · offline").font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("\(account.currency) \(account.balance)")
                                        .monospacedDigit()
                                }
                            }
                        }
                        Section {
                            Button("Add account record") { showEditor = true }
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Lock", systemImage: "lock") { storage.lock() }
                        }
                    }
                    .sheet(isPresented: $showEditor) {
                        NavigationStack {
                            Form {
                                TextField("Account nickname", text: $accountName)
                                TextField("Display balance", text: $accountBalance)
                            }
                            .navigationTitle("Add account")
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Cancel") { showEditor = false }
                                }
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Save") {
                                        storage.addAccount(name: accountName, balance: accountBalance)
                                        accountName = ""; accountBalance = ""
                                        showEditor = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("VAULT")
            .alert("VAULT", isPresented: Binding(
                get: { storage.message != nil },
                set: { if !$0 { storage.message = nil } }
            )) {
                Button("OK") { storage.message = nil }
            } message: {
                Text(storage.message ?? "")
            }
        }
    }
}