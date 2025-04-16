//
//  AttendanceViewModel.swift
//  Test A
//
//  Created by Uls on 08/04/25.
//

import SwiftUI
import UIKit
import Foundation
import WidgetKit
import AppIntents
import Combine

class AttendanceViewModel: ObservableObject {
    @Published var employees: [Employee] = []
    @Published var attendanceRecords: [AttendanceRecord] = []
    @Published var searchText: String = ""
    @Published var selectedDate: Date = Date()
    @Published var showImportSheet: Bool = false
    @Published var dailyHours: Double = 12.0

    private var attendanceStatus: [UUID: Bool] = [:]
    private var temporaryStatuses: [UUID: EmployeeStatus] = [:]

    init() {
        loadEmployees()
        loadAttendanceRecords()
    }

    enum SortOption {
        case byOperatorNumber
        case byAreaThenOperatorNumber
        case byStatus
    }

    // Agrega esta propiedad al ViewModel
    @Published var currentSortOption: SortOption = .byOperatorNumber

    // Agrega esta función para ordenar
    func sortEmployees(_ employees: [Employee], by option: SortOption) -> [Employee] {
        switch option {
        case .byOperatorNumber:
            return employees.sorted { $0.operatorNumber < $1.operatorNumber }
        case .byAreaThenOperatorNumber:
            return employees.sorted {
                if $0.area == $1.area {
                    return $0.operatorNumber < $1.operatorNumber
                }
                return $0.area < $1.area
            }
        case .byStatus:
            return employees.sorted {
                if $0.status == $1.status {
                    return $0.operatorNumber < $1.operatorNumber
                }
                return $0.status.rawValue < $1.status.rawValue
            }
        }
    }
    
    // MARK: - Employee Management

    var activeEmployees: [Employee] {
        employees.filter { $0.status == .active }
    }
    
    func addEmployee(_ employee: Employee) {
        employees.append(employee)
        saveEmployees()
    }

    func updateEmployee(_ employee: Employee) {
        if let index = employees.firstIndex(where: { $0.id == employee.id }) {
            employees[index] = employee
            saveEmployees()
        }
    }

    func deleteEmployee(_ employee: Employee) {
        employees.removeAll { $0.id == employee.id }
        attendanceRecords.removeAll { $0.employeeId == employee.id }
        saveEmployees()
        saveAttendanceRecords()
    }

    func terminateEmployee(_ employee: Employee, terminationDate: Date?) {
        if let index = employees.firstIndex(where: { $0.id == employee.id }) {
            employees[index].status = .inactive
            employees[index].terminationDate = terminationDate
            saveEmployees()
        }
    }

    // MARK: - Attendance Management

    func toggleAttendance(for employeeId: UUID) {
        // Eliminar registros existentes para hoy
        attendanceRecords.removeAll { record in
            record.employeeId == employeeId && Calendar.current.isDate(record.date, inSameDayAs: selectedDate)
        }

        if let isPresent = attendanceStatus[employeeId], isPresent {
            attendanceStatus[employeeId] = false
            let newRecord = AttendanceRecord(employeeId: employeeId, date: selectedDate, status: .absent)
            attendanceRecords.append(newRecord)
        } else {
            attendanceStatus[employeeId] = true
            let newRecord = AttendanceRecord(employeeId: employeeId, date: selectedDate, status: .present)
            attendanceRecords.append(newRecord)
        }
        saveAttendanceRecords()
    }

    func toggleAttendance(for employeeId: UUID, temporaryStatus: EmployeeStatus) {
        // Eliminar registros existentes para hoy
        attendanceRecords.removeAll { record in
            record.employeeId == employeeId && Calendar.current.isDate(record.date, inSameDayAs: selectedDate)
        }

        if temporaryStatus == .onLeave {
            let newRecord = AttendanceRecord(employeeId: employeeId, date: selectedDate, status: .onLeave, absenceReason: "Permiso")
            attendanceRecords.append(newRecord)
        } else if temporaryStatus == .suspended {
            let newRecord = AttendanceRecord(employeeId: employeeId, date: selectedDate, status: .suspended, absenceReason: "Suspension")
            attendanceRecords.append(newRecord)
        }
        saveAttendanceRecords()
    }

