import SwiftUI

struct AttendanceStatsView: View {
    @EnvironmentObject var viewModel: AttendanceViewModel
    @State private var selectedTimeRange: AttendanceViewModel.TimeRange = .today
    @State private var showingShareSheet = false
    @State private var pdfURL: URL?
    @Environment(\.dismiss) var dismiss // For going back
    
    var terminatedEmployees: [Employee] {
        viewModel.employees.filter { $0.status == .inactive }
    }
    
    var stats: AttendanceStats {
        let stats = viewModel.getAttendanceStats(for: selectedTimeRange)
        // Sobrescribir el porcentaje con el cálculo correcto
        return AttendanceStats(
            present: stats.present,
            absent: stats.absent,
            terminated: stats.terminated,
            onVacation: stats.onVacation,
            suspended: stats.suspended,
            onleave: stats.onleave,
            totalEmployees: stats.totalEmployees,
            activeEmployees: stats.activeEmployees,
            operatorsByArea: stats.operatorsByArea,
            attendancePercentage: viewModel.calculateAttendancePercentage(for: selectedTimeRange), // Usar la nueva función
            totalHoursWorked: stats.totalHoursWorked,
            frequentAbsentees: stats.frequentAbsentees,
            attendanceByArea: stats.attendanceByArea
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Rango de tiempo", selection: $selectedTimeRange) {
                        Text("Hoy").tag(AttendanceViewModel.TimeRange.today)
                        Text("Esta semana").tag(AttendanceViewModel.TimeRange.week)
                        Text("Este mes").tag(AttendanceViewModel.TimeRange.month)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Resumen general
                    summarySection
                    
                    // Asistencia por áreas
                    attendanceByAreaSection
                    
                    specialStatusSection
                    
                    // Empleados con múltiples faltas
                    frequentAbsenteesSection
                    
                    
                }
                .padding(.vertical)
            }
            .navigationTitle("Resumen de Asistencia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                // Botón para volver a la vista principal (si es necesario)
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        AttendanceView()
                            .environmentObject(viewModel)
                    } label: {
                        Label("Volver", systemImage: "arrow.left")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: generateShortReport) {
                            Label("Compartir resumen", systemImage: "text.bubble")
                        }
                        Button(action: generateDetailedPDF) {
                            Label("Generar PDF completo", systemImage: "doc.text")
                        }
                    } label: {
                        Label("Compartir", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let pdfURL = pdfURL {
                    ShareSheet(activityItems: [pdfURL])
                }
            }
        }
    }
    
    // Nuevas funciones:
    private func generateShortReport() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let reportText = """
        📊 Resumen de Asistencia - \(dateFormatter.string(from: Date()))
        
        👥 Total: \(stats.totalEmployees)
        ✅ Presentes: \(stats.present)
        ❌ Ausentes: \(stats.absent)
        🏖 Vacaciones: \(stats.onVacation)
        ⏸ Suspendidos: \(stats.suspended)
        📅 Permisos: \(stats.onleave)
        
        📈 Asistencia: \(String(format: "%.1f%%", stats.attendancePercentage))
        ⏱ Horas trabajadas: \(String(format: "%.1f h", stats.totalHoursWorked))
        """
        let av = UIActivityViewController(activityItems: [reportText], applicationActivities: nil)
         if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let rootViewController = windowScene.windows.first?.rootViewController {
          rootViewController.present(av, animated: true)
         }
    }
    
    private func generateDetailedPDF() {
        // Implementación similar a la actual pero con más detalles
        let reportText = generateCompleteReportText()
        let pdfGenerator = PDFGenerator2()
        pdfURL = pdfGenerator.generateAttendancePDF(content: reportText)
        showingShareSheet = true
    }
    
    private var summarySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Resumen General")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 15) {
                StatCard(
                    title: "Presentes",
                    value: "\(stats.present)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Ausentes",
                    value: "\(stats.absent)",
                    icon: "xmark.circle.fill",
                    color: .red
                )
                
                StatCard(
                    title: "Asistencia",
                    value: String(format: "%.1f%%", stats.attendancePercentage),
                    icon: "chart.pie.fill",
                    color: .blue
                )
            }
            
            HStack(spacing: 15) {
                StatCard(
                    title: "Vacaciones",
                    value: "\(stats.onVacation)",
                    icon: "beach.umbrella.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Suspendidos",
                    value: "\(stats.suspended)",
                    icon: "person.fill.xmark",
                    color: .orange
                )
                
                StatCard(
                    title: "Permisos",
                    value: "\(stats.onleave)",
                    icon: "calendar.badge.clock",
                    color: .purple
                )
            }
            
            HStack(spacing: 15) {
                StatCard(
                    title: "Total",
                    value: "\(stats.totalEmployees)",
                    icon: "person.3.fill",
                    color: .gray
                )
                
                StatCard(
                    title: "Horas Trab.",
                    value: String(format: "%.1f h", stats.totalHoursWorked),
                    icon: "clock.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    private var attendanceByAreaSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Asistencia por Áreas")
                    .font(.headline)
                Spacer()
            }
            
            ForEach(stats.attendanceByArea, id: \.area) { area in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(area.area)
                            .font(.subheadline)
                        Spacer()
                        Text("\(area.present)/\(area.total)")
                            .font(.subheadline)
                            .bold()
                    }
                    
                    ProgressView(value: Double(area.present), total: Double(area.total))
                        .progressViewStyle(LinearProgressViewStyle(tint: area.present == area.total ? .green : .orange))
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    private var frequentAbsenteesSection: some View {
        Group {
            if !stats.frequentAbsentees.isEmpty {
                VStack(spacing: 12) {
                    HStack {
                        Text("Empleados con 3+ faltas (30 días)")
                            .font(.headline)
                        Spacer()
                    }
                    
                    ForEach(stats.frequentAbsentees) { employee in
                        let absences = viewModel.attendanceRecords
                            .filter { $0.employeeId == employee.id && $0.status == .absent }
                            .sorted { $0.date > $1.date }
                        
                        DisclosureGroup {
                            ForEach(absences.prefix(5)) { record in
                                HStack {
                                    Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                    Spacer()
                                    if let reason = record.absenceReason {
                                        Text(reason)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .font(.caption)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(employee.name)
                                        .font(.subheadline)
                                    Text("#\(employee.operatorNumber) - \(employee.area)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("\(absences.count) faltas")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding(.horizontal)
            }
        }
    }
    
    private var specialStatusSection: some View {
        VStack(spacing: 12) {
            // 1. Refactor into a reusable function for each status type
            specialStatusDisclosureGroup(
                status: .onVacation,
                employees: viewModel.employees.filter { $0.status == .onVacation },
                statsCount: stats.onVacation,
                title: "Empleados de Vacaciones",
                icon: "beach.umbrella.fill",
                color: .blue,
                showTerminationDate: false
            )
            
            specialStatusDisclosureGroup(
                status: .onLeave,
                employees: viewModel.employees.filter { $0.status == .onLeave },
                statsCount: stats.onleave,
                title: "Empleados con Permisos",
                icon: "calendar.badge.checkmark",
                color: .orange,
                showTerminationDate: false
            )
            
            specialStatusDisclosureGroup(
                status: .suspended,
                employees: viewModel.employees.filter { $0.status == .suspended },
                statsCount: stats.suspended,
                title: "Empleados Suspendidos",
                icon: "person.fill.xmark",
                color: .yellow,
                showTerminationDate: false
            )
            
            specialStatusDisclosureGroup(
                status: .inactive,
                employees: viewModel.employees.filter { $0.status == .inactive },
                statsCount: stats.terminated,
                title: "Empleados dados de Baja",
                icon: "person.fill.xmark",
                color: .red,
                showTerminationDate: true
            )
            
            // Repeat for other statuses (onLeave, etc.) if needed
            
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func specialStatusDisclosureGroup(
        status: EmployeeStatus,
        employees: [Employee],
        statsCount: Int,
        title: String,
        icon: String,
        color: Color,
        showTerminationDate: Bool // NEW: Control the date display
    ) -> some View {
        if !employees.isEmpty {
            DisclosureGroup("\(title) (\(statsCount))") {
                if employees.isEmpty {
                    Text("No hay \(title.lowercased())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(employees.prefix(3)) { employee in
                        EmployeeStatusRow(employee: employee, status: title, icon: icon, color: color)
                        if showTerminationDate, let date = employee.terminationDate { // Conditional date display
                            Text("Baja: \(date.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
    }
    
    
    struct EmployeeStatusRow: View {
        let employee: Employee
        let status: String
        let icon: String
        let color: Color
        
        var body: some View {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                VStack(alignment: .leading) {
                    Text(employee.name)
                        .font(.subheadline)
                    Text("#\(employee.operatorNumber) - \(employee.area)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(status)
                    .font(.caption)
                    .foregroundColor(color)
            }
            .padding(.vertical, 4)
        }
    }
    
    
    private func generateCompleteReportText() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        
        // Obtener empleados presentes y ausentes hoy
        let today = viewModel.selectedDate
        let todayRecords = viewModel.attendanceRecords.filter {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }
        
        let presentToday = todayRecords.filter { $0.status == .present }
        let absentToday = todayRecords.filter { $0.status == .absent }
        
        // Preparar reporte detallado
        var reportText = """
        📊 REPORTE DETALLADO DE ASISTENCIA
        📅 \(dateFormatter.string(from: Date()))
        =====================================
        
        🔍 RESUMEN GENERAL
        • Total empleados: \(stats.totalEmployees)
        • Empleados activos: \(stats.activeEmployees)
        • Presentes hoy: \(stats.present)
        • Ausentes hoy: \(stats.absent)
        • En vacaciones: \(stats.onVacation)
        • Con permisos: \(stats.onleave)
        • Suspendidos: \(stats.suspended)
        • Bajas recientes: \(stats.terminated)
        • % Asistencia: \(String(format: "%.1f%%", stats.attendancePercentage))
        • Horas trabajadas: \(String(format: "%.1f h", stats.totalHoursWorked))
        
        📋 DETALLE POR ÁREAS
        """
        
        // Detalle por áreas con nombres de empleados
        for area in stats.attendanceByArea {
            let areaEmployees = viewModel.employees.filter { $0.area == area.area && $0.status == .active }
            let presentEmployees = areaEmployees.filter { emp in
                todayRecords.contains { $0.employeeId == emp.id && $0.status == .present }
            }
            
            reportText += """
            
            🔹 \(area.area.uppercased()) (\(area.present)/\(area.total) - \(String(format: "%.1f%%", Double(area.present)/Double(area.total)*100))
            ✅ Presentes:
            \(presentEmployees.isEmpty ? "   - Ninguno" : presentEmployees.map { "   - \($0.name) (#\($0.operatorNumber))" }.joined(separator: "\n"))
            
            ❌ Ausentes:
            \(areaEmployees.filter { emp in !presentEmployees.contains(where: { $0.id == emp.id }) }
              .isEmpty ? "   - Ninguno" :
              areaEmployees.filter { emp in !presentEmployees.contains(where: { $0.id == emp.id }) }
              .map { "   - \($0.name) (#\($0.operatorNumber))" }.joined(separator: "\n"))
            """
        }
        
        // Empleados con faltas recurrentes
        reportText += """
        
        ⚠️ EMPLEADOS CON 3+ FALTAS (ÚLTIMOS 30 DÍAS)
        """
        
        if stats.frequentAbsentees.isEmpty {
            reportText += "\n   - No hay empleados con faltas recurrentes"
        } else {
            for employee in stats.frequentAbsentees {
                let absences = viewModel.attendanceRecords
                    .filter { $0.employeeId == employee.id && $0.status == .absent }
                    .sorted { $0.date > $1.date }
                
                reportText += """
                
                • \(employee.name) (#\(employee.operatorNumber)) - \(employee.area) //
                Total faltas: \(absences.count)
                Últimas faltas:
                \(absences.prefix(5).map {
                    "    - \($0.date.formatted(date: .abbreviated, time: .omitted))" +
                ($0.absenceReason != nil ? " (Motivo: \($0.absenceReason!))" : "")
                }.joined(separator: "\n"))
                """
            }
        }
        
        // Personal en vacaciones
        let onVacation = viewModel.employees.filter { $0.status == .onVacation }
        reportText += """
        
        🏖 EMPLEADOS EN VACACIONES
        \(onVacation.isEmpty ? "   - Ninguno" : onVacation.map {
            "   - \($0.name) (#\($0.operatorNumber)) - \($0.area)"
        }.joined(separator: "\n"))
        """
        
        // Personal suspendido
        let suspended = viewModel.employees.filter { $0.status == .suspended }
        reportText += """
        
        ⏸ EMPLEADOS SUSPENDIDOS
        \(suspended.isEmpty ? "   - Ninguno" : suspended.map {
            "   - \($0.name) (#\($0.operatorNumber)) - \($0.area)"
        }.joined(separator: "\n"))
        """
        
        // Personal con permisos
        let onLeave = viewModel.employees.filter { $0.status == .onLeave }
        reportText += """
        
        📅 EMPLEADOS CON PERMISOS
        \(onLeave.isEmpty ? "   - Ninguno" : onLeave.map {
            "   - \($0.name) (#\($0.operatorNumber)) - \($0.area)"
        }.joined(separator: "\n"))
        """
        
        // Bajas recientes
        reportText += """
        
        🚪 EMPLEADOS DADOS DE BAJA
        \(terminatedEmployees.isEmpty ? "   - Ninguno" : terminatedEmployees.map {
            "   - \($0.name) (#\($0.operatorNumber)) - \($0.area)" +
            ($0.terminationDate != nil ? " (Baja: \($0.terminationDate!.formatted(date: .abbreviated, time: .omitted)))" : "")
        }.joined(separator: "\n"))
        """
        
        // Registro de asistencia del día
        reportText += """
        
        📅 REGISTRO DE ASISTENCIA - \(dateFormatter.string(from: today))
        ✅ Presentes (\(presentToday.count)):
        \(presentToday.isEmpty ? "   - Ninguno" : presentToday.compactMap { record in
            viewModel.employees.first { $0.id == record.employeeId }?.name
        }.map { "   - \($0)" }.joined(separator: "\n"))
        
        ❌ Ausentes (\(absentToday.count)):
        \(absentToday.isEmpty ? "   - Ninguno" : absentToday.compactMap { record in
            if let employee = viewModel.employees.first(where: { $0.id == record.employeeId }) {
                return "   - \(employee.name) (#\(employee.operatorNumber))" +
                       (record.absenceReason != nil ? " (Motivo: \(record.absenceReason!))" : "")
            }
            return nil
        }.joined(separator: "\n")))
        """
        
        return reportText
    }
}
    
    struct TerminatedEmployeesListView: View {
        @EnvironmentObject var viewModel: AttendanceViewModel
        
        var body: some View {
            List {
                ForEach(viewModel.employees.filter { $0.status == .inactive }) { employee in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(employee.name)
                                .font(.headline)
                            Text("#\(employee.operatorNumber) - \(employee.area)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let date = employee.terminationDate {
                                Text("Fecha de baja: \(date.formatted(date: .complete, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Empleados dados de baja")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}


struct ProgressBar: View {
    var value: Double
    var total: Double
    var color: Color = .blue
    
    var percentage: Double {
        total > 0 ? value / total : 0
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: 6)
                    .opacity(0.3)
                    .foregroundColor(Color.gray)
                
                Rectangle()
                    .frame(width: min(CGFloat(percentage) * geometry.size.width, geometry.size.width), height: 6)
                    .foregroundColor(color)
                    .animation(.linear, value: percentage)
            }
            .cornerRadius(3)
        }
        .frame(height: 6)
    }
}



class PDFGenerator2 {
    func generateAttendancePDF(content: String) -> URL {
        let format = UIGraphicsPDFRendererFormat()
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let tempDir = FileManager.default.temporaryDirectory
        let pdfURL = tempDir.appendingPathComponent("ReporteAsistencia_\(Date().timeIntervalSince1970).pdf")
        
        do {
            try renderer.writePDF(to: pdfURL) { context in
                context.beginPage()
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .left
                paragraphStyle.lineBreakMode = .byWordWrapping
                
                let attributes = [
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),
                    NSAttributedString.Key.paragraphStyle: paragraphStyle
                ]
                
                let textRect = pageRect.insetBy(dx: 36, dy: 36)
                content.draw(in: textRect, withAttributes: attributes)
            }
            return pdfURL
        } catch {
            print("Error generando PDF: \(error)")
            return tempDir.appendingPathComponent("error.pdf")
        }
    }
}


