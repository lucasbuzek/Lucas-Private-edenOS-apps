import SwiftUI

/// Informational roadmap preview. This file does not create service connections,
/// purchases, accounts, session transports or unverified user-facing controls.
private struct SwayFutureFeature: Identifiable {
    let id:String
    let title:String
    let icon:String
    let status:String
    let summary:String
    let detail:String
}

private enum SwayFutureCatalog {
    static let consumer:[SwayFutureFeature] = [
        .init(id:"community", title:"SWAY Community", icon:"person.3.fill",
              status:"Planned · official release",
              summary:"Find dancers, share choreography and follow creators.",
              detail:"Community will have optional pseudonymous profiles, private/public visibility, friends and follows, favorite content and explicit publishing. Accounts and online services are not required for local Moves, Beats, workouts or .swaypack sharing. The official service is not live in this Alpha."),
        .init(id:"catalog", title:"Official Content", icon:"square.stack.3d.up",
              status:"Planned · official release",
              summary:"Browse and download versioned dance content and updates.",
              detail:"The official online catalog will provide discoverable, compatible content packs, validation, updates and offline caching. Native .swaypack import/export is a separate local function, not a promised future account feature."),
        .init(id:"challenges", title:"Community Challenges", icon:"flag.checkered",
              status:"Planned · official release",
              summary:"Join shared challenges and optional community groups.",
              detail:"Community challenges and groups extend individual programs without forcing public competition. Publication, rankings, consent and moderation must be verified before activation."),
        .init(id:"together", title:"Dance Together", icon:"person.2.fill",
              status:"In development · device verification pending",
              summary:"A synchronized consumer dance session for two participants.",
              detail:"Dance Together is the two-participant mode, distinct from Household (up to six family members) and SWAY Master instructor-led classes. Song, beat, counts and choreography share a reference while each participant keeps camera/tracking data private. Real transport and device synchronization are unverified; solo offline dancing remains available."),
        .init(id:"household", title:"Family / Household", icon:"person.3.sequence.fill",
              status:"Entitlement and session verification pending",
              summary:"Up to six eligible family members, each with a private profile.",
              detail:"The established Household tier supports up to six eligible members via Apple Family Sharing of qualifying purchases or subscriptions. Each person maintains separate progress, Health and camera data. Apple Family Sharing does not supply real-time session transport, and neither production entitlement verification nor synchronized household dancing has passed physical testing."),
        .init(id:"instructors", title:"More Instructors", icon:"person.crop.rectangle.stack",
              status:"Planned · after production Lucia",
              summary:"Nandi, Thabo, Zuri and Kyle join Lucia.",
              detail:"Each additional instructor must use the same verified choreography, articulated rig and character quality contract. Unfinished character options are not offered as if they work."),
        .init(id:"watch", title:"Apple Watch", icon:"applewatch",
              status:"Planned · near version 1",
              summary:"Companion workout control and progress.",
              detail:"The Apple Watch companion is a recovered roadmap feature, not a currently verified feature. Core dancing on iPhone or iPad does not depend on a Watch.")
    ]
    static let family:[SwayFutureFeature] = [
        .init(id:"swayz", title:"SWAYZ", icon:"pencil.and.outline",
              status:"Separate professional product · development",
              summary:"Professional choreography creation, rehearsal and instruction.",
              detail:"SWAYZ authors and teaches movement using the SWAYcore choreography engine and .swaypack exchange. It is separate from consumer Dance & Fitness and from studio billing administration."),
        .init(id:"kids", title:"Kid Dancers", icon:"figure.child",
              status:"Separate child-focused product · development",
              summary:"Dance learning designed for children and parents.",
              detail:"Kid Dancers needs its own age-appropriate UI and safeguarding. It does not automatically inherit adult community profiles, follows or public uploads."),
        .init(id:"studio", title:"Studio Management", icon:"calendar.badge.clock",
              status:"Separate professional product · development",
              summary:"Schedule classes, rosters, attendance and memberships.",
              detail:"Studio Management is the separate business operations product. Larger teacher-led classes and professional shared sessions belong to the professional SWAY ecosystem, not the two-person consumer Shared Sessions feature.")
    ]
}

struct SwayComingToSWAYView: View {
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:18) {
                Text("What's coming").font(.largeTitle.bold())
                Text("Explore established future features. These are information previews, not active services.")
                    .font(.subheadline).foregroundStyle(.secondary)
                section("Dance & Fitness",items:SwayFutureCatalog.consumer)
                section("SWAY family",items:SwayFutureCatalog.family)
                Text("Offline dancing, local Beats and .swaypack sharing do not require future community accounts.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding(18).frame(maxWidth:850).frame(maxWidth:.infinity)
        }
        .background(SwayTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .navigationTitle("Coming to SWAY")
        .navigationBarTitleDisplayMode(.inline)
    }
    private func section(_ title:String,items:[SwayFutureFeature])->some View {
        VStack(alignment:.leading,spacing:10) {
            Text(title).font(.title3.bold())
            ForEach(items){ item in
                NavigationLink { SwayFutureDetailView(item:item) } label:{
                    HStack(spacing:12) {
                        Image(systemName:item.icon).font(.title3)
                            .frame(width:36).foregroundStyle(SwayTheme.cyan)
                        VStack(alignment:.leading,spacing:4) {
                            Text(item.title).font(.headline).foregroundStyle(.white)
                            Text(item.summary).font(.caption).foregroundStyle(.secondary)
                            Text(item.status).font(.caption2.bold()).foregroundStyle(SwayTheme.cyan)
                        }
                        Spacer(minLength:4)
                        Image(systemName:"chevron.right").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(14).frame(maxWidth:.infinity,alignment:.leading)
                    .background(SwayTheme.surface,in:RoundedRectangle(cornerRadius:16))
                }.buttonStyle(.plain)
            }
        }
    }
}

private struct SwayFutureDetailView: View {
    let item:SwayFutureFeature
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:17) {
                Image(systemName:item.icon).font(.system(size:38))
                    .foregroundStyle(SwayTheme.cyan)
                Text(item.title).font(.largeTitle.bold())
                Text(item.status).font(.subheadline.bold()).foregroundStyle(SwayTheme.cyan)
                Text(item.summary).font(.headline)
                Text(item.detail).foregroundStyle(.secondary)
                Label("Preview only — not active in this build",systemImage:"info.circle")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding(22).frame(maxWidth:800,alignment:.leading)
        }
        .background(SwayTheme.background.ignoresSafeArea())
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
