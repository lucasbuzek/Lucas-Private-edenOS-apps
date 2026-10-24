import SwiftUI

/// The other Headless agents remain owned by their original applications.
/// Observation is read-only, control is intentionally unavailable until
/// an independently reviewed and permissioned owner adapter is integrated.
struct BifrostPeerMenu: View {
    @ObservedObject var peers: BifrostObservedPeerRegistry
    let expert: Bool

    var body: some View {
        Menu {
            Text(peers.hasFreshObservation
                 ? "Launchd observed · not service health"
                 : "Observation stale · refresh to inspect")
            Divider()
            ForEach(peers.peers) { peer in
                BifrostPeerMenuItem(peer: peer,
                                    fresh: peers.hasFreshObservation,
                                    expert: expert)
            }
            Divider()
            Button("Refresh peer observations") { peers.refresh() }
            if expert {
                Text(peers.feedback)
            }
        } label: {
            Label("Other Headless Services", systemImage: "square.stack.3d.up")
        }
    }
}

private struct BifrostPeerMenuItem: View {
    let peer: BifrostObservedPeer
    let fresh: Bool
    let expert: Bool

    private var menuTitle: String {
        peer.name + " · " + (fresh ? peer.state.rawValue : "Unknown · stale")
    }

    var body: some View {
        Menu(menuTitle) {
            Text("Owner · " + peer.owner)
            if expert {
                Text("launchd · " + peer.id)
                Text(peer.observedAt?.formatted(date: .omitted, time: .shortened)
                     ?? "Not observed")
                Text("Process state is not service health")
            }
            Divider()
            Text("Start/Stop unavailable · owner approval required")
        }
    }
}

