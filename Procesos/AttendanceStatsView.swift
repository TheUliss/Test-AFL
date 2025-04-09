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
    
    var stats: AttendanceViewModel.AttendanceStats {
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
    
    private func generateReport() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let reportText = """
        Reporte de Asistencia - \(dateFormatter.string(from: Date()))
        =====================================
        
        Resumen General:
        - Presentes: \(stats.present)
        - Ausentes: \(stats.absent)
        - Total empleados: \(stats.totalEmployees)
        - Porcentaje de asistencia: \(String(format: "%.1f%%", stats.attendancePercentage))
        - Horas trabajadas: \(String(format: "%.1f h", stats.totalHoursWorked))
        
        Asistencia por Áreas:
        \(stats.attendanceByArea.map { "- \($0.area): \($0.present)/\($0.total) (\(String(format: "%.1f%%", Double($0.present)/Double($0.total)*100))" }.joined(separator: "\n"))
        
        Empleados con múltiples faltas:
        \(stats.frequentAbsentees.isEmpty ? "Ninguno" : stats.frequentAbsentees.map { "- \($0.name) (#\($0.operatorNumber))" }.joined(separator: "\n"))
        """
        
        // Generar PDF (implementación básica)
        let pdfGenerator = PDFGenerator()
        pdfURL = pdfGenerator.generateAttendancePDF(content: reportText)
        showingShareSheet = true
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

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

class PDFGenerator {
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