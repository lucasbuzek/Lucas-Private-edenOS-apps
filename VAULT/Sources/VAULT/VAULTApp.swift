import SwiftUI
import PhotosUI

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
    @State private var pickedReference: PhotosPickerItem?

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
                        Section("Appearance") {
                            PhotosPicker(selection: $pickedReference, matching: .images) {
                                Label("Select layout screenshot", systemImage: "photo.on.rectangle")
                            }
                            if let layout = storage.referenceLayout {
                                Text("Layout reference saved: \(layout.textRegions.count) text regions. Original image and extracted text not retained.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
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
            .onChange(of: pickedReference) { _, selection in
                guard let selection, let session = storage.activeSessionID else { return }
                Task {
                    defer { pickedReference = nil }
                    do {
                        guard let imageData = try await selection.loadTransferable(type: Data.self) else {
                            storage.message = "Could not read the selected image."
                            return
                        }
                        let result = try await Task.detached(priority: .userInitiated) {
                            try ScreenshotLayoutAnalyzer.analyze(imageData)
                        }.value
                        guard storage.activeSessionID == session else { return }
                        storage.updateLayout(result)
                    } catch {
                        guard storage.activeSessionID == session else { return }
                        storage.message = "Could not analyze this image locally."
                    }
                }
            }
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