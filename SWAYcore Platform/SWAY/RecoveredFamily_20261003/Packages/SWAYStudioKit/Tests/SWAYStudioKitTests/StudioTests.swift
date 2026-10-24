import XCTest
@testable import SWAYStudioKit

final class StudioTests: XCTestCase {
    func tmp() -> URL { FileManager.default.temporaryDirectory.appendingPathComponent("studio-\(UUID().uuidString)/studio.json") }

    /// Clean-data acceptance path from the spec.
    func testAcceptanceWorkflowAndRelaunch() throws {
        let url = tmp(); var s: StudioStore! = try StudioStore(url: url)
        let teacher = Person(name: "Ana", role: .instructor), m1 = Person(name: "Bo", role: .member), m2 = Person(name: "Cy", role: .member)
        try [teacher, m1, m2].forEach { try s.add($0) }
        let plan = MembershipPlan(name: "Unlimited", priceCents: 9000); try s.add(plan)
        // 2026-10-05 is a Monday
        let cls = StudioClass(title: "Salsa", instructorID: teacher.id, capacity: 1, startDay: "2026-10-05", startMinute: 18 * 60, recurrence: .weekly(weekdays: [2], until: nil))
        try s.add(cls)
        try s.start(plan: plan.id, member: m1.id, day: "2026-10-01"); try s.start(plan: plan.id, member: m2.id, day: "2026-10-01")
        try s.enroll(member: m1.id, classID: cls.id)
        XCTAssertThrowsError(try s.enroll(member: m2.id, classID: cls.id)) { XCTAssertEqual($0 as? StudioError, .classFull) }
        try s.record(attendance: .present, member: m1.id, classID: cls.id, day: "2026-10-12")
        let inv = Invoice(memberID: m1.id, description: "October", amountCents: 9000, issuedDay: "2026-10-01", dueDay: "2026-10-10"); try s.issue(inv)
        try s.pay(Payment(invoiceID: inv.id, amountCents: 4000, day: "2026-10-02", method: "card"))
        XCTAssertEqual(s.balance(invoice: inv.id), 5000); XCTAssertEqual(s.outstanding(member: m1.id), 5000)
        XCTAssertEqual(s.summary(today: "2026-10-15"), FinanceSummary(invoicedCents: 9000, collectedCents: 4000, outstandingCents: 5000, overdueCents: 5000))
        s = nil
        let r = try StudioStore(url: url)   // quit / relaunch
        XCTAssertEqual(r.data.people.count, 3); XCTAssertEqual(r.roster(classID: cls.id, day: "2026-10-12"), [m1.id])
        XCTAssertEqual(r.attendanceHistory(member: m1.id).first?.status, .present)
        XCTAssertEqual(r.data.invoices.first?.status, .partiallyPaid); XCTAssertEqual(r.summary(today: "2026-10-15").collectedCents, 4000)
    }
    func testRecurrenceAndCancellation() throws {
        let s = try StudioStore()
        try s.add(StudioClass(title: "A", capacity: 5, startDay: "2026-10-05", startMinute: 600, recurrence: .weekly(weekdays: [2, 4], until: "2026-10-14")))
        XCTAssertEqual(s.occurrences(from: "2026-10-05", through: "2026-10-31").map(\.day), ["2026-10-05", "2026-10-07", "2026-10-12", "2026-10-14"])
        try s.cancel(classID: s.data.classes[0].id, day: "2026-10-07")
        XCTAssertEqual(s.occurrences(from: "2026-10-05", through: "2026-10-31").count, 3)
        XCTAssertTrue(s.occurrences(from: "2026-10-31", through: "2026-10-01").isEmpty)
    }
    func testInstructorConflictRollsBack() throws {
        let s = try StudioStore(); let t = Person(name: "T", role: .instructor); try s.add(t)
        try s.add(StudioClass(title: "A", instructorID: t.id, capacity: 5, startDay: "2026-10-05", startMinute: 600))
        XCTAssertThrowsError(try s.add(StudioClass(title: "B", instructorID: t.id, capacity: 5, startDay: "2026-10-05", startMinute: 630))) { XCTAssertEqual($0 as? StudioError, .instructorConflict) }
        XCTAssertEqual(s.data.classes.count, 1)
        try s.add(StudioClass(title: "C", instructorID: t.id, capacity: 5, startDay: "2026-10-05", startMinute: 660))   // back-to-back is fine
    }
    func testEnrollmentRules() throws {
        let s = try StudioStore(); let m = Person(name: "M", role: .member); let i = Person(name: "I", role: .instructor); try s.add(m); try s.add(i)
        let c = StudioClass(title: "A", capacity: 2, startDay: "2026-10-05", startMinute: 600); try s.add(c)
        XCTAssertThrowsError(try s.enroll(member: m.id, classID: c.id)) { XCTAssertEqual($0 as? StudioError, .noActiveMembership) }
        let p = MembershipPlan(name: "P", priceCents: 1); try s.add(p); try s.start(plan: p.id, member: m.id, day: "2026-10-01")
        try s.enroll(member: m.id, classID: c.id)
        XCTAssertThrowsError(try s.enroll(member: m.id, classID: c.id)) { XCTAssertEqual($0 as? StudioError, .alreadyEnrolled) }
        XCTAssertThrowsError(try s.enroll(member: i.id, classID: c.id))     // instructors are not members
        XCTAssertThrowsError(try s.record(attendance: .present, member: "ghost", classID: c.id, day: "2026-10-05")) { XCTAssertEqual($0 as? StudioError, .notEnrolled) }
        try s.unenroll(member: m.id, classID: c.id); XCTAssertTrue(s.roster(classID: c.id, day: "2026-10-05").isEmpty)
        XCTAssertThrowsError(try s.unenroll(member: m.id, classID: c.id))
    }
    func testMembershipLifecycle() throws {
        let s = try StudioStore(); let m = Person(name: "M", role: .member); try s.add(m)
        let p = MembershipPlan(name: "P", priceCents: 1); try s.add(p)
        try s.start(plan: p.id, member: m.id, day: "2026-10-01"); XCTAssertTrue(s.hasActiveMembership(m.id, on: "2026-10-02"))
        let id = s.data.memberships[0].id
        try s.setMembership(id, status: .paused, day: "2026-10-05"); XCTAssertFalse(s.hasActiveMembership(m.id, on: "2026-10-06"))
        try s.setMembership(id, status: .active, day: "2026-10-07"); try s.setMembership(id, status: .cancelled, day: "2026-10-09")
        XCTAssertFalse(s.hasActiveMembership(m.id, on: "2026-10-10")); XCTAssertTrue(s.hasActiveMembership(m.id, on: "2026-10-09"))
    }
    func testBillingRules() throws {
        let s = try StudioStore(); let m = Person(name: "M", role: .member); try s.add(m)
        let inv = Invoice(memberID: m.id, description: "x", amountCents: 1000, issuedDay: "2026-10-01", dueDay: "2026-10-05"); try s.issue(inv)
        XCTAssertThrowsError(try s.pay(Payment(invoiceID: inv.id, amountCents: 1001, day: "d", method: "cash"))) { XCTAssertEqual($0 as? StudioError, .overpayment) }
        XCTAssertThrowsError(try s.pay(Payment(invoiceID: inv.id, amountCents: 0, day: "d", method: "cash")))
        try s.pay(Payment(invoiceID: inv.id, amountCents: 1000, day: "d", method: "cash")); XCTAssertEqual(s.data.invoices[0].status, .paid)
        XCTAssertThrowsError(try s.void(invoice: inv.id))
        XCTAssertThrowsError(try s.issue(Invoice(memberID: "ghost", description: "", amountCents: 5, issuedDay: "", dueDay: "")))
        XCTAssertEqual(s.exceptions(today: "2026-10-20"), [])
    }
    func testExceptionsListActionableItems() throws {
        let s = try StudioStore(); let m = Person(name: "M", role: .member); try s.add(m)
        try s.add(StudioClass(title: "NoTeacher", capacity: 1, startDay: "2026-10-05", startMinute: 600))
        try s.issue(Invoice(memberID: m.id, description: "x", amountCents: 100, issuedDay: "2026-09-01", dueDay: "2026-09-10"))
        XCTAssertEqual(s.exceptions(today: "2026-10-05"), ["NoTeacher: no instructor assigned", "1 overdue invoice(s)"])
    }
    func testV1MigrationAndCorruptRecovery() throws {
        let v1 = """
        {"schemaVersion":1,"studioName":"Old","members":[{"id":"m1","name":"Old Member"}],"invoices":[{"id":"i1","memberID":"m1","description":"d","amountCents":500,"issuedDay":"2026-01-01","status":"open"}]}
        """
        let d = try StudioStore.decode(Data(v1.utf8))
        XCTAssertEqual(d.schemaVersion, 2); XCTAssertEqual(d.people.first?.role, .member); XCTAssertEqual(d.invoices.first?.dueDay, "2026-01-01"); XCTAssertEqual(d.studioName, "Old")
        XCTAssertThrowsError(try StudioStore.decode(Data("{\"schemaVersion\":9}".utf8)))
        XCTAssertThrowsError(try StudioStore.decode(Data("junk".utf8)))
        let url = tmp(); let s = try StudioStore(url: url); try s.add(Person(name: "A", role: .member)); try s.add(Person(name: "B", role: .member))
        try Data("corrupt".utf8).write(to: url)
        XCTAssertEqual(try StudioStore(url: url).data.people.count, 1)     // falls back to .bak (previous good save)
    }
    func testFailedMutationLeavesNoPartialState() throws {
        let s = try StudioStore(); XCTAssertThrowsError(try s.add(Person(name: "  ", role: .member))); XCTAssertTrue(s.data.people.isEmpty)
        XCTAssertThrowsError(try s.add(StudioClass(title: "bad", capacity: 0, startDay: "2026-10-05", startMinute: 1))); XCTAssertTrue(s.data.classes.isEmpty)
    }
    func testInactiveInstructorCannotBeAssigned() throws {
        let s = try StudioStore(); let t = Person(name: "T", role: .instructor, active: false); try s.add(t)
        XCTAssertThrowsError(try s.add(StudioClass(title: "A", instructorID: t.id, capacity: 5, startDay: "2026-10-05", startMinute: 600))) { XCTAssertEqual($0 as? StudioError, .inactiveInstructor) }
    }
}
