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
    
    
    func addEmployee(_ employee: Employee) {
           employees.append(employee)
           // Aquí podrías agregar persistencia si es necesario
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
    
   // extension AttendanceViewModel {
        func getAttendanceStats() -> AttendanceStats {
            let todayRecords = attendanceRecords.filter {
                Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
            }
            
            // Estadísticas básicas
            let absentCount = todayRecords.filter { !$0.isPresent }.count
            let presentCount = employees.count - absentCount
            
            // 1. Cantidad de operadores por área
            let operatorsByArea = Dictionary(grouping: employees, by: { $0.area })
                .mapValues { $0.count }
                .sorted { $0.key < $1.key }
            
            // 2. Porcentaje de asistencia total
            let attendancePercentage = employees.isEmpty ? 0 : Double(presentCount) / Double(employees.count) * 100
            
            // 3. Horas totales trabajadas (presentes * 10.5 horas)
            let totalHoursWorked = Double(presentCount) * 10.5
            
            // Empleados con múltiples faltas (más de 3 faltas en 30 días)
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            let recentAbsences = attendanceRecords.filter { $0.date >= thirtyDaysAgo && !$0.isPresent }
            let absenceCounts = Dictionary(recentAbsences.map { ($0.employeeId, 1) }, uniquingKeysWith: +)
            let frequentAbsentees = absenceCounts.filter { $0.value > 3 }.compactMap { employeeId, _ in
                employees.first { $0.id == employeeId }
            }
            
            return AttendanceStats(
                present: presentCount,
                absent: absentCount,
                totalEmployees: employees.count,
                operatorsByArea: operatorsByArea,
                attendancePercentage: attendancePercentage,
                totalHoursWorked: totalHoursWorked,
                frequentAbsentees: frequentAbsentees
            )
        }
    //}

    struct AttendanceStats {
        let present: Int
        let absent: Int
        let totalEmployees: Int
        let operatorsByArea: [(key: String, value: Int)]
        let attendancePercentage: Double
        let totalHoursWorked: Double
        let frequentAbsentees: [Employee]
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

    
}


struct AttendanceView: View {
    @EnvironmentObject var viewModel: AttendanceViewModel
    @State private var showingAddEmployee = false
    @State private var newEmployee = Employee(operatorNumber: "", name: "", area: "", supervisor: "")
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            AttendanceListView(viewModel: viewModel)
                .navigationTitle("Control de Asistencia")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        // Botón para estadísticas
                        Button(action: { showingStats = true }) {
                            Label("Estadísticas", systemImage: "chart.bar")
                        }
                        
                        Button(action: { showingAddEmployee = true }) {
                            Label("Agregar", systemImage: "person.badge.plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAddEmployee) {
                    AddEmployeeView(employee: $newEmployee) {
                        viewModel.addEmployee(newEmployee)
                        newEmployee = Employee(operatorNumber: "", name: "", area: "", supervisor: "")
                    }
                }
                .sheet(isPresented: $showingStats) {
                    AttendanceStatsView()
                        .environmentObject(viewModel)
                }
        }
        }
    
    func shareStatistics() {
        let stats = viewModel.getAttendanceStats()
        let dateString = viewModel.selectedDate.formatted(date: .complete, time: .omitted)
        
        var shareContent = """
        Reporte de Asistencia
        Fecha: \(dateString)
        --------------------------
        Total empleados: \(viewModel.employees.count)
        Presentes: \(stats.present)
        Ausentes: \(stats.absent)
        """
        
        // Agregar lista de ausentes si los hay
        let absentees = viewModel.attendanceRecords
            .filter { Calendar.current.isDate($0.date, inSameDayAs: viewModel.selectedDate) && !$0.isPresent }
            .compactMap { record in
                viewModel.employees.first { $0.id == record.employeeId }?.name
            }
        
        if !absentees.isEmpty {
            shareContent += "\n\nAusentes:\n- " + absentees.joined(separator: "\n- ")
        }
        
        // Agregar empleados con múltiples faltas si los hay
        if !stats.frequentAbsentees.isEmpty {
            shareContent += "\n\nEmpleados con 3+ faltas (últimos 30 días):\n- " +
            stats.frequentAbsentees.map { $0.name }.joined(separator: "\n- ")
        }
        
        let activityVC = UIActivityViewController(activityItems: [shareContent], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
    }
}


struct AttendanceListView: View {
    @ObservedObject var viewModel: AttendanceViewModel
    @State private var selectedArea: String = "Todos"
    @State private var employeeToEdit: Employee? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header fijo
            VStack(spacing: 0) {
                CompactDatePicker(selectedDate: $viewModel.selectedDate)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                
                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .background(Color(.systemBackground))
                
                // Filtro por área
                AreaFilterView(selectedArea: $selectedArea, areas: areas)
                    .padding(.bottom, 8)
                    .background(Color(.systemBackground))
            }
            
            // Lista optimizada
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
                .sheet(item: $employeeToEdit) { employee in
                    AddEmployeeView(
                        employee: .constant(employee),
                        onSave: {
                            if let index = viewModel.employees.firstIndex(where: { $0.id == employee.id }) {
                                viewModel.employees[index] = employee
                            }
                        },
                        isEditing: true
                    )
                }
                
                .background(Color(.secondarySystemBackground))
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


// Componente de fila para cada empleado
struct EmployeeAttendanceRow: View {
    let employee: Employee
    var isPresent: Bool
    var onToggle: () -> Void
    
    var body: some View {
        HStack {
            // Indicador visual rápido
            Circle()
                .fill(isPresent ? Color.green : Color.red)
                .frame(width: 12, height: 12)
            
            // Información compacta
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
            
            // Botón de acción rápida
            Button(action: onToggle) {
                Image(systemName: isPresent ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isPresent ? .green : .red)
                    .imageScale(.medium)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
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



struct AttendanceStatsView: View {
    @EnvironmentObject var viewModel: AttendanceViewModel
    
    var stats: AttendanceStats {
        viewModel.getAttendanceStats()
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Sección de resumen general
                Section(header: Text("Resumen General")) {
                    HStack {
                        AttendancePercentageView(percentage: stats.attendancePercentage)
                            .frame(maxWidth: .infinity)
                        
                        VStack(alignment: .leading) {
                            StatRow(label: "Total", value: "\(stats.totalEmployees)", icon: "person.3")
                            StatRow(label: "Presentes", value: "\(stats.present)", icon: "checkmark.circle", color: .green)
                            StatRow(label: "Ausentes", value: "\(stats.absent)", icon: "xmark.circle", color: .red)
                            StatRow(label: "Horas Trabajadas", value: String(format: "%.1f h", stats.totalHoursWorked), icon: "clock")
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                // Sección de operadores por área
                Section(header: Text("Operadores por Área")) {
                    ForEach(stats.operatorsByArea, id: \.key) { area, count in
                        HStack {
                            Text(area)
                            Spacer()
                            Text("\(count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Sección de empleados con múltiples faltas
                if !stats.frequentAbsentees.isEmpty {
                    Section(header: Text("Empleados con 3+ faltas (últimos 30 días)")) {
                        ForEach(stats.frequentAbsentees) { employee in
                            VStack(alignment: .leading) {
                                Text(employee.name)
                                    .font(.headline)
                                Text("#\(employee.operatorNumber) - \(employee.area)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Estadísticas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: shareStats) {
                        Label("Compartir", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }
    
    private func shareStats() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        
        var shareContent = """
        Reporte Estadístico de Asistencia
        Fecha: \(dateFormatter.string(from: viewModel.selectedDate))
        =====================================
        
        RESUMEN GENERAL:
        • Total empleados: \(stats.totalEmployees)
        • Presentes: \(stats.present)
        • Ausentes: \(stats.absent)
        • Porcentaje de asistencia: \(String(format: "%.1f", stats.attendancePercentage))%
        • Horas trabajadas: \(String(format: "%.1f", stats.totalHoursWorked)) h
        
        OPERADORES POR ÁREA:
        \(stats.operatorsByArea.map { "• \($0.key): \($0.value)" }.joined(separator: "\n"))
        
        EMPLEADOS AUSENTES HOY:
        \(getAbsenteesList())
        """
        
        if !stats.frequentAbsentees.isEmpty {
            shareContent += """
            
            EMPLEADOS CON 3+ FALTAS (ÚLTIMOS 30 DÍAS):
            \(stats.frequentAbsentees.map { "• \($0.name) (#\($0.operatorNumber))" }.joined(separator: "\n"))
            """
        }
        
        let activityVC = UIActivityViewController(activityItems: [shareContent], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
    }
    
    private func getAbsenteesList() -> String {
        let absentees = viewModel.attendanceRecords
            .filter { Calendar.current.isDate($0.date, inSameDayAs: viewModel.selectedDate) && !$0.isPresent }
            .compactMap { record in
                viewModel.employees.first { $0.id == record.employeeId }?.name
            }
        
        return absentees.isEmpty ? "Ninguno" : absentees.joined(separator: "\n• ")
    }
}

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

struct AttendanceGridView: View {
    @ObservedObject var viewModel: AttendanceViewModel
    @State private var selectedArea: String = "Todos"
    
    let columns = [GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 8)]
    
    var body: some View {
        VStack(spacing: 0) {
            CompactDatePicker(selectedDate: $viewModel.selectedDate)
                .padding(.vertical, 8)
            
            SearchBar(text: $viewModel.searchText)
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            AreaFilterView(selectedArea: $selectedArea, areas: areas)
                .padding(.bottom, 8)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(filteredEmployees) { employee in
                        EmployeeGridCell(
                            employee: employee,
                            isPresent: viewModel.isPresent(employeeId: employee.id),
                            onToggle: { viewModel.toggleAttendance(for: employee.id) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // ... mismas propiedades computadas que en AttendanceListView
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

struct EmployeeGridCell: View {
    let employee: Employee
    var isPresent: Bool
    var onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            // Avatar/Iniciales
            ZStack {
                Circle()
                    .fill(isPresent ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text(initials(for: employee.name))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isPresent ? .green : .red)
            }
            
            // Nombre corto
            Text(shortName(for: employee.name))
                .font(.caption)
                .lineLimit(1)
            
            // Número de operador
            Text("#\(employee.operatorNumber)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isPresent ? Color.green : Color.red, lineWidth: 1)
        )
        .onTapGesture(perform: onToggle)
    }
    
    private func initials(for name: String) -> String {
        let parts = name.components(separatedBy: " ")
        let initials = parts.prefix(2).compactMap { $0.first?.uppercased() }
        return initials.joined()
    }
    
    private func shortName(for name: String) -> String {
        let parts = name.components(separatedBy: " ")
        if parts.count > 1 {
            return "\(parts[0]) \(parts[1].prefix(1))."
        }
        return name
    }
}


struct AddEmployeeView: View {
    @Binding var employee: Employee
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var isEditing: Bool
    
    init(employee: Binding<Employee>, onSave: @escaping () -> Void, isEditing: Bool = false) {
        self._employee = employee
        self.onSave = onSave
        self.isEditing = isEditing
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Información del Empleado")) {
                    TextField("Número de Operador", text: $employee.operatorNumber)
                        .keyboardType(.numberPad)
                        .disabled(isEditing) // No permitir cambiar el número si está editando
                    TextField("Nombre Completo", text: $employee.name)
                    TextField("Área/Departamento", text: $employee.area)
                    TextField("Responsable/Supervisor", text: $employee.supervisor)
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
                    Button(isEditing ? "Guardar Cambios" : "Guardar", action: {
                        onSave()
                        dismiss()
                    })
                    .disabled(employee.operatorNumber.isEmpty || employee.name.isEmpty)
                }
            }
        }
    }
}



extension View {
    func shareSheet(_ activityItems: [Any]) {
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
    }
}


