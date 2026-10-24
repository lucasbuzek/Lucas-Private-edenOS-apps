import SwiftUI
import SWAYStudioKit

struct StudioRoot: View {
    @EnvironmentObject var m: StudioModel
    var body: some View {
        Group {
            if let storageError = m.storageError {
                VStack(spacing: 12) {
                    Image(systemName: "externaldrive.badge.exclamationmark").font(.largeTitle)
                    Text("Studio data unavailable").font(.title2).bold()
                    Text(storageError).multilineTextAlignment(.center).foregroundStyle(.secondary)
                }
                .padding(32).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                NavigationSplitView {
                    List(StudioModel.Nav.allCases, selection: $m.nav) { n in Label(n.rawValue, systemImage: icon(n)).tag(n) }.navigationTitle("Studio")
                } detail: {
                    Group { switch m.nav ?? .today { case .today: TodayView(); case .schedule: ScheduleView(); case .people: PeopleView(); case .memberships: MembershipsView(); case .billing: BillingView(); case .admin: AdminView() } }
                        .id(m.rev)
                        .alert("Couldn't do that", isPresented: Binding(get: { m.error != nil }, set: { _ in m.error = nil })) { Button("OK") {} } message: { Text(m.error ?? "") }
                }
                .safeAreaInset(edge: .top) {
                    if m.store.loadedFromBackup {
                        Label("Recovered from the previous saved copy. Check records before continuing.", systemImage: "exclamationmark.triangle")
                            .font(.caption).foregroundStyle(.orange).frame(maxWidth: .infinity).padding(8)
                    }
                }
            }
        }
    }
    func icon(_ n: StudioModel.Nav) -> String { ["Today": "sun.max", "Schedule": "calendar", "People": "person.2", "Memberships": "creditcard", "Billing": "doc.text", "Admin": "gearshape"][n.rawValue] ?? "circle" }
}

struct TodayView: View {
    @EnvironmentObject var m: StudioModel
    var body: some View {
        let occ = m.store.occurrences(from: m.today, through: m.today)
        List {
            let ex = m.store.exceptions(today: m.today)
            if !ex.isEmpty { Section("Needs attention") { ForEach(ex, id: \.self) { Label($0, systemImage: "exclamationmark.triangle").foregroundStyle(.orange) } } }
            Section("Today's classes") {
                if occ.isEmpty { Text("No classes today").foregroundStyle(.secondary) }
                ForEach(occ, id: \.classID) { o in
                    let c = m.store.data.classes.first { $0.id == o.classID }!
                    NavigationLink { RosterView(classID: c.id, day: o.day) } label: {
                        VStack(alignment: .leading) { Text(c.title).font(.headline)
                            Text("\(hm(o.startMinute))–\(hm(o.endMinute)) · \(m.store.roster(classID: c.id, day: o.day).count)/\(c.capacity) · \(c.instructorID.flatMap { m.store.person($0)?.name } ?? "No instructor")").font(.subheadline).foregroundStyle(.secondary) }
                    }
                }
            }
        }.navigationTitle("Today")
    }
}
func hm(_ minute: Int) -> String { String(format: "%d:%02d", minute / 60, minute % 60) }

struct RosterView: View {
    @EnvironmentObject var m: StudioModel
    let classID: String; let day: String
    @State private var adding = ""
    var body: some View {
        let c = m.store.data.classes.first { $0.id == classID }!
        List {
            Section("Roster (\(m.store.roster(classID: classID, day: day).count)/\(c.capacity))") {
                ForEach(m.store.roster(classID: classID, day: day), id: \.self) { id in
                    let p = m.store.person(id); let rec = m.store.data.attendance.first { $0.classID == classID && $0.day == day && $0.memberID == id }
                    HStack { Text(p?.name ?? id); Spacer()
                        Menu(rec?.status.rawValue.capitalized ?? "Check in") { ForEach([AttendanceRecord.Status.present, .late, .absent, .excused], id: \.self) { s in Button(s.rawValue.capitalized) { m.run { try m.store.record(attendance: s, member: id, classID: classID, day: day) } } } }
                    }.swipeActions { Button("Remove", role: .destructive) { m.run { try m.store.unenroll(member: id, classID: classID, day: nil) } } }
                }
            }
            Section("Enroll member") {
                ForEach(m.store.data.people.filter { $0.role == .member && $0.active && !m.store.roster(classID: classID, day: day).contains($0.id) }) { p in
                    Button(p.name) { m.run { try m.store.enroll(member: p.id, classID: classID, day: nil) } } }
            }
        }.navigationTitle(c.title)
    }
}