    func markPresent(_ employeeId: UUID) {
        attendanceRecords.removeAll { record in
            record.employeeId == employeeId && Calendar.current.isDate(record.date, inSameDayAs: selectedDate)
        }
        let newRecord = AttendanceRecord(employeeId: employeeId, date: selectedDate, status: .present)
        attendanceRecords.append(newRecord)
        saveAttendanceRecords()
    }

    func markAbsent(_ employeeId: UUID) {
        attendanceRecords.removeAll { record in
            record.employeeId == employeeId && Calendar.current.isDate(record.date, inSameDayAs: selectedDate)
        }
        let newRecord = AttendanceRecord(employeeId: employeeId, date: selectedDate, status: .absent)
        attendanceRecords.append(newRecord)
        saveAttendanceRecords()
    }

    func isEmployeePresent(_ employeeId: UUID) -> Bool {
      // Check for temporary statuses first
      if temporaryStatuses[employeeId] != nil {
      return false // Consider temporarily absent
      }
     

      // Check for attendance records
      let todayRecord = attendanceRecords.first { record in
      record.employeeId == employeeId && Calendar.current.isDate(record.date, inSameDayAs: selectedDate)
      }
     

      return todayRecord?.status == .present
     }

    func todayRecordsCount() -> Int {
        return attendanceRecords.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }.count
    }

    func clearAllAttendanceRecords() {
        attendanceRecords.removeAll { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
        saveAttendanceRecords()
    }

    // MARK: - Bulk Operations

    func markAllPresent() {
        // Primero eliminar cualquier registro existente para hoy
        attendanceRecords.removeAll { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }

        // Crear nuevos registros para todos como presentes
        let activeEmployees = employees.filter { $0.status == .active }
        let newRecords = activeEmployees.map { employee in
            AttendanceRecord(employeeId: employee.id, date: selectedDate, status: .present)
        }
        attendanceRecords.append(contentsOf: newRecords)
        saveAttendanceRecords()
    }

    func markAllAbsent() {
        // Primero eliminar registros existentes para hoy
        attendanceRecords.removeAll { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }

        let activeEmployees = employees.filter { $0.status == .active }
        let newRecords = activeEmployees.map { employee in
            AttendanceRecord(employeeId: employee.id, date: selectedDate, status: .absent)
        }
        attendanceRecords.append(contentsOf: newRecords)
        saveAttendanceRecords()
    }

    // MARK: - File Persistence

    private var employeesFileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("employees.json")
    }

    private var attendanceRecordsFileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("attendance_records.json")
    }

    func saveEmployees() {
        do {
            let data = try JSONEncoder().encode(employees)
            try data.write(to: employeesFileURL)
            print("Empleados guardados en archivo.")
        } catch {
            print("Error al guardar empleados: \(error)")
        }
    }

    func loadEmployees() {
        do {
            let data = try Data(contentsOf: employeesFileURL)
            employees = try JSONDecoder().decode([Employee].self, from: data)
            print("Empleados cargados desde archivo.")
        } catch {
            print("No se encontraron datos previos o hubo error: \(error)")
        }
    }

    func saveAttendanceRecords() {
        do {
            let data = try JSONEncoder().encode(attendanceRecords)
            try data.write(to: attendanceRecordsFileURL)
            print("Registros de asistencia guardados.")
        } catch {
            print("Error guardando registros de asistencia: \(error)")
        }
    }

    func loadAttendanceRecords() {
        do {
            let data = try Data(contentsOf: attendanceRecordsFileURL)
            attendanceRecords = try JSONDecoder().decode([AttendanceRecord].self, from: data)
            print("Registros de asistencia cargados.")
        } catch {
            print("Error cargando registros de asistencia: \(error)")
        }
    }

    // MARK: - Import/Export

    func importEmployees(from data: Data) {
     
    }

    func exportToCSV() -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let csvHeader = "Fecha,NumeroOperador,Nombre,Area,Estado\n"
        var csvString = csvHeader
        
        for record in attendanceRecords {
            guard let employee = employees.first(where: { $0.id == record.employeeId }) else { continue }
            
            let dateStr = dateFormatter.string(from: record.date)
            let line = "\(dateStr),\(employee.operatorNumber),\(employee.name),\(employee.area),\(record.status.rawValue)\n"
            csvString.append(line)
        }
        
        do {
            let path = FileManager.default.temporaryDirectory
                .appendingPathComponent("asistencia_\(Date().timeIntervalSince1970).csv")
            try csvString.write(to: path, atomically: true, encoding: .utf8)
            return path
        } catch {
            print("Error exportando CSV: \(error)")
            return nil
        }
    }

    // MARK: - Statistics

    enum TimeRange {
        case today, week, month
    }

    
    
    func getAttendanceStats(for timeRange: TimeRange = .today) -> AttendanceStats {
     //   let attendancePercentage: Double
        let calendar = Calendar.current
        let today = selectedDate
        
        // 1. Determinar el rango de fechas según la selección
        let startDate: Date
        let endDate: Date
        
        switch timeRange {
        case .today:
            startDate = calendar.startOfDay(for: today)
            endDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? today
            
        case .week:
            startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
            endDate = calendar.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? today
            
        case .month:
            startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
            endDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? today
        }
        
        // 2. Filtrar registros y empleados según el rango
        let relevantRecords = attendanceRecords.filter {
            $0.date >= startDate && $0.date < endDate
        }
        
        let activeEmployees = employees.filter { $0.status == .active }
        let terminatedEmployees = employees.filter { $0.status == .inactive }
        
        // 3. Calcular estadísticas básicas
        let presentCount = relevantRecords.filter { $0.status == .present }.count
        let absentCount = relevantRecords.filter { $0.status == .absent }.count
        let terminatedCount = terminatedEmployees.count
        let onVacationCount = employees.filter { $0.status == .onVacation }.count
        let suspendedCount = employees.filter { $0.status == .suspended }.count
        let onLeaveCount = employees.filter { $0.status == .onLeave }.count
        
        // 4. Estadísticas por área
        let operatorsByArea = Dictionary(grouping: activeEmployees, by: { $0.area })
            .mapValues { $0.count }
            .sorted { $0.key < $1.key }
        
        let attendanceByArea: [(area: String, present: Int, total: Int)] = {
            let grouped = Dictionary(grouping: activeEmployees, by: { $0.area })
            return grouped.map { area, employeesInArea in
                let present = employeesInArea.filter { employee in
                    relevantRecords.contains {
                        $0.employeeId == employee.id && $0.status == .present
                    }
                }.count
                return (area: area, present: present, total: employeesInArea.count)
            }.sorted { $0.area < $1.area }
        }()
        
        // 5. Porcentaje de asistencia
        let employeesExpectedToWork = employees.filter {
                $0.status == .active &&
                $0.status != .onVacation &&
                $0.status != .onLeave &&
                $0.status != .suspended
            }.count
            
            // Calcular porcentaje de asistencia
            let attendancePercentage: Double
            if employeesExpectedToWork == 0 {
                attendancePercentage = 0.0
            } else {
                // Solo contar presentes vs los que se espera que trabajen
                attendancePercentage = min((Double(presentCount) / Double(employeesExpectedToWork)) * 100, 100)
            }
        
        // 6. Horas trabajadas
        let totalHoursWorked = Double(presentCount) * dailyHours
        
        // 7. Empleados con múltiples faltas (últimos 30 días)
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today)!
        let recentAbsences = attendanceRecords.filter {
            $0.date >= thirtyDaysAgo && $0.status == .absent
        }
        
        let absenceCounts = Dictionary(recentAbsences.map { ($0.employeeId, 1) }, uniquingKeysWith: +)
        let frequentAbsentees = absenceCounts
            .filter { $0.value >= 3 } // 3+ faltas en 30 días
            .compactMap { employeeId, _ in
                employees.first { $0.id == employeeId }
            }
            .sorted { $0.name < $1.name }
        
        // 8. Crear y retornar el objeto de estadísticas
        return AttendanceStats(
            present: presentCount,
            absent: absentCount,
            terminated: terminatedCount,
            onVacation: onVacationCount,
            suspended: suspendedCount,
            onleave: onLeaveCount,
            totalEmployees: employees.count,
            activeEmployees: activeEmployees.count,
            operatorsByArea: operatorsByArea,
            attendancePercentage: attendancePercentage,
            totalHoursWorked: totalHoursWorked,
            frequentAbsentees: frequentAbsentees,
            attendanceByArea: attendanceByArea
        )
    }

    // MARK: - Helper Functions
    func calculateAttendancePercentage(for timeRange: TimeRange) -> Double {
        let calendar = Calendar.current
        let today = selectedDate
        
        // 1. Determinar el rango de fechas
        let startDate: Date
        let endDate: Date
        
        switch timeRange {
        case .today:
            startDate = calendar.startOfDay(for: today)
            endDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? today
        case .week:
            startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
            endDate = calendar.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? today
        case .month:
            startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
            endDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? today
        }
        
        // 2. Filtrar registros en el rango
        let relevantRecords = attendanceRecords.filter {
            $0.date >= startDate && $0.date < endDate
        }
        
        // 3. Contar presentes y ausentes
        let presentCount = relevantRecords.filter { $0.status == .present }.count
        let absentCount = relevantRecords.filter { $0.status == .absent }.count
        
        // 4. Calcular porcentaje (evitar división por cero)
        guard presentCount + absentCount > 0 else { return 0.0 }
        
        return (Double(presentCount) / Double(presentCount + absentCount)) * 100
    }

 /*   func getAttendancePercentage(for timeRange: TimeRange = .today) -> Double {
        let calendar = Calendar.current
        let today = selectedDate
        
        // 1. Determinar el rango de fechas
        let startDate: Date
        let endDate: Date
        
        switch timeRange {
        case .today:
            startDate = calendar.startOfDay(for: today)
            endDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? today
        case .week:
            startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
            endDate = calendar.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? today
        case .month:
            startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
            endDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? today
        }
        
        // 2. Filtrar registros en el rango y solo contar presentes/ausentes
        let relevantRecords = attendanceRecords.filter {
            $0.date >= startDate && $0.date < endDate &&
            ($0.status == .present || $0.status == .absent)
        }
        
        let presentCount = relevantRecords.filter { $0.status == .present }.count
        let absentCount = relevantRecords.filter { $0.status == .absent }.count
        let totalRecords = presentCount + absentCount
        
        // 3. Calcular porcentaje (evitar división por cero)
        guard totalRecords > 0 else { return 0.0 }
        
        return (Double(presentCount) / Double(totalRecords)) * 100
    }*/
        
    
    func getAllAreas() -> [String] {
        let allAreas = Array(Set(employees.map { $0.area })).sorted()
        return ["Todos"] + allAreas
    }

    func getFilteredEmployees(area: String, showAbsentOnly: Bool) -> [Employee] {
        let baseList = searchText.isEmpty ? employees : employees.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.operatorNumber.contains(searchText) }

        let filtradosPorArea = area == "Todos" ? baseList : baseList.filter { $0.area == area }

        if showAbsentOnly {
            return filtradosPorArea.filter { employee in
                attendanceRecords.contains {
                    $0.employeeId == employee.id &&
                    Calendar.current.isDate($0.date, inSameDayAs: selectedDate) &&
                    $0.status == .absent
                }
            }
        } else {
            return filtradosPorArea
        }
    }
}
    
    struct AttendanceView: View {
        @EnvironmentObject var viewModel: AttendanceViewModel
        @State private var showingAddEmployee = false
        @State private var showingImportSheet = false
        @State private var newEmployee = Employee(operatorNumber: "", name: "", area: "", supervisor: "")
        @Environment(\.dismiss) var dismiss // For going back
        
        var body: some View {
            NavigationStack {
                AttendanceListView()
                    .navigationTitle("Control de Asistencia")
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                           
                            NavigationLink {
                            AttendanceStatsView()
                            .environmentObject(viewModel)
                            } label: {
                            Label("Estadísticas", systemImage: "chart.bar")
                            }
                            
                            Button(action: { showingImportSheet = true }) {
                                Label("Importar", systemImage: "square.and.arrow.down")
                            }
                            
                            Button(action: { showingAddEmployee = true }) {
                                Label("Agregar", systemImage: "person.badge.plus")
                            }
                        }
                    }
                    .sheet(isPresented: $showingAddEmployee) {
                        AddEmployeeView(employee: newEmployee, isEditing: false) { newEmployee in
                            viewModel.addEmployee(newEmployee)
                            self.newEmployee = Employee(operatorNumber: "", name: "", area: "", supervisor: "")
                        }
                    }
                    .sheet(isPresented: $showingImportSheet) {
                        DocumentPicker { url in
                            do {
                                let data = try Data(contentsOf: url)
                                viewModel.importEmployees(from: data)
                            } catch {
                                print("Error importing file: \(error)")
                            }
                        }
                    }
            }
        }
    }

