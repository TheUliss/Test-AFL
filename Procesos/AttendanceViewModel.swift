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


import SwiftUI

class AttendanceViewModel: ObservableObject {
    @Published var employees: [Employee] = []
    @Published var attendanceRecords: [AttendanceRecord] = []
    @Published var searchText: String = ""
    @Published var selectedDate: Date = Date()
    @Published var showImportSheet: Bool = false
    
    init() {
        loadEmployees()
    }
    
    
    // MARK: - Employee Management
 
   
       private var employeesFileURL: URL {
           let manager = FileManager.default
           let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
           return url.appendingPathComponent("employees.json")
       }

       func saveEmployees() {
           do {
               let data = try JSONEncoder().encode(employees)
               //try data.write(to: employeesFileURL, options: [.atomic, .completeFileProtection])
               let options: Data.WritingOptions = [.atomic, .completeFileProtection]
               try data.write(to: employeesFileURL, options: options)

               print("✅ Empleados guardados en archivo.")
           } catch {
               print("❌ Error al guardar empleados: \(error)")
           }
       }

       func loadEmployees() {
           do {
               let data = try Data(contentsOf: employeesFileURL)
               employees = try JSONDecoder().decode([Employee].self, from: data)
               print("✅ Empleados cargados desde archivo.")
           } catch {
               print("⚠️ No se encontraron datos previos o hubo error: \(error)")
           }
       }

       // También aquí dentro:
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
       }

       func terminateEmployee(_ employee: Employee, terminationDate: Date = Date()) {
           if let index = employees.firstIndex(where: { $0.id == employee.id }) {
               employees[index].status = .inactive
               employees[index].terminationDate = terminationDate
               let newRecord = AttendanceRecord(
                   employeeId: employee.id,
                   date: terminationDate,
                   status: .terminated,
                   absenceReason: "Baja definitiva"
               )
               attendanceRecords.append(newRecord)
               saveEmployees()
           }
       }
    
    
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
    
    var activeEmployees: [Employee] {
        employees.filter { $0.status == .active }
    }
    
    
    // MARK: - Attendance Management
    func toggleAttendance(for employeeId: UUID) {
        if let index = attendanceRecords.firstIndex(where: { $0.employeeId == employeeId && Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
            attendanceRecords[index].status = attendanceRecords[index].status == .present ? .absent : .present
        } else {
            let newRecord = AttendanceRecord(
                employeeId: employeeId,
                date: selectedDate,
                status: .absent
            )
            attendanceRecords.append(newRecord)
        }
    }
    
    func isPresent(employeeId: UUID) -> Bool {
        !attendanceRecords.contains(where: { $0.employeeId == employeeId &&
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate) &&
            $0.status == .absent })
    }
    
    // MARK: - Import/Export
    func importEmployees(from csvData: Data) {
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
    
    // MARK: - Statistics
    func getAttendanceStats() -> AttendanceStats {
        let todayRecords = attendanceRecords.filter {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
        
        let activeCount = activeEmployees.count
        let presentCount = todayRecords.filter { $0.status == .present }.count
        let absentCount = todayRecords.filter { $0.status == .absent }.count
        let terminatedCount = employees.filter { $0.status == .inactive }.count
        
        // Operadores por área
        let operatorsByArea = Dictionary(grouping: activeEmployees, by: { $0.area })
            .mapValues { $0.count }
            .sorted { $0.key < $1.key }
        
        // Asistencia por área
        let attendanceByArea: [(area: String, present: Int, total: Int)] = {
            let grouped = Dictionary(grouping: activeEmployees, by: { $0.area })
            return grouped.map { area, employeesInArea in
                let present = employeesInArea.filter { employee in
                    !todayRecords.contains { $0.employeeId == employee.id && $0.status == .absent }
                }.count
                return (area: area, present: present, total: employeesInArea.count)
            }.sorted { $0.area < $1.area }
        }()
        
        let attendancePercentage = activeCount > 0 ? Double(presentCount) / Double(activeCount) * 100 : 0
        let totalHoursWorked = Double(presentCount) * 10.5
        
        // Empleados con múltiples faltas (últimos 30 días)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let recentAbsences = attendanceRecords.filter {
            $0.date >= thirtyDaysAgo && $0.status == .absent
        }
        let absenceCounts = Dictionary(recentAbsences.map { ($0.employeeId, 1) }, uniquingKeysWith: +)
        let frequentAbsentees = absenceCounts.filter { $0.value > 3 }.compactMap { employeeId, _ in
            employees.first { $0.id == employeeId }
        }
        
        return AttendanceStats(
            present: presentCount,
            absent: absentCount,
            terminated: terminatedCount,
            totalEmployees: employees.count,
            activeEmployees: activeCount,
            operatorsByArea: operatorsByArea,
            attendancePercentage: attendancePercentage,
            totalHoursWorked: totalHoursWorked,
            frequentAbsentees: frequentAbsentees,
            attendanceByArea: attendanceByArea
        )
    }
}
    
    struct AttendanceView: View {
        @EnvironmentObject var viewModel: AttendanceViewModel
        @State private var showingAddEmployee = false
        @State private var showingImportSheet = false
        @State private var newEmployee = Employee(operatorNumber: "", name: "", area: "", supervisor: "")
        
        var body: some View {
            NavigationStack {
                AttendanceListView()
                    .navigationTitle("Control de Asistencia")
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            /* Button(action: { showingStats = true }) {
                             Label("Estadísticas", systemImage: "chart.bar")
                             }*/
                            Button(action: { showingImportSheet = true }) {
                                Label("Importar", systemImage: "square.and.arrow.down")
                            }
                            
                            Button(action: { showingAddEmployee = true }) {
                                Label("Agregar", systemImage: "person.badge.plus")
                            }
                        }
                    }
                    .sheet(isPresented: $showingAddEmployee) {
                        AddEmployeeView(employee: $newEmployee, isEditing: false) {
                            viewModel.addEmployee(newEmployee)
                            newEmployee = Employee(operatorNumber: "", name: "", area: "", supervisor: "")
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
    
    
    struct AttendanceListView: View {
        @EnvironmentObject var viewModel: AttendanceViewModel
        @State private var selectedArea: String = "Todos"
        @State private var employeeToEdit: Employee?
        
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
                    
                    AreaFilterView(selectedArea: $selectedArea, areas: areas)
                        .padding(.bottom, 8)
                        .background(Color(.systemBackground))
                }
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredEmployees) { employee in
                            EmployeeAttendanceRow(
                                employee: employee,
                                isPresent: viewModel.isPresent(employeeId: employee.id),
                                onToggle: { viewModel.toggleAttendance(for: employee.id) },
                                onEdit: { employeeToEdit = employee }
                            )
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
                AddEmployeeView(
                    employee: .constant(employee),
                    isEditing: true,
                    onSave: {
                        viewModel.updateEmployee(employee)
                    }
                )
            }
        }
        
        private var areas: [String] {
            let allAreas = Array(Set(viewModel.employees.map { $0.area })).sorted()
            return ["Todos"] + allAreas
        }
        
        private var filteredEmployees: [Employee] {
            let baseList = viewModel.searchText.isEmpty ?
            viewModel.employees :
            viewModel.filteredEmployees
            
            if selectedArea == "Todos" {
                return baseList
            } else {
                return baseList.filter { $0.area == selectedArea }
            }
        }
    }
    