struct ScheduleView: View {
    @EnvironmentObject var m: StudioModel
    @State private var title = ""; @State private var capacity = 12; @State private var instructor = ""; @State private var date = Date(); @State private var weekly = true
    var body: some View {
        let from = m.today, to = Day.adding(14, to: from)!
        List {
            Section("Next 14 days") {
                ForEach(Array(m.store.occurrences(from: from, through: to).enumerated()), id: \.offset) { _, o in
                    let c = m.store.data.classes.first { $0.id == o.classID }!
                    HStack { VStack(alignment: .leading) { Text(c.title).font(.headline); Text("\(o.day) · \(hm(o.startMinute))–\(hm(o.endMinute))").font(.subheadline).foregroundStyle(.secondary) }; Spacer()
                        Menu(c.instructorID.flatMap { m.store.person($0)?.name } ?? "Assign instructor") {
                            Button("Unassigned") { m.run { try m.store.assign(instructor: nil, to: c.id) } }
                            ForEach(m.store.data.people.filter { $0.role == .instructor && $0.active }) { person in
                                Button(person.name) { m.run { try m.store.assign(instructor: person.id, to: c.id) } }
                            }
                        }
                    }.swipeActions { Button("Cancel", role: .destructive) { m.run { try m.store.cancel(classID: c.id, day: o.day) } } }
                }
            }
            Section("New class") {
                TextField("Title", text: $title); Stepper("Capacity \(capacity)", value: $capacity, in: 1...200)
                DatePicker("First session", selection: $date); Toggle("Repeats weekly", isOn: $weekly)
                Picker("Instructor", selection: $instructor) { Text("Unassigned").tag(""); ForEach(m.store.data.people.filter { $0.role == .instructor && $0.active }) { Text($0.name).tag($0.id) } }
                Button("Add class") { add() }.disabled(title.isEmpty)
            }
        }.navigationTitle("Schedule")
    }
    func add() {
        let cal = Calendar.current; let comp = cal.dateComponents([.hour, .minute, .weekday], from: date)
        var utc = Calendar(identifier: .gregorian); utc.timeZone = TimeZone(identifier: "UTC")!
        let dayStr = Day.string(date)
        let c = StudioClass(title: title, instructorID: instructor.isEmpty ? nil : instructor, capacity: capacity, startDay: dayStr, startMinute: (comp.hour ?? 0) * 60 + (comp.minute ?? 0),
                            recurrence: weekly ? .weekly(weekdays: [Day.weekday(dayStr) ?? 1], until: nil) : .once)
        m.run { try m.store.add(c); title = "" }
    }
}

struct PeopleView: View {
    @EnvironmentObject var m: StudioModel
    @State private var name = ""; @State private var role = Person.Role.member; @State private var email = ""
    var body: some View {
        List {
            ForEach([Person.Role.instructor, .staff, .member], id: \.self) { r in
                Section(r.rawValue.capitalized + "s") { ForEach(m.store.data.people.filter { $0.role == r }) { p in
                    HStack { VStack(alignment: .leading) { Text(p.name); if let e = p.email { Text(e).font(.caption).foregroundStyle(.secondary) } }; Spacer()
                        Toggle("Active", isOn: Binding(get: { p.active }, set: { v in m.run { try m.store.setActive(p.id, v) } })).labelsHidden() } } }
            }
            Section("Add person") { TextField("Name", text: $name); TextField("Email", text: $email)
                Picker("Role", selection: $role) { Text("Member").tag(Person.Role.member); Text("Instructor").tag(Person.Role.instructor); Text("Staff").tag(Person.Role.staff) }
                Button("Add") { m.run { try m.store.add(Person(name: name, email: email.isEmpty ? nil : email, role: role)); name = ""; email = "" } } }
        }.navigationTitle("People")
    }
}