//MARK: ATTENDANCELISTVIEW
struct AttendanceListView: View {
    @EnvironmentObject var viewModel: AttendanceViewModel
    @State private var mostrarSoloFaltas = false
    @State private var selectedArea: String = "Todos"
    @State private var employeeToEdit: Employee?
    @State private var showBulkActions = false
    @State private var showHoursConfig = false
    @State private var showConfirmationAlert: Bool = false
    @State private var showSortOptions = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                CompactDatePicker(selectedDate: $viewModel.selectedDate)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))

                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .background(Color(.systemBackground))

                AreaFilterView(selectedArea: $selectedArea, areas: viewModel.getAllAreas())
                    .padding(.bottom, 8)
                    .background(Color(.systemBackground))

                HStack {
                                    Text("Ordenar por:")
                                        .font(.caption)
                                    
                                    Button(action: { showSortOptions.toggle() }) {
                                        HStack {
                                            Text(currentSortOptionText)
                                            Image(systemName: "chevron.down")
                                        }
                                        .font(.caption)
                                        .padding(6)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(8)
                                    }
                                    .actionSheet(isPresented: $showSortOptions) {
                                        ActionSheet(
                                            title: Text("Ordenar empleados por"),
                                            buttons: [
                                                .default(Text("Número de empleado")) {
                                                    viewModel.currentSortOption = .byOperatorNumber
                                                },
                                                .default(Text("Área y número")) {
                                                    viewModel.currentSortOption = .byAreaThenOperatorNumber
                                                },
                                                .default(Text("Estado")) {
                                                    viewModel.currentSortOption = .byStatus
                                                },
                                                .cancel()
                                            ]
                                        )
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("Mostrar solo con falta", isOn: $mostrarSoloFaltas)
                                        .font(.caption)
                                }
                                .padding(.horizontal)
                    .toggleStyle(.switch)
                
                
                
                if showBulkActions {
                    HStack {
                        Button(action: {
                            viewModel.markAllPresent()
                        }) {
                            Label("Todos Presentes", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .padding(8)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                        }

                        Button(action: {
                            viewModel.markAllAbsent()
                        }) {
                            Label("Marcar Ausentes", systemImage: "xmark.circle.fill")
                                .font(.caption)
                                .padding(8)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(8)
                        }

                        Button(action: {
                            showConfirmationAlert = true
                        }) {
                            Label("Limpiar Todo", systemImage: "trash")
                                .font(.caption)
                                .padding(8)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                        .alert("¿Borrar todos los registros?", isPresented: $showConfirmationAlert) {
                            Button("Cancelar", role: .cancel) {}
                            Button("Borrar", role: .destructive) {
                                viewModel.clearAllAttendanceRecords()
                            }
                        } message: {
                            Text("Esta acción eliminará todos los registros de asistencia permanentemente.")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredEmployees) { employee in
                        EmployeeAttendanceRow(
                            employee: employee,
                            onEdit: { employeeToEdit = employee }
                        )
                  /*  ForEach(viewModel.getFilteredEmployees(area: selectedArea, showAbsentOnly: mostrarSoloFaltas)) { employee in
                        EmployeeAttendanceRow(
                            employee: employee,
                            onEdit: { employeeToEdit = employee }
                        )*/
                        .padding(.vertical, 6)
                        .padding(.horizontal)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                    }
                }
                .padding(.top, 4)
            }
            .background(Color(.secondarySystemBackground))
        }
        .sheet(item: $employeeToEdit) { employee in
            AddEmployeeView(employee: employee, isEditing: true) { updatedEmployee in
                viewModel.updateEmployee(updatedEmployee)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showBulkActions.toggle() }) {
                        Label("Acciones masivas", systemImage: "checklist")
                    }

                    Button(action: {
                      if let url = viewModel.exportToCSV() {
                      let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                     
                      //  New way to get the current window scene
                      if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootViewController = windowScene.windows.first?.rootViewController {
                      rootViewController.present(av, animated: true)
                      }
                      }
                     }) {
                      Label("Exportar CSV", systemImage: "square.and.arrow.up")
                     }

                    Button(action: {
                      let filteredEmployees = viewModel.getFilteredEmployees(area: selectedArea, showAbsentOnly: mostrarSoloFaltas)
                      let nombres = filteredEmployees.map { "\($0.name) - #\($0.operatorNumber) - \($0.area)" }
                      let texto = nombres.joined(separator: "\n")
                      let av = UIActivityViewController(activityItems: [texto], applicationActivities: nil)
                     
                      // Updated code for iOS 15 and later
                      if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootViewController = windowScene.windows.first?.rootViewController {
                      rootViewController.present(av, animated: true)
                      }
                     }) {
                      Label("Compartir lista", systemImage: "square.and.arrow.up")
                     }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }

            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showHoursConfig.toggle() }) {
                    Label("Horas", systemImage: "clock")
                }
            }
        }
        .sheet(isPresented: $showHoursConfig) {
            HoursConfigView(dailyHours: $viewModel.dailyHours)
        }
    }
    
    struct HoursConfigView: View {
        @Binding var dailyHours: Double
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            VStack {
                Text("Horas por jornada")
                    .font(.headline)
                    .padding()
                
                TextField("Horas", value: $dailyHours, formatter: NumberFormatter())
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .frame(width: 150)
                
                Button("Guardar") {
                    dismiss()
                }
                .padding()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
        private var currentSortOptionText: String {
                switch viewModel.currentSortOption {
                case .byOperatorNumber: return "Número"
                case .byAreaThenOperatorNumber: return "Área y Número"
                case .byStatus: return "Estado"
                }
            }
            
            private var filteredEmployees: [Employee] {
                let baseList = viewModel.searchText.isEmpty ?
                    viewModel.employees :
                    viewModel.employees.filter {
                        $0.name.localizedCaseInsensitiveContains(viewModel.searchText) ||
                        $0.operatorNumber.contains(viewModel.searchText)
                    }
                
                let filtradosPorArea = selectedArea == "Todos" ?
                    baseList :
                    baseList.filter { $0.area == selectedArea }
                
                let filtered = if mostrarSoloFaltas {
                    filtradosPorArea.filter { employee in
                        viewModel.attendanceRecords.contains {
                            $0.employeeId == employee.id &&
                            Calendar.current.isDate($0.date, inSameDayAs: viewModel.selectedDate) &&
                            $0.status == .absent
                        }
                    }
                } else {
                    filtradosPorArea
                }
                
                // Aplicar el ordenamiento seleccionado
                return viewModel.sortEmployees(filtered, by: viewModel.currentSortOption)
            }
        
    private var areas: [String] {
        let allAreas = Array(Set(viewModel.employees.map { $0.area })).sorted()
        return ["Todos"] + allAreas
    }
    
  /*  private var filteredEmployees: [Employee] {
        let baseList = viewModel.searchText.isEmpty ?
            viewModel.employees :
        //    viewModel.filteredEmployees
        self.filteredEmployees
    
        
        let filtradosPorArea = selectedArea == "Todos" ? baseList : baseList.filter { $0.area == selectedArea }
        
        if mostrarSoloFaltas {
            return filtradosPorArea.filter { employee in
                viewModel.attendanceRecords.contains {
                    $0.employeeId == employee.id &&
                    Calendar.current.isDate($0.date, inSameDayAs: viewModel.selectedDate) &&
                    $0.status == .absent
                }
            }
        } else {
            return filtradosPorArea
        }
    }*/
}
  

struct EmployeeAttendanceRow: View {
    @EnvironmentObject var viewModel: AttendanceViewModel
    let employee: Employee
    var onEdit: () -> Void
    @State private var showingTerminationSheet = false
    @State private var terminationDate = Date()
    @State private var showingCopiedAlert = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        HStack {
            // Indicador de estado (ahora interactivo)
            Circle()
                .fill(statusColor)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                )
                .onTapGesture {
                    if employee.status == .active {
                        viewModel.toggleAttendance(for: employee.id)
                    }
                }

            // Información del empleado
            VStack(alignment: .leading, spacing: 2) {
                Text(employee.name)
                    .font(.subheadline)
                    .lineLimit(1)
                Text("#\(employee.operatorNumber) • \(employee.area)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Indicador visual de presencia (solo para empleados activos)
            if employee.status == .active {
                Image(systemName: viewModel.isEmployeePresent(employee.id) ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(viewModel.isEmployeePresent(employee.id) ? .green : .red)
            }

            // Menú contextual
            if employee.status == .active {
                Menu {
            
                    // Sección de Estado del Empleado
                    Menu {
                        Button(action: { changeStatus(to: .onVacation) }) {
                            Label("Vacaciones", systemImage: "beach.umbrella.fill")
                        }
                        Button(action: { changeStatus(to: .onLeave) }) {
                            Label("Permiso", systemImage: "calendar.badge.clock")
                        }
                        Button(action: { changeStatus(to: .suspended) }) {
                            Label("Suspender", systemImage: "person.slash.fill")
                        }
                        Button(action: { changeStatus(to: .inactive) }) {
                            Label("Dar de baja", systemImage: "person.fill.xmark")
                        }
                    } label: {
                        Label("Cambiar estado", systemImage: "person.crop.circle.badge")
                    }
                    Divider()

                    Button(action: onEdit) {
                        Label("Editar información", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: confirmDelete) {
                        Label("Eliminar empleado", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            } else {
                Menu {
                    Button(action: { changeStatus(to: .active) }) {
                        Label("Reactivar empleado", systemImage: "person.fill.checkmark")
                    }
                   /* Button(role: .destructive, action: confirmDelete) {
                        Label("Eliminar permanentemente", systemImage: "trash.fill")
                    }*/
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .contentShape(Rectangle())
        .onLongPressGesture {
            let info = "\(employee.name) - #\(employee.operatorNumber) - \(employee.area)"
            UIPasteboard.general.string = info
            showingCopiedAlert = true
        }
        .alert("Datos copiados", isPresented: $showingCopiedAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert("Confirmar eliminación", isPresented: $showingDeleteConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive) {
                viewModel.deleteEmployee(employee)
            }
        } message: {
            Text("¿Eliminar permanentemente a \(employee.name)? Todos sus registros serán borrados.")
        }
        .sheet(isPresented: $showingTerminationSheet) {
            terminationConfirmationSheet
        }
    }

    private func changeStatus(to status: EmployeeStatus) {
        var updatedEmployee = employee
        updatedEmployee.status = status
        if status == .onLeave || status == .suspended {
            viewModel.toggleAttendance(for: employee.id, temporaryStatus: status == .onLeave ? .onLeave : .suspended)
        } else if status == .inactive {
            showingTerminationSheet = true
            return
        }
        viewModel.updateEmployee(updatedEmployee)
    }

    private func confirmDelete() {
        showingDeleteConfirmation = true
    }

    private var statusColor: Color {
        switch employee.status {
        case .active:
            return viewModel.isEmployeePresent(employee.id) ? .green : .red
        case .inactive:
            return .gray
        case .onLeave:
            return .orange
        case .suspended:
            return .yellow
        case .onVacation:
            return .blue
        }
    }

    private var terminationConfirmationSheet: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker("Fecha de baja", selection: $terminationDate, displayedComponents: .date)
                }
                Section {
                    Button(role: .destructive) {
                        viewModel.terminateEmployee(employee, terminationDate: terminationDate)
                    } label: {
                        HStack {
                            Spacer()
                            Text("Confirmar Baja")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Confirmar Baja")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        showingTerminationSheet = false
                    }
                }
            }
        }
    }
}

    
struct AddEmployeeView: View {
    @State private var editableEmployee: Employee
    var isEditing: Bool
    var onSave: (Employee) -> Void
    @Environment(\.dismiss) var dismiss
    
    init(employee: Employee, isEditing: Bool, onSave: @escaping (Employee) -> Void) {
        self._editableEmployee = State(initialValue: employee)
        self.isEditing = isEditing
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Información del Empleado")) {
                    TextField("Número de Operador", text: $editableEmployee.operatorNumber)
                        .keyboardType(.numberPad)
                        .disabled(isEditing)
                    
                    TextField("Nombre Completo", text: $editableEmployee.name)
                    
                    TextField("Área/Departamento", text: $editableEmployee.area)
                    
                    TextField("Responsable/Supervisor", text: $editableEmployee.supervisor)
                    
                    if isEditing {
                        Picker("Estado", selection: $editableEmployee.status) {
                            ForEach(EmployeeStatus.allCases, id: \.self) { status in
                                Text(status.rawValue).tag(status)
                            }
                        }
                        
                        if editableEmployee.status == .inactive {
                            DatePicker("Fecha de baja",
                                selection: Binding(
                                    get: { editableEmployee.terminationDate ?? Date() },
                                    set: { editableEmployee.terminationDate = $0 }
                                ),
                                displayedComponents: .date
                            )
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Editar Empleado" : "Nuevo Empleado")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Guardar Cambios" : "Guardar") {
                        onSave(editableEmployee)
                        dismiss()
                    }
                    .disabled(editableEmployee.operatorNumber.isEmpty || editableEmployee.name.isEmpty)
                }
            }
        }
    }
}


    // Componentes auxiliares
    struct StatRow: View {
        let label: String
        let value: String
        let icon: String
        var color: Color = .primary
        
        var body: some View {
            HStack {
                Label(label, systemImage: icon)
                Spacer()
                Text(value)
                    .foregroundColor(color)
                    .fontWeight(.medium)
            }
        }
    }
    
struct AttendancePercentageView: View {
    @EnvironmentObject var viewModel: AttendanceViewModel
    let timeRange: AttendanceViewModel.TimeRange
    //let percentage: Double
    
    // Calcular el porcentaje cuando se necesita
    private var percentage: Double {
        viewModel.calculateAttendancePercentage(for: timeRange)
    }
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(lineWidth: 10)
                    .opacity(0.3)
                    .foregroundColor(.gray)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(percentage/100, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                    .foregroundColor(percentageColor)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear, value: percentage)
                
                Text(String(format: "%.1f%%", percentage))
                    .font(.title2)
                    .fontWeight(.bold)
                    }
            .frame(width: 100, height: 100)
            
            Text("Asistencia")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    private var percentageColor: Color {
        switch percentage {
        case ..<70: return .red
        case 70..<90: return .orange
        default: return .green
        }
    }
}
    
    struct SearchBar: View {
        @Binding var text: String
        
        var body: some View {
            HStack {
                TextField("Buscar empleado...", text: $text)
                    .padding(8)
                    .padding(.horizontal, 25)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 8)
                            
                            if !text.isEmpty {
                                Button(action: {
                                    text = ""
                                }) {
                                    Image(systemName: "multiply.circle.fill")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 8)
                                }
                            }
                        }
                    )
            }
            .padding(.horizontal, 10)
        }
    }
    
    struct AreaFilterView: View {
        @Binding var selectedArea: String
        let areas: [String]
        
        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(areas, id: \.self) { area in
                        Button(action: { selectedArea = area }) {
                            Text(area)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedArea == area ? Color.blue : Color(.systemGray5))
                                .foregroundColor(selectedArea == area ? .white : .primary)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    struct CompactDatePicker: View {
        @Binding var selectedDate: Date
        
        var body: some View {
            HStack {
                Button(action: { addDays(-1) }) {
                    Image(systemName: "chevron.left")
                        .padding(8)
                }
                
                Text(selectedDate.formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                
                Button(action: { addDays(1) }) {
                    Image(systemName: "chevron.right")
                        .padding(8)
                }
                
                Button(action: { selectedDate = Date() }) {
                    Text("Hoy")
                        .font(.caption)
                        .padding(8)
                }
            }
            .buttonStyle(.bordered)
            .padding(.horizontal)
        }
        
        private func addDays(_ days: Int) {
            if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
                selectedDate = newDate
            }
        }
    }
    
struct DocumentPicker: UIViewControllerRepresentable {
    var onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.commaSeparatedText], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onDocumentPicked(url)
        }
    }
}
