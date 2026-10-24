import Foundation

public enum StudioError: Error, Equatable {
    case notFound(String), classFull, alreadyEnrolled, notEnrolled, overpayment, invalid(String), instructorConflict, inactiveInstructor, noActiveMembership
}

public enum Day {
    static var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }
    static var fmt: DateFormatter { let f = DateFormatter(); f.calendar = cal; f.timeZone = cal.timeZone; f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"; return f }
    public static func date(_ s: String) -> Date? { fmt.date(from: s) }
    public static func string(_ d: Date) -> String { fmt.string(from: d) }
    public static func weekday(_ s: String) -> Int? { date(s).map { cal.component(.weekday, from: $0) } }   // 1=Sun
    public static func adding(_ days: Int, to s: String) -> String? { date(s).flatMap { cal.date(byAdding: .day, value: days, to: $0) }.map(string) }
}

public struct Occurrence: Equatable, Sendable { public var classID: String, day: String, startMinute: Int, endMinute: Int }

public struct FinanceSummary: Equatable, Sendable {
    public var invoicedCents: Int, collectedCents: Int, outstandingCents: Int, overdueCents: Int
}

/// Operational store: validated mutations + durable JSON persistence with migration and backup.
public final class StudioStore {
    public private(set) var data: StudioData
    public private(set) var loadedFromBackup = false
    private let url: URL?
    private var protectRecoveredBackup = false

    public init(url: URL? = nil) throws {
        self.url = url
        if let url, FileManager.default.fileExists(atPath: url.path) {
            do {
                data = try Self.decode(Data(contentsOf: url))
            } catch {
                data = try Self.load(url)
                loadedFromBackup = true
                protectRecoveredBackup = true
            }
        } else {
            data = StudioData()
        }
    }

    // MARK: persistence + migration
    public static func load(_ url: URL) throws -> StudioData {
        let raw = try Data(contentsOf: url)
        do { return try decode(raw) }
        catch {
            if let b = try? Data(contentsOf: url.appendingPathExtension("bak")), let d = try? decode(b) { return d }
            throw error
        }
    }

    public static func decode(_ raw: Data) throws -> StudioData {
        guard var o = (try? JSONSerialization.jsonObject(with: raw)) as? [String: Any] else { throw StudioError.invalid("not JSON") }
        let v = (o["schemaVersion"] as? Int) ?? 1
        guard v >= 1, v <= StudioData.currentSchema else { throw StudioError.invalid("unsupported schema \(v)") }
        if v == 1 {
            // v1 -> v2: `members` array became `people` with role=member; invoices gained dueDay; payments keyed by invoiceID.
            var people = (o["people"] as? [[String: Any]]) ?? []
            for var m in (o["members"] as? [[String: Any]]) ?? [] { m["role"] = "member"; if m["active"] == nil { m["active"] = true }; if m["notes"] == nil { m["notes"] = "" }; people.append(m) }
            o["members"] = nil; o["people"] = people
            if var inv = o["invoices"] as? [[String: Any]] {
                for i in inv.indices where inv[i]["dueDay"] == nil { inv[i]["dueDay"] = inv[i]["issuedDay"] ?? "1970-01-01" }
                o["invoices"] = inv
            }
            for k in ["plans", "memberships", "classes", "enrollments", "attendance", "invoices", "payments", "notes"] where o[k] == nil { o[k] = [Any]() }
            if o["studioName"] == nil { o["studioName"] = "My Studio" }
            o["schemaVersion"] = 2
        }
        let d = try JSONSerialization.data(withJSONObject: o)
        do { return try JSONDecoder().decode(StudioData.self, from: d) } catch { throw StudioError.invalid("decode: \(error)") }
    }

    public func save() throws {
        guard let url else { return }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let enc = JSONEncoder(); enc.outputFormatting = [.sortedKeys, .prettyPrinted]
        let out = try enc.encode(data)
        if FileManager.default.fileExists(atPath: url.path) && !protectRecoveredBackup {
            let bak = url.appendingPathExtension("bak"); try? FileManager.default.removeItem(at: bak); try? FileManager.default.copyItem(at: url, to: bak)
        }
        try out.write(to: url, options: .atomic)
        protectRecoveredBackup = false
    }

    private func commit(_ change: () throws -> Void) throws {
        let snapshot = data
        do { try change(); try save() } catch { data = snapshot; throw error }
    }

    // MARK: people / plans
    public func add(_ p: Person) throws { try commit {
        guard !p.name.trimmingCharacters(in: .whitespaces).isEmpty else { throw StudioError.invalid("name") }
        data.people.append(p) } }
    public func setActive(_ id: String, _ active: Bool) throws { try commit {
        guard let i = data.people.firstIndex(where: { $0.id == id }) else { throw StudioError.notFound(id) }
        data.people[i].active = active } }
    public func add(_ plan: MembershipPlan) throws { try commit { guard plan.priceCents >= 0, plan.periodDays > 0 else { throw StudioError.invalid("plan") }; data.plans.append(plan) } }
    public func person(_ id: String) -> Person? { data.people.first { $0.id == id } }

