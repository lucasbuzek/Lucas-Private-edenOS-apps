import Foundation

/// Studio operations domain (ND-007). Deliberately independent of SWAYcoreKit's movement engine;
/// classes may *reference* SWAYZ content by opaque id (`choreographyRef`) only.
public struct Person: Codable, Equatable, Identifiable, Sendable {
    public enum Role: String, Codable, Sendable { case instructor, staff, member }
    public var id: String, name: String, email: String?, phone: String?, role: Role, active: Bool, notes: String
    public init(id: String = UUID().uuidString, name: String, email: String? = nil, phone: String? = nil, role: Role, active: Bool = true, notes: String = "") {
        self.id = id; self.name = name; self.email = email; self.phone = phone; self.role = role; self.active = active; self.notes = notes
    }
}

public struct MembershipPlan: Codable, Equatable, Identifiable, Sendable {
    public var id: String, name: String, priceCents: Int, classesPerPeriod: Int?, periodDays: Int
    public init(id: String = UUID().uuidString, name: String, priceCents: Int, classesPerPeriod: Int? = nil, periodDays: Int = 30) {
        self.id = id; self.name = name; self.priceCents = priceCents; self.classesPerPeriod = classesPerPeriod; self.periodDays = periodDays
    }
}

/// Explicit lifecycle history for memberships created by this version.
 /// Legacy schema-v2 memberships have no recoverable historical event stream.
public struct MembershipStatusEvent: Codable, Equatable, Sendable {
    public var status: Membership.Status, day: String
    public init(status: Membership.Status, day: String) { self.status = status; self.day = day }
}

public struct Membership: Codable, Equatable, Identifiable, Sendable {
    public enum Status: String, Codable, Sendable { case active, paused, cancelled, expired }
    public var id: String, memberID: String, planID: String, status: Status, startDay: String, endDay: String?
    public var statusEvents: [MembershipStatusEvent]?
    public init(id: String = UUID().uuidString, memberID: String, planID: String, status: Status = .active, startDay: String, endDay: String? = nil) {
        self.id = id; self.memberID = memberID; self.planID = planID; self.status = status; self.startDay = startDay; self.endDay = endDay
        self.statusEvents = [MembershipStatusEvent(status: status, day: startDay)]
    }
}

public struct StudioClass: Codable, Equatable, Identifiable, Sendable {
    public enum Recurrence: Codable, Equatable, Sendable { case once, weekly(weekdays: [Int], until: String?) }   // weekday 1=Sun ... 7=Sat
    public var id: String, title: String, instructorID: String?, capacity: Int
    public var startDay: String      // yyyy-MM-dd of first occurrence
    public var startMinute: Int      // minutes after midnight, studio-local
    public var durationMinutes: Int
    public var recurrence: Recurrence
    public var choreographyRef: String?
    public var cancelledDays: [String]
    public init(id: String = UUID().uuidString, title: String, instructorID: String? = nil, capacity: Int, startDay: String, startMinute: Int,
                durationMinutes: Int = 60, recurrence: Recurrence = .once, choreographyRef: String? = nil, cancelledDays: [String] = []) {
        self.id = id; self.title = title; self.instructorID = instructorID; self.capacity = capacity; self.startDay = startDay
        self.startMinute = startMinute; self.durationMinutes = durationMinutes; self.recurrence = recurrence
        self.choreographyRef = choreographyRef; self.cancelledDays = cancelledDays
    }
}

/// Enrollment is per class-session (class id + day) roster entry; `standing` enrollments apply to every occurrence.
public struct Enrollment: Codable, Equatable, Identifiable, Sendable {
    public var id: String, classID: String, memberID: String, day: String?   // nil = standing
    public init(id: String = UUID().uuidString, classID: String, memberID: String, day: String? = nil) { self.id = id; self.classID = classID; self.memberID = memberID; self.day = day }
}

public struct AttendanceRecord: Codable, Equatable, Identifiable, Sendable {
    public enum Status: String, Codable, Sendable { case present, absent, late, excused }
    public var id: String, classID: String, day: String, memberID: String, status: Status
    public init(id: String = UUID().uuidString, classID: String, day: String, memberID: String, status: Status) {
        self.id = id; self.classID = classID; self.day = day; self.memberID = memberID; self.status = status
    }
}

public struct Invoice: Codable, Equatable, Identifiable, Sendable {
    public enum Status: String, Codable, Sendable { case open, partiallyPaid, paid, void }
    public var id: String, memberID: String, description: String, amountCents: Int, issuedDay: String, dueDay: String, status: Status
    public init(id: String = UUID().uuidString, memberID: String, description: String, amountCents: Int, issuedDay: String, dueDay: String, status: Status = .open) {
        self.id = id; self.memberID = memberID; self.description = description; self.amountCents = amountCents; self.issuedDay = issuedDay; self.dueDay = dueDay; self.status = status
    }
}

public struct Payment: Codable, Equatable, Identifiable, Sendable {
    public var id: String, invoiceID: String, amountCents: Int, day: String, method: String
    public init(id: String = UUID().uuidString, invoiceID: String, amountCents: Int, day: String, method: String) {
        self.id = id; self.invoiceID = invoiceID; self.amountCents = amountCents; self.day = day; self.method = method
    }
}

public struct StudioNote: Codable, Equatable, Identifiable, Sendable {
    public var id: String, day: String, text: String
    public init(id: String = UUID().uuidString, day: String, text: String) { self.id = id; self.day = day; self.text = text }
}

public struct StudioData: Codable, Equatable, Sendable {
    public static let currentSchema = 2
    public var schemaVersion = StudioData.currentSchema
    public var studioName = "My Studio"
    public var people: [Person] = []
    public var plans: [MembershipPlan] = []
    public var memberships: [Membership] = []
    public var classes: [StudioClass] = []
    public var enrollments: [Enrollment] = []
    public var attendance: [AttendanceRecord] = []
    public var invoices: [Invoice] = []
    public var payments: [Payment] = []
    public var notes: [StudioNote] = []
    public init() {}
}
