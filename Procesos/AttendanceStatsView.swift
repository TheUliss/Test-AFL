import SwiftUI

struct AttendanceStatsView: View {
    @EnvironmentObject var viewModel: AttendanceViewModel
    @State private var selectedTimeRange: TimeRange = .today
    @State private var showingShareSheet = false
    @State private var pdfURL: URL?
    
    enum TimeRange: String, CaseIterable {
        case today = "Hoy"
        case week = "Esta semana"
        case month = "Este mes"
    }
    
    var terminatedEmployees: [Employee] {
        viewModel.employees.filter { $0.status == .inactive }
    }
    
    var stats: AttendanceStats {
        viewModel.getAttendanceStats()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Selector de rango de tiempo
                    Picker("Rango de tiempo", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Resumen general
                    summarySection
                    
                    // Asistencia por áreas
                    attendanceByAreaSection
                    
                    // Empleados con múltiples faltas
                    frequentAbsenteesSection
                    
                    // Sección de bajas
                    terminatedEmployeesSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Estadísticas de Asistencia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: generateReport) {
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
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(employee.name)
                                    .font(.subheadline)
                                Text("#\(employee.operatorNumber) - \(employee.area)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                        }
                        .padding(.vertical, 8)
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
    
    
    private var terminatedEmployeesSection: some View {
            Group {
                if !terminatedEmployees.isEmpty {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Empleados dados de baja")
                                .font(.headline)
                            Spacer()
                            Text("Total: \(terminatedEmployees.count)")
                                .font(.subheadline)
                        }
                        
                        ForEach(terminatedEmployees.prefix(3)) { employee in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(employee.name)
                                        .font(.subheadline)
                                    Text("#\(employee.operatorNumber) - \(employee.area)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if let date = employee.terminationDate {
                                        Text("Baja: \(date.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        
                        if terminatedEmployees.count > 3 {
                            NavigationLink(destination: TerminatedEmployeesListView()) {
                                Text("Ver todos (\(terminatedEmployees.count))")
                                    .font(.caption)
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
    
    
    private func generateReport() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            
            let reportText = """
            Reporte de Asistencia - \(dateFormatter.string(from: Date()))
            =====================================
            
            RESUMEN GENERAL:
            • Total empleados: \(stats.totalEmployees)
            • Activos: \(stats.activeEmployees)
            • Presentes: \(stats.present)
            • Ausentes: \(stats.absent)
            • Bajas: \(stats.terminated)
            • Porcentaje de asistencia: \(String(format: "%.1f%%", stats.attendancePercentage))
            • Horas trabajadas: \(String(format: "%.1f h", stats.totalHoursWorked))
            
            OPERADORES POR ÁREA:
            \(stats.operatorsByArea.map { "• \($0.key): \($0.value)" }.joined(separator: "\n"))
            
            EMPLEADOS AUSENTES HOY:
            \(viewModel.attendanceRecords.filter {
                Calendar.current.isDate($0.date, inSameDayAs: viewModel.selectedDate) && $0.status == .absent
            }.compactMap { record in
                viewModel.employees.first { $0.id == record.employeeId }?.name
            }.joined(separator: "\n• "))
            
            EMPLEADOS DADOS DE BAJA:
            \(terminatedEmployees.map { "• \($0.name) (#\($0.operatorNumber)) - \($0.terminationDate?.formatted(date: .abbreviated, time: .omitted) ?? "Sin fecha")" }.joined(separator: "\n"))
            """
            
            let pdfGenerator = PDFGenerator2()
            pdfURL = pdfGenerator.generateAttendancePDF(content: reportText)
            showingShareSheet = true
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