    // MARK: classes & schedule
    public func add(_ c: StudioClass) throws { try commit {
        guard c.capacity > 0, (0..<1440).contains(c.startMinute), c.durationMinutes > 0, Day.date(c.startDay) != nil else { throw StudioError.invalid("class") }
        if let iid = c.instructorID {
            guard let p = person(iid), p.role == .instructor else { throw StudioError.notFound(iid) }
            guard p.active else { throw StudioError.inactiveInstructor }
        }
        data.classes.append(c)
        if let iid = c.instructorID, hasInstructorConflict(iid, excluding: c.id) { throw StudioError.instructorConflict }
    } }

    public func assign(instructor: String?, to classID: String) throws { try commit {
        guard let i = data.classes.firstIndex(where: { $0.id == classID }) else { throw StudioError.notFound(classID) }
        if let instructor { guard let p = person(instructor), p.role == .instructor else { throw StudioError.notFound(instructor) }; guard p.active else { throw StudioError.inactiveInstructor } }
        data.classes[i].instructorID = instructor
        if let instructor, hasInstructorConflict(instructor, excluding: nil) { throw StudioError.instructorConflict }
    } }

    public func cancel(classID: String, day: String) throws { try commit {
        guard let i = data.classes.firstIndex(where: { $0.id == classID }) else { throw StudioError.notFound(classID) }
        if !data.classes[i].cancelledDays.contains(day) { data.classes[i].cancelledDays.append(day) } } }

    public func occurrences(from: String, through: String) -> [Occurrence] {
        guard let start = Day.date(from), let end = Day.date(through), start <= end else { return [] }
        var out: [Occurrence] = []
        var d = start
        while d <= end {
            let ds = Day.string(d), wd = Day.cal.component(.weekday, from: d)
            for c in data.classes where !c.cancelledDays.contains(ds) && ds >= c.startDay {
                let hit: Bool
                switch c.recurrence {
                case .once: hit = ds == c.startDay
                case .weekly(let wds, let until): hit = wds.contains(wd) && (until == nil || ds <= until!)
                }
                if hit { out.append(Occurrence(classID: c.id, day: ds, startMinute: c.startMinute, endMinute: c.startMinute + c.durationMinutes)) }
            }
            d = Day.cal.date(byAdding: .day, value: 1, to: d)!
        }
        return out.sorted { ($0.day, $0.startMinute, $0.classID) < ($1.day, $1.startMinute, $1.classID) }
    }

    func hasInstructorConflict(_ iid: String, excluding: String?) -> Bool {
        guard let first = data.classes.compactMap({ $0.startDay }).min() else { return false }
        let end = Day.adding(56, to: first)!
        let occ = occurrences(from: first, through: end).filter { o in data.classes.first { $0.id == o.classID }?.instructorID == iid }
        for (i, a) in occ.enumerated() { for b in occ[(i + 1)...] where a.day == b.day && a.classID != b.classID && a.startMinute < b.endMinute && b.startMinute < a.endMinute { return true } }
        return false
    }

    // MARK: roster
    public func roster(classID: String, day: String) -> [String] {
        data.enrollments.filter { $0.classID == classID && ($0.day == nil || $0.day == day) }.map(\.memberID)
    }
    public func enroll(member: String, classID: String, day: String? = nil) throws { try commit {
        guard let c = data.classes.first(where: { $0.id == classID }) else { throw StudioError.notFound(classID) }
        guard let m = person(member), m.role == .member, m.active else { throw StudioError.notFound(member) }
        guard hasActiveMembership(member, on: day ?? c.startDay) else { throw StudioError.noActiveMembership }
        let checkDay = day ?? c.startDay
        guard !roster(classID: classID, day: checkDay).contains(member) else { throw StudioError.alreadyEnrolled }
        guard roster(classID: classID, day: checkDay).count < c.capacity else { throw StudioError.classFull }
        data.enrollments.append(Enrollment(classID: classID, memberID: member, day: day)) } }
    public func unenroll(member: String, classID: String, day: String? = nil) throws { try commit {
        guard let i = data.enrollments.firstIndex(where: { $0.classID == classID && $0.memberID == member && $0.day == day }) else { throw StudioError.notEnrolled }
        data.enrollments.remove(at: i) } }

    // MARK: attendance
    public func record(attendance status: AttendanceRecord.Status, member: String, classID: String, day: String) throws { try commit {
        guard roster(classID: classID, day: day).contains(member) else { throw StudioError.notEnrolled }
        data.attendance.removeAll { $0.classID == classID && $0.day == day && $0.memberID == member }
        data.attendance.append(AttendanceRecord(classID: classID, day: day, memberID: member, status: status)) } }
    public func attendanceHistory(member: String) -> [AttendanceRecord] { data.attendance.filter { $0.memberID == member }.sorted { $0.day < $1.day } }

