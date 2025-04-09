class AttendanceViewModel: ObservableObject {
    @Published var employees: [Employee] = []
    @Published var attendanceRecords: [AttendanceRecord] = []
    @Published var searchText: String = ""
    @Published var selectedDate: Date = Date()
    @Published var showImportSheet: Bool = false
    @Published var showStats: Bool = false
    
    var filteredEmployees: [Employee] {
        if searchText.isEmpty {
            return employees
        } else {
            return employees.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.operatorNumber.localizedCaseInsensitiveContains(searchText) ||
                $0.area.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func toggleAttendance(for employeeId: UUID) {
        if let index = attendanceRecords.firstIndex(where: { $0.employeeId == employeeId && Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
            attendanceRecords[index].isPresent.toggle()
        } else {
            let newRecord = AttendanceRecord(employeeId: employeeId, date: selectedDate, isPresent: false)
            attendanceRecords.append(newRecord)
        }
    }
    
    func isPresent(employeeId: UUID) -> Bool {
        !attendanceRecords.contains(where: { $0.employeeId == employeeId && 
                                          Calendar.current.isDate($0.date, inSameDayAs: selectedDate) && 
                                          !$0.isPresent })
    }
    
    func getAttendanceStats() -> (present: Int, absent: Int, frequentAbsentees: [Employee]) {
        let todayRecords = attendanceRecords.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
        let absentCount = todayRecords.filter { !$0.isPresent }.count
        let presentCount = employees.count - absentCount
        
        // Obtener empleados con más faltas (más de 3 faltas en los últimos 30 días)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let recentAbsences = attendanceRecords.filter { $0.date >= thirtyDaysAgo && !$0.isPresent }
        
        let absenceCounts = Dictionary(recentAbsences.map { ($0.employeeId, 1) }, uniquingKeysWith: +)
        let frequentAbsentees = absenceCounts.filter { $0.value > 3 }.compactMap { employeeId, _ in
            employees.first { $0.id == employeeId }
        }
        
        return (presentCount, absentCount, frequentAbsentees)
    }
    
    func importEmployees(from csvData: Data) {
        // Implementación simplificada - en producción necesitarías un parser CSV robusto
        let string = String(decoding: csvData, as: UTF8.self)
        let lines = string.components(separatedBy: .newlines)
        
        for line in lines.dropFirst() where !line.isEmpty {
            let components = line.components(separatedBy: ",")
            if components.count >= 4 {
                let newEmployee = Employee(
                    operatorNumber: components[0].trimmingCharacters(in: .whitespaces),
                    name: components[1].trimmingCharacters(in: .whitespaces),
                    area: components[2].trimmingCharacters(in: .whitespaces),
                    supervisor: components[3].trimmingCharacters(in: .whitespaces)
                )
                employees.append(newEmployee)
            }
        }
    }
}