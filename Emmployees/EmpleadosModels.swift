//
//  EmployeeStatus.swift
//  Test AFL
//
//  Created by Ulises Islas on 09/04/25.
//


import Foundation

enum EmployeeStatus: String, Codable, CaseIterable {
    case active = "Activo"
    case inactive = "Baja"
    case onLeave = "Permiso"
    case onVacation = "Vacaciones"
    case suspended = "Suspencion"
}

enum AttendanceStatus: String, Codable {
    case present = "Presente"
    case absent = "Ausente"
    case terminated = "Baja"
    case onLeave = "Permiso"
    case onVacation = "Vacaciones"
    case suspended = "Suspencion"
}

struct Employee: Identifiable, Codable, Hashable {
    let id: UUID
    var operatorNumber: String
    var name: String
    var area: String
    var supervisor: String
    var status: EmployeeStatus
    var terminationDate: Date?
    
    init(id: UUID = UUID(), operatorNumber: String, name: String, area: String, supervisor: String, status: EmployeeStatus = .active, terminationDate: Date? = nil) {
        self.id = id
        self.operatorNumber = operatorNumber
        self.name = name
        self.area = area
        self.supervisor = supervisor
        self.status = status
        self.terminationDate = terminationDate
    }
}

struct AttendanceRecord: Identifiable, Codable {
    let id: UUID
    let employeeId: UUID
    let date: Date
    var status: AttendanceStatus
    var absenceReason: String?
    
    init(id: UUID = UUID(), employeeId: UUID, date: Date = Date(), status: AttendanceStatus = .present, absenceReason: String? = nil) {
        self.id = id
        self.employeeId = employeeId
        self.date = date
        self.status = status
        self.absenceReason = absenceReason
    }
}

struct AttendanceStats {
    let present: Int
    let absent: Int
    let terminated: Int
    let onVacation: Int
    let suspended: Int
    let onleave: Int
    let totalEmployees: Int
    let activeEmployees: Int
    let operatorsByArea: [(key: String, value: Int)]
    let attendancePercentage: Double
    let totalHoursWorked: Double
    let frequentAbsentees: [Employee]
    let attendanceByArea: [(area: String, present: Int, total: Int)]
}