    // MARK: memberships
    public func start(plan: String, member: String, day: String) throws { try commit {
        guard data.plans.contains(where: { $0.id == plan }) else { throw StudioError.notFound(plan) }
        guard person(member)?.role == .member else { throw StudioError.notFound(member) }
        for i in data.memberships.indices where data.memberships[i].memberID == member && data.memberships[i].status == .active { data.memberships[i].status = .cancelled; data.memberships[i].endDay = day }
        data.memberships.append(Membership(memberID: member, planID: plan, startDay: day)) } }
    public func setMembership(_ id: String, status: Membership.Status, day: String) throws { try commit {
        guard let i = data.memberships.firstIndex(where: { $0.id == id }) else { throw StudioError.notFound(id) }
        guard Day.date(day) != nil, day >= data.memberships[i].startDay else { throw StudioError.invalid("membership status date") }
        data.memberships[i].status = status
        if status == .cancelled || status == .expired { data.memberships[i].endDay = day }
        else if status == .active { data.memberships[i].endDay = nil }
        // Do not invent historical events for schema-v2 records; their earlier timeline is unknown.
        if data.memberships[i].statusEvents != nil {
            data.memberships[i].statusEvents!.append(MembershipStatusEvent(status: status, day: day))
        }
    } }
    public func hasActiveMembership(_ member: String, on day: String) -> Bool {
        data.memberships.contains { membership in
            guard membership.memberID == member, membership.startDay <= day else { return false }
            guard let events = membership.statusEvents else {
                // Legacy snapshot: only current status is evidenced.
                return membership.status == .active && (membership.endDay == nil || day <= membership.endDay!)
            }
            var current = Membership.Status.expired
            // Each recorded event changes the effective status; cancellation/expiry
            // ends access after the recorded final day.
            for event in events.sorted(by: { $0.day < $1.day }) {
                let effective = (event.status == .cancelled || event.status == .expired)
                    ? (Day.adding(1, to: event.day) ?? event.day) : event.day
                if effective <= day { current = event.status }
            }
            return current == .active
        }
    }

    // MARK: billing
    public func issue(_ inv: Invoice) throws { try commit { guard inv.amountCents > 0, person(inv.memberID) != nil else { throw StudioError.invalid("invoice") }; data.invoices.append(inv) } }
    public func paidCents(invoice id: String) -> Int { data.payments.filter { $0.invoiceID == id }.reduce(0) { $0 + $1.amountCents } }
    public func balance(invoice id: String) -> Int? { data.invoices.first { $0.id == id }.map { $0.amountCents - paidCents(invoice: id) } }
    public func pay(_ p: Payment) throws { try commit {
        guard let i = data.invoices.firstIndex(where: { $0.id == p.invoiceID }) else { throw StudioError.notFound(p.invoiceID) }
        guard p.amountCents > 0, data.invoices[i].status != .void else { throw StudioError.invalid("payment") }
        guard p.amountCents <= data.invoices[i].amountCents - paidCents(invoice: p.invoiceID) else { throw StudioError.overpayment }
        data.payments.append(p)
        data.invoices[i].status = paidCents(invoice: p.invoiceID) == data.invoices[i].amountCents ? .paid : .partiallyPaid } }
    public func void(invoice id: String) throws { try commit {
        guard let i = data.invoices.firstIndex(where: { $0.id == id }) else { throw StudioError.notFound(id) }
        guard paidCents(invoice: id) == 0 else { throw StudioError.invalid("paid invoice cannot be voided") }
        data.invoices[i].status = .void } }
    public func outstanding(member: String) -> Int {
        data.invoices.filter { $0.memberID == member && $0.status != .void }.reduce(0) { $0 + $1.amountCents - paidCents(invoice: $1.id) }
    }
    public func summary(today: String) -> FinanceSummary {
        let live = data.invoices.filter { $0.status != .void }
        let invoiced = live.reduce(0) { $0 + $1.amountCents }
        let collected = live.reduce(0) { $0 + paidCents(invoice: $1.id) }
        let overdue = live.filter { $0.dueDay < today }.reduce(0) { $0 + $1.amountCents - paidCents(invoice: $1.id) }
        return FinanceSummary(invoicedCents: invoiced, collectedCents: collected, outstandingCents: invoiced - collected, overdueCents: overdue)
    }
    public func rename(_ name: String) throws { try commit { guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { throw StudioError.invalid("name") }; data.studioName = name } }
    public func add(note: StudioNote) throws { try commit { data.notes.append(note) } }

    /// "Actionable exceptions" for today: full/over-capacity classes, unassigned instructors, missing attendance, overdue invoices.
    public func exceptions(today: String) -> [String] {
        var out: [String] = []
        for o in occurrences(from: today, through: today) {
            guard let c = data.classes.first(where: { $0.id == o.classID }) else { continue }
            if c.instructorID == nil { out.append("\(c.title): no instructor assigned") }
            if roster(classID: c.id, day: today).count >= c.capacity { out.append("\(c.title): class full") }
        }
        let overdue = data.invoices.filter { $0.status != .void && $0.dueDay < today && (balance(invoice: $0.id) ?? 0) > 0 }
        if !overdue.isEmpty { out.append("\(overdue.count) overdue invoice(s)") }
        return out
    }
}
