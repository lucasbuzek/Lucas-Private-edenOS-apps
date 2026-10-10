import SwiftUI
import Foundation
import UniformTypeIdentifiers

/// Headless-owned setup inventory, shown in the native App.
/// Staging imports files only: it does not execute installers or download tools.
private struct SetupCatalog: Decodable {
    let packages: [SetupPackage]
    let executionsEnabled: Bool
}

private struct SetupPackage: Decodable, Identifiable {
    let id: String
    let name: String
    let kind: String
    let status: String
    let available: Bool
    let staged: Bool
    let archive_name: String?
    let installation: String
}

struct SetupView: View {
    @EnvironmentObject private var headless: HeadlessClient
    @State private var packages: [SetupPackage] = []
    @State private var loading = false
    @State private var status = "Checking setup packages"
    @State private var operationFeedback = ""
    @State private var pendingStage: SetupPackage?
    @State private var importPackageID: String?
    @State private var showArchiveImporter = false

    private let endpoint = URL(string: "http://127.0.0.1:8798")!

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 11) {
                BifrostColorIcon("Install & Setup", symbol: "shippingbox.fill", accent: BifrostUI.apps)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Install & Setup").font(.title2.weight(.bold))
                    Text("Package discovery · safe staging · verification gates")
                        .font(.caption).foregroundStyle(BifrostUI.muted)
                }
                Spacer()
                Button("Refresh") { Task { await refresh() } }
                    .disabled(loading)
                Button("Headless Web") { headless.openWeb() }
                    .disabled(!headless.isRunning)
            }

            HStack(spacing: 9) {
                Button("Import AI Toolkit…") {
                    importPackageID = "ai-toolkit"
                    showArchiveImporter = true
                }
                Button("Import Project Workspace…") {
                    importPackageID = "project-workspace"
                    showArchiveImporter = true
                }
                Text("Choose source ZIPs. Originals are preserved.")
                    .font(.caption2).foregroundStyle(BifrostUI.muted)
            }
            BifrostPanel(title: "Installation sources", symbol: "shippingbox.fill",
                         accent: BifrostUI.apps) {
                Text("Staging unpacks a validated archive into a private review location. It does not install software, execute scripts, log into accounts or download models.")
                    .font(.caption).foregroundStyle(BifrostUI.muted)
                if packages.isEmpty {
                    Text(status).font(.subheadline)
                        .foregroundStyle(BifrostUI.muted).padding(.vertical, 9)
                }
                ForEach(packages) { pkg in
                    Divider().overlay(BifrostUI.line)
                    HStack(spacing: 10) {
                        BifrostColorIcon(pkg.name,
                                         symbol: pkg.kind == "toolkit" ? "brain.head.profile" : "folder.fill",
                                         accent: pkg.kind == "toolkit" ? BifrostUI.ai : BifrostUI.apps)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pkg.name).font(.subheadline.weight(.semibold))
                            Text(pkg.archive_name ?? "Source archive missing")
                                .font(.caption2).foregroundStyle(BifrostUI.muted)
                            Text("Installation: \(pkg.installation)")
                                .font(.caption2).foregroundStyle(BifrostUI.muted)
                        }
                        Spacer()
                        Text(pkg.status.capitalized)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(pkg.status == "available" || pkg.status == "staged" ?
                                             BifrostUI.healthy : BifrostUI.warning)
                        if pkg.status == "available" {
                            Button("Stage for review") { pendingStage = pkg }
                                .buttonStyle(.bordered)
                                .disabled(loading || !headless.isRunning)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }

            BifrostPanel(title: "Next setup gates", symbol: "checklist",
                         accent: BifrostUI.tasks) {
                Text("1 · Review package contents and installation profile")
                Text("2 · Resolve platforms, dependencies, licenses and disk space")
                Text("3 · Authorize specific installation operations")
                Text("4 · Execute through a trusted device adapter")
                Text("5 · Verify installed tools, preserve receipts and rollback")
                Text("6 · Allow mobile control only with device grants and approvals")
                Text("Execution gates 2–6 are not implemented by the current setup importer.")
                    .foregroundStyle(BifrostUI.warning)
            }
            .font(.caption)
            if !operationFeedback.isEmpty {
                Text(operationFeedback).font(.caption).foregroundStyle(BifrostUI.warning)
            }
            if !status.isEmpty {
                Text(status).font(.caption).foregroundStyle(BifrostUI.muted)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: 980, alignment: .leading)
        .onAppear { Task { await refresh() } }
        .confirmationDialog("Stage selected package for local review?",
                            isPresented: Binding(
                                get: { pendingStage != nil },
                                set: { if !$0 { pendingStage = nil } }
                            ),
                            titleVisibility: .visible) {
            Button("Stage files only") {
                guard let pkg = pendingStage else { return }
                Task { await stage(pkg) }
                pendingStage = nil
            }
            Button("Cancel", role: .cancel) { pendingStage = nil }
        } message: {
            Text("The archive is validated and extracted without running any installer or changing provider accounts.")
        }
        .fileImporter(isPresented: $showArchiveImporter,
                      allowedContentTypes: [.zip],
                      allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let source = urls.first, let id = importPackageID {
                    importArchive(source, packageID: id)
                }
            case .failure(let error):
                status = "Import cancelled or failed: \(error.localizedDescription)"
            }
        }
    }

    @MainActor private func importArchive(_ source: URL, packageID: String) {
        let destinationName: String
        switch packageID {
        case "ai-toolkit":
            destinationName = "Universal_AI_Toolkit_Final.zip"
        case "project-workspace":
            destinationName = "Universal_Project_Workspace_v0.2.zip"
        default:
            status = "Unsupported package type"
            return
        }
        let scoped = source.startAccessingSecurityScopedResource()
        defer { if scoped { source.stopAccessingSecurityScopedResource() } }
        do {
            let support = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support/BIFROST", isDirectory: true)
            let inbox = support.appendingPathComponent("Incoming", isDirectory: true)
            try FileManager.default.createDirectory(at: inbox,
                                                    withIntermediateDirectories: true,
                                                    attributes: [.posixPermissions: 0o700])
            try FileManager.default.setAttributes([.posixPermissions: 0o700],
                                                  ofItemAtPath: inbox.path)
            let target = inbox.appendingPathComponent(destinationName)
            guard !FileManager.default.fileExists(atPath: target.path) else {
                status = "An archive of this type is already imported. Inspect it before replacing."
                return
            }
            try FileManager.default.copyItem(at: source, to: target)
            try FileManager.default.setAttributes([.posixPermissions: 0o600],
                                                  ofItemAtPath: target.path)
            status = "Imported \(destinationName) for Headless validation. No installer executed."
            Task { await refresh() }
        } catch {
            status = "Import failed: \(error.localizedDescription)"
        }
    }

    @MainActor private func refresh() async {
        guard !loading else { return }
        loading = true
        defer { loading = false }
        do {
            let (data, response) = try await URLSession.shared.data(
                from: endpoint.appendingPathComponent("api/setup/catalog"))
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            let catalog = try JSONDecoder().decode(SetupCatalog.self, from: data)
            packages = catalog.packages
            status = catalog.executionsEnabled ?
                "Installation executor is available (verification pending)" :
                "Stage and review only · installation execution disabled"
        } catch {
            packages = []
            status = "Setup inventory unavailable: \(error.localizedDescription)"
        }
    }

    @MainActor private func stage(_ pkg: SetupPackage) async {
        loading = true
        defer { loading = false }
        do {
            let (sessionData, _) = try await URLSession.shared.data(
                from: endpoint.appendingPathComponent("api/session"))
            guard let session = try JSONSerialization.jsonObject(with: sessionData)
                as? [String: Any], let token = session["token"] as? String else {
                throw URLError(.userAuthenticationRequired)
            }
            var request = URLRequest(url: endpoint.appendingPathComponent("api/setup/stage"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(token, forHTTPHeaderField: "X-Bifrost-Token")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["id": pkg.id])
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                let body = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                throw NSError(domain: "BIFROST", code: 1,
                              userInfo: [NSLocalizedDescriptionKey:
                                body?["error"] as? String ?? "Staging rejected"])
            }
            operationFeedback = "\(pkg.name) safely staged. Installation NOT performed."
        } catch {
            operationFeedback = "Staging failed: \(error.localizedDescription)"
        }
        loading = false
        await refresh()
    }
}