import SwiftUI

struct EmployeeAttendanceRow: View {
    @EnvironmentObject var viewModel: AttendanceViewModel
    let employee: Employee
    var isPresent: Bool
    var onToggle: () -> Void
    var onEdit: () -> Void
    
    @State private var showingTerminationSheet = false
    @State private var terminationDate = Date()
    
    var body: some View {
        HStack {
            // Indicador de estado
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
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
            
            // Menú contextual con gesto largo
            if employee.status == .active {
                Menu {
                    Button(action: onEdit) {
                        Label("Editar", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { showingTerminationSheet = true }) {
                        Label("Dar de baja", systemImage: "person.fill.xmark")
                    }
                    
                    Button(role: .destructive, action: { viewModel.deleteEmployee(employee) }) {
                        Label("Eliminar", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .contextMenu {
                    Button(action: onEdit) {
                        Label("Editar", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { showingTerminationSheet = true }) {
                        Label("Dar de baja", systemImage: "person.fill.xmark")
                    }
                    
                    if employee.status == .active || employee.status == .inactive {
                        Menu {
                            if employee.status == .active {
                                Button(action: onEdit) {
                                    Label("Editar", systemImage: "pencil")
                                }

                                Button(role: .destructive, action: { showingTerminationSheet = true }) {
                                    Label("Dar de baja", systemImage: "person.fill.xmark")
                                }
                            }

                            Button(role: .destructive, action: { viewModel.deleteEmployee(employee) }) {
                                Label("Eliminar", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }

                }
            }
        }
        .sheet(isPresented: $showingTerminationSheet) {
            terminationConfirmationSheet
        }
        .onTapGesture {
            onToggle() // marcar como falta/presente
        }
        .onLongPressGesture {
            onEdit()
        }
    }
    
    private var statusColor: Color {
        switch employee.status {
        case .active: return isPresent ? .green : .red
        case .inactive: return .gray
        case .onLeave: return .orange
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
    @Binding var employee: Employee
    var isEditing: Bool
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Información del Empleado")) {
                    TextField("Número de Operador", text: $employee.operatorNumber)
                        .keyboardType(.numberPad)
                        .disabled(isEditing)
                    
                    TextField("Nombre Completo", text: $employee.name)
                    
                    TextField("Área/Departamento", text: $employee.area)
                    
                    TextField("Responsable/Supervisor", text: $employee.supervisor)
                    
                    if isEditing {
                        Picker("Estado", selection: $employee.status) {
                            ForEach(EmployeeStatus.allCases, id: \.self) { status in
                                Text(status.rawValue).tag(status)
                            }
                        }
                        
                        if employee.status == .inactive {
                            DatePicker("Fecha de baja", selection: Binding(
                                get: { employee.terminationDate ?? Date() },
                                set: { employee.terminationDate = $0 }
                            ), displayedComponents: .date)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Editar Empleado" : "Nuevo Empleado")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Guardar Cambios" : "Guardar") {
                        onSave()
                        dismiss()
                    }
                    .disabled(employee.operatorNumber.isEmpty || employee.name.isEmpty)
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
        let percentage: Double
        
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
    
    // MARK: - Persistencia local (guardar/cargar empleados)
    private var employeesFileURL: URL {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return url.appendingPathComponent("employees.json")
    }
    
  