struct MembershipsView: View {
    @EnvironmentObject var m: StudioModel
    @State private var planName = ""; @State private var price = 9000; @State private var member = ""; @State private var plan = ""
    var body: some View {
        List {
            Section("Plans") { ForEach(m.store.data.plans) { p in HStack { Text(p.name); Spacer(); Text(money(p.priceCents)) } }
                TextField("Plan name", text: $planName); Stepper("Price \(money(price))", value: $price, in: 0...100000, step: 500)
                Button("Add plan") { m.run { try m.store.add(MembershipPlan(name: planName, priceCents: price)); planName = "" } }.disabled(planName.isEmpty) }
            Section("Memberships") { ForEach(m.store.data.memberships) { ms in
                HStack { Text(m.store.person(ms.memberID)?.name ?? "?"); Text(m.store.data.plans.first { $0.id == ms.planID }?.name ?? "").foregroundStyle(.secondary); Spacer()
                    Menu(ms.status.rawValue.capitalized) { ForEach([Membership.Status.active, .paused, .cancelled, .expired], id: \.self) { s in Button(s.rawValue.capitalized) { m.run { try m.store.setMembership(ms.id, status: s, day: m.today) } } } } } } }
            Section("Start membership") {
                Picker("Member", selection: $member) { Text("Choose").tag(""); ForEach(m.store.data.people.filter { $0.role == .member }) { Text($0.name).tag($0.id) } }
                Picker("Plan", selection: $plan) { Text("Choose").tag(""); ForEach(m.store.data.plans) { Text($0.name).tag($0.id) } }
                Button("Start") { m.run { try m.store.start(plan: plan, member: member, day: m.today) } }.disabled(member.isEmpty || plan.isEmpty) }
        }.navigationTitle("Memberships")
    }
}

struct BillingView: View {
    @EnvironmentObject var m: StudioModel
    @State private var member = ""; @State private var desc = ""; @State private var amount = 5000; @State private var due = Date().addingTimeInterval(14 * 86400)
    var body: some View {
        let s = m.store.summary(today: m.today)
        List {
            Section("Summary") { row("Invoiced", s.invoicedCents); row("Collected", s.collectedCents); row("Outstanding", s.outstandingCents); row("Overdue", s.overdueCents) }
            Section("Invoices") { ForEach(m.store.data.invoices) { inv in
                VStack(alignment: .leading) { HStack { Text(m.store.person(inv.memberID)?.name ?? "?"); Spacer(); Text(inv.status.rawValue.capitalized).foregroundStyle(.secondary) }
                    Text("\(inv.description) · \(money(inv.amountCents)) · balance \(money(m.store.balance(invoice: inv.id) ?? 0)) · due \(inv.dueDay)").font(.caption).foregroundStyle(.secondary) }
                .swipeActions { if inv.status != .paid && inv.status != .void { Button("Pay balance") { m.run { try m.store.pay(Payment(invoiceID: inv.id, amountCents: m.store.balance(invoice: inv.id) ?? 0, day: m.today, method: "recorded")) } }.tint(.green) } } } }
            Section("New invoice") { Picker("Member", selection: $member) { Text("Choose").tag(""); ForEach(m.store.data.people.filter { $0.role == .member }) { Text($0.name).tag($0.id) } }
                TextField("Description", text: $desc); Stepper("Amount \(money(amount))", value: $amount, in: 100...1000000, step: 500); DatePicker("Due", selection: $due, displayedComponents: .date)
                Button("Issue") { m.run { try m.store.issue(Invoice(memberID: member, description: desc, amountCents: amount, issuedDay: m.today, dueDay: Day.string(due))); desc = "" } }.disabled(member.isEmpty) }
        }.navigationTitle("Billing")
    }
    func row(_ t: String, _ c: Int) -> some View { HStack { Text(t); Spacer(); Text(money(c)).monospacedDigit() } }
}

struct AdminView: View {
    @EnvironmentObject var m: StudioModel
    @State private var note = ""
    var body: some View {
        List {
            Section("Studio") { TextField("Studio name", text: Binding(get: { m.store.data.studioName }, set: { n in m.run { try m.store.rename(n) } })) }
            Section("Notes") { ForEach(m.store.data.notes) { Text("\($0.day): \($0.text)") }; TextField("Add note", text: $note).onSubmit { m.run { try m.store.add(note: StudioNote(day: m.today, text: note)); note = "" } } }
            Section("Data") { Text("Stored locally on this device with automatic backup. Schema v\(m.store.data.schemaVersion).").font(.footnote) }
        }.navigationTitle("Admin")
    }
}
