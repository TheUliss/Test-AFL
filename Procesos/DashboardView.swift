//
//  DashboardView.swift
//  Test AFL
//
//  Created by Uls on 25/03/25.
//
import SwiftUI
import Foundation

struct DashboardView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var attendanceVM: AttendanceViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    MetricasRapidasView()
                        .padding(.horizontal)
                    
                    // Modifica el ResumenAsistenciaView para incluir estadísticas
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                        Text("Today")
                            .font(.headline)
                                                
                        Spacer()
                                                
                        NavigationLink(destination: AttendanceStatsView()) {
                            Text("Stadistics ")
                            .font(.subheadline)
                        }
                                                
                        NavigationLink(destination: AttendanceView()) {
                            Text("Control")
                            .font(.subheadline)
                        }
                        }
                                            
                                            let stats = attendanceVM.getAttendanceStats()
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
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                    
                    GraficoSemanasView()
                        .padding(.horizontal)
                    
                    ResumenMaterialesView()
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.secondarySystemBackground))
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: AttendanceView()) {
                Image(systemName: "list.bullet.clipboard")
                    }
                }
            }
        }
    }
}



//MARK: CALSIFICACION DE ORDENES

import SwiftUI

struct MetricasRapidasView: View {
    @EnvironmentObject var dataManager: DataManager

    private let columnas = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Resumen de Órdenes")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(Color.blue)
            .cornerRadius(10)

            
            LazyVGrid(columns: columnas, spacing: 10) {
                MetricCard(
                    title: "En Proceso",
                    value: dataManager.ordenesEnProceso.count,
                    icon: "clock.fill",
                    color: .blue,
                    backgroundColor: Color.blue.opacity(0.2),
                    ordenes: dataManager.ordenesEnProceso // 📌 Pasa órdenes en proceso
                )

                MetricCard(
                    title: "Completadas",
                    value: dataManager.ordenesTerminadas.count,
                    icon: "checkmark.circle.fill",
                    color: .green,
                    backgroundColor: Color.green.opacity(0.2),
                    ordenes: dataManager.ordenesTerminadas // 📌 Pasa órdenes terminadas
                )

                MetricCard(
                    title: "Retrasadas",
                    value: dataManager.ordenesRetrasadas.count,
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    backgroundColor: Color.red.opacity(0.2),
                    ordenes: dataManager.ordenesRetrasadas // 📌 Pasa órdenes retrasadas
                )

                MetricCard(
                    title: "Stand-By",
                    value: dataManager.ordenesStandby.count,
                    icon: "pause.circle.fill",
                    color: .orange,
                    backgroundColor: Color.orange.opacity(0.2),
                    ordenes: dataManager.ordenesStandby // 📌 Pasa órdenes en stand-by
                )
            }
            .padding()
        }
        .frame(maxHeight: 350)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(radius: 3)
        .padding(.horizontal)
    }
}



struct MetricCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    let backgroundColor: Color
    let ordenes: [Orden] // 📌 Se agregan las órdenes asociadas

    var body: some View {
        NavigationLink(destination: ResumenOrdenesView(title: title, ordenes: ordenes)) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .padding(8)
                    .background(Circle().fill(color.opacity(0.2)))

                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)

                Text("\(value)")
                    .font(.title)
                    .bold()
                    .foregroundColor(.primary)
            }
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(backgroundColor)
            .cornerRadius(12)
            .shadow(radius: 1)
        }
        .buttonStyle(PlainButtonStyle()) // 📌 Evita que el NavigationLink tenga estilos de botón por defecto
    }
}


// Primero, añade esta extensión fuera de tu struct (puede ir en el mismo archivo o en uno de utilidades)
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

struct ResumenOrdenesView: View {
    let title: String
    let ordenes: [Orden]
    @EnvironmentObject var dataManager: DataManager // 📌 Acceder a la lista de artículos

    var body: some View {
        VStack {
            Text("Órdenes \(title)")
                .font(.headline)
                .padding()

            let ordenesOrdenadas = ordenes.sorted {
                ($0.fechaUltimaModificacion ?? Date.distantPast) > ($1.fechaUltimaModificacion ?? Date.distantPast)
            }

            if ordenesOrdenadas.isEmpty {
                Text("No hay órdenes en este estado")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List(ordenesOrdenadas.indices, id: \.self) { index in
                    let orden = ordenesOrdenadas[index]

                    VStack(alignment: .leading) {
                        Text("\(index + 1). Orden: \(orden.nombre)")
                            .font(.headline)
                            .foregroundColor(.blue)

                        // 📌 Buscar el artículo correspondiente
                        if let articulo = dataManager.articulos.first(where: { $0.ordenes.contains(where: { $0.id == orden.id }) }) {
                            Text("Artículo: \(articulo.nombre)")
                            Text("Descripción: \(articulo.descripcion)")
                        } else {
                            Text("Artículo: No disponible")
                            Text("Descripción: No disponible")
                        }

                        Text("Tiempo Límite: \(orden.tiempoLimiteHoras) horas")
                            .font(.subheadline)

                        if let fecha = orden.fechaUltimaModificacion {
                            Text("Última Modificación: \(fecha, formatter: DateFormatter.shortDate)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .navigationTitle("Órdenes \(title)")
        .background(Color(.secondarySystemBackground))
    }
}



//MARK: RESUMEN SEMANAL
import SwiftUI

struct GraficoSemanasView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var semanasActivas: [String] {
        dataManager.articulos
            .flatMap { articulo in
                articulo.ordenes.compactMap { orden in
                    guard let semana = orden.noWeek, orden.clasificacion != .terminada else { return nil }
                    return semana
                }
            }
            .removingDuplicates()
            .sorted(by: >)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Semanas Activas")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(semanasActivas.count) semanas")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.blue) // Cambiado a azul para coincidir
            
            if semanasActivas.isEmpty {
                Text("No hay semanas activas")
                    .padding()
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(semanasActivas.prefix(8), id: \.self) { semana in
                            ResumenSemanalCard(semana: semana)
                                .frame(width: 220)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
        .background(Color(.secondarySystemBackground)) // Fondo estandarizado
        .cornerRadius(10) // Radio de esquina igual
        .shadow(radius: 3) // Sombra igual
    }
}


struct ResumenSemanalCard: View {
    @EnvironmentObject var dataManager: DataManager
    let semana: String

    var ordenesEnSemana: [Orden] {
        dataManager.ordenes.filter { $0.noWeek == semana }
    }
    var ordenesTerminadas: Int {
        ordenesEnSemana.filter { $0.clasificacion == .terminada }.count
    }
    var ordenesActivas: Int {
        ordenesEnSemana.filter { $0.clasificacion != .terminada }.count
    }
    var porcentajeCompletado: Double {
        guard !ordenesEnSemana.isEmpty else { return 0 }
        return Double(ordenesTerminadas) / Double(ordenesEnSemana.count)
    }

    var body: some View {
        VStack(spacing: 10) {
           
            HStack(alignment: .center, spacing: 8) {
                Text("Semana \(semana)")
                    .font(.system(size: 14, weight: .semibold)) // Control manual del tamaño
                    .foregroundColor(.white)
                
                Spacer()
                
                if ordenesActivas > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                        Text("\(ordenesActivas) Proceso")
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                }
            }
            .frame(height: 20)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray)
            .cornerRadius(10, corners: [.topLeft, .topRight])
            
                VStack(spacing: 12) {
                    if ordenesEnSemana.isEmpty {
                        Text("Sin órdenes registradas")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Progreso de la semana")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ZStack(alignment: .leading) {
                                Capsule()
                                    .frame(height: 8)
                                    .foregroundColor(Color.gray.opacity(0.3))

                                Capsule()
                                    .frame(width: max(CGFloat(porcentajeCompletado) * 120, 8), height: 8)
                                    .foregroundColor(porcentajeCompletado > 0.7 ? Color.green : Color.orange)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        VStack(spacing: 10) {
                            MetricItem(title: "Progreso", value: Int(porcentajeCompletado * 100), icon: "chart.bar.fill", color: .blue, isPercentage: true)
                        }
                        HStack(spacing: 20) {
                            MetricItem(title: "Completadas", value: ordenesTerminadas, icon: "checkmark.circle.fill", color: .green)
                            MetricItem(title: "Total", value: ordenesEnSemana.count, icon: "list.number", color: .gray)
                        
                        }
                    }
                }
            .padding(15)
        }
        //.background(Color(.secondarySystemBackground))
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 2)
        .padding(.vertical, 10)
    }
}


struct MetricItem: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    var isPercentage: Bool = false

    var body: some View {
        VStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(isPercentage ? "\(value)%" : "\(value)")
                .font(.headline)
                .bold()
        }
        .frame(minWidth: 80)
    }
}


extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}


//MARK: MATERIALES.

struct ResumenMaterialesView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var materialesCriticos: [MaterialConsolidado] = []
    @State private var cantidadesDisponibles: [String: Int] = [:]
    @State private var pdfURL: URL?
    @State private var showingShareSheet = false
    @StateObject private var userInputManager = MaterialUserInputManager()
    
    
    struct MaterialConsolidado: Identifiable {
        let id = UUID()
        let nombre: String
        let cantidadRequerida: Int
        let ordenesAfectadas: Int
        var cantidadDisponible: Int
        var deficitTotal: Int {
                    max(0, cantidadRequerida - cantidadDisponible) // Siempre positivo o cero
                }
    }
    
    // Clase para manejar persistencia
        class MaterialUserInputManager: ObservableObject {
            @Published var cantidadesDisponibles: [String: Int] = [:]
            
            func saveToUserDefaults() {
                if let encoded = try? JSONEncoder().encode(cantidadesDisponibles) {
                    UserDefaults.standard.set(encoded, forKey: "savedCantidadesDisponibles")
                }
            }
            
            func loadFromUserDefaults() {
                if let saved = UserDefaults.standard.data(forKey: "savedCantidadesDisponibles"),
                   let decoded = try? JSONDecoder().decode([String: Int].self, from: saved) {
                    cantidadesDisponibles = decoded
                }
            }
        }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) { // Elimina espacio extra
            // Encabezado
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                Text("Materiales Críticos")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(materialesCriticos.count)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.blue)
            .cornerRadius(10)

            if materialesCriticos.isEmpty {
                Text("No hay materiales con déficit")
                    .padding()
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 0) {
                    // Encabezado de la tabla
                    HStack {
                        Text("Material").bold().font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                        Text("Déficit").bold().font(.caption).frame(width: 60, alignment: .center)
                        Text("Disponible").bold().font(.caption).frame(width: 70, alignment: .center)
                        Text("Requerido").bold().font(.caption).frame(width: 70, alignment: .center)
                        Text("Órdenes").bold().font(.caption).frame(width: 50, alignment: .center)
                    }
                    .padding(.vertical, 6)
                    //.background(Color(.secondarySystemBackground).opacity(0.9))
                    .background(Color.gray.opacity(0.8))
                    .cornerRadius(2)

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach($materialesCriticos) { $material in
                                HStack {
                                    Text(material.nombre)
                                        .frame(maxWidth: .infinity, alignment: .leading) // Ocupa todo el ancho disponible
                                        .lineLimit(1)
                                        .font(.system(size: 11))

                                    Text("\(material.deficitTotal)")
                                        .frame(width: 40, alignment: .center)
                                        .foregroundColor(.red)
                                        .bold()
                                        .font(.system(size: 11))

                                    TextField("", value: Binding<Int>(
                                        get: {
                                            userInputManager.cantidadesDisponibles[material.nombre] ?? material.cantidadRequerida
                                        },
                                        set: { newValue in
                                            let validatedValue = max(0, newValue)
                                            userInputManager.cantidadesDisponibles[material.nombre] = validatedValue
                                            actualizarCantidadDisponible(nombre: material.nombre, cantidad: validatedValue)
                                        
                                        }
                                    ), formatter: {
                                        let formatter = NumberFormatter()
                                        formatter.zeroSymbol = "" // Permite borrar el valor
                                        return formatter
                                    }())
                                    .keyboardType(.numberPad)
                                    .frame(width: 70)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.system(size: 11))
                                    .background(material.deficitTotal > 0 ? Color.red.opacity(0.1) : Color.green.opacity(0.1))

                                    Text("\(material.cantidadRequerida)")
                                        .frame(width: 60, alignment: .center)
                                        .foregroundColor(.orange)
                                        .font(.system(size: 11))

                                    Text("\(material.ordenesAfectadas)")
                                        .frame(width: 50, alignment: .center)
                                        .font(.system(size: 11))
     
                                }
                                .padding(.vertical, 5)
                                .background(material.deficitTotal < 0 ? Color.red.opacity(0.1) : Color.clear)

                                Divider()
                            }
                        }
                    }
                    .frame(maxHeight: 350)
                    .onTapGesture {
                        hideKeyboard()
                    }

                    Button(action: {
                        guardarCambios()
                        generarPDF()
                    }) {
                        Text("Guardar y Generar PDF")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                .padding(.horizontal, 5) // Reduce el padding de la tarjeta externa
            }
        }
        //.background(Color(.secondarySystemBackground))
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .shadow(radius: 3)
        .padding(.horizontal, 5) // Reduce el padding externo
        .onAppear {
            inicializarMateriales()
        }
        // Agregar este modificador a la vista principal
        .onChange(of: pdfURL) { newURL in
            if newURL != nil {
                showingShareSheet = true
        
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfURL = pdfURL {
                ShareSheet(activityItems: [pdfURL])
            }
        }

    }

    private func hideKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }


    private func generarPDF() {
        guardarCambios()
        
        let materialesParaPDF = materialesCriticos.map { material in
            let disponible = userInputManager.cantidadesDisponibles[material.nombre] ?? material.cantidadDisponible
            return Material(
                id: UUID(),
                nombre: material.nombre,
                cantidadDisponible: disponible,
                cantidadRequerida: material.cantidadRequerida,
                cantidadAPedir: max(0, material.cantidadRequerida - disponible)
            )
        }
        
        guard !materialesParaPDF.isEmpty,
              !dataManager.empresa.isEmpty,
              !dataManager.usuario.isEmpty else {
            print("🚨 Error: Datos incompletos para generar PDF")
            return
        }
        
        if let pdfURL = PDFGenerator.createPDF(
            empresa: dataManager.empresa,
            usuario: dataManager.usuario,
            logo: dataManager.logoData != nil ? UIImage(data: dataManager.logoData!) : nil,
            materiales: materialesParaPDF
        ) {
            self.pdfURL = pdfURL
            self.showingShareSheet = true  // 📌 Ahora se activa la vista de compartir
            print("✅ PDF generado en: \(pdfURL.absoluteString)")
        } else {
            print("🚨 Error al generar PDF")
        }
    }



    private func inicializarMateriales() {
        var materialesMap: [String: (requerida: Int, ordenes: Int)] = [:]
        
        // Calcular total requerido por material - VERSIÓN CORREGIDA
        for articulo in dataManager.articulos {
            for material in articulo.materiales {
                let totalRequerido = articulo.ordenes
                    .filter { $0.clasificacion != .terminada }
                    .reduce(0) { total, orden in  // Usamos los dos parámetros explícitamente
                        total + material.cantidadRequerida
                    }
                
                if totalRequerido > 0 {
                    if let existente = materialesMap[material.nombre] {
                        materialesMap[material.nombre] = (
                            requerida: existente.requerida + totalRequerido,
                            ordenes: existente.ordenes + articulo.ordenes.filter { $0.clasificacion != .terminada }.count
                        )
                    } else {
                        materialesMap[material.nombre] = (
                            requerida: totalRequerido,
                            ordenes: articulo.ordenes.filter { $0.clasificacion != .terminada }.count
                        )
                    }
                }
            }
        }
        
        // Cargar valores guardados
        userInputManager.loadFromUserDefaults()
        
        // Crear materiales críticos
        materialesCriticos = materialesMap.map { nombre, valores in
            let disponible = userInputManager.cantidadesDisponibles[nombre] ?? valores.requerida // Valor por defecto = requerido
            return MaterialConsolidado(
                nombre: nombre,
                cantidadRequerida: valores.requerida,
                ordenesAfectadas: valores.ordenes,
                cantidadDisponible: disponible
            )
        }
    }

    private func actualizarCantidadDisponible(nombre: String, cantidad: Int) {
        // Validar que la cantidad no sea negativa
        let cantidadValidada = max(0, cantidad)
        
        // Actualizar en el manager de persistencia
        userInputManager.cantidadesDisponibles[nombre] = cantidadValidada
        
        // Actualizar en la lista local
        if let index = materialesCriticos.firstIndex(where: { $0.nombre == nombre }) {
            materialesCriticos[index].cantidadDisponible = cantidadValidada
        }
        
        // Actualizar en el DataManager
        for articuloIndex in dataManager.articulos.indices {
            for materialIndex in dataManager.articulos[articuloIndex].materiales.indices {
                if dataManager.articulos[articuloIndex].materiales[materialIndex].nombre == nombre {
                    dataManager.articulos[articuloIndex].materiales[materialIndex].cantidadDisponible = cantidadValidada
                }
            }
        }
    }

    private func guardarCambios() {
        // Persistir en UserDefaults
        userInputManager.saveToUserDefaults()
        
        // Opcional: Guardar en el DataManager si es necesario
        dataManager.saveChanges()
    }
}

struct ResumenAsistenciaView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var attendanceVM: AttendanceViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Asistencia Hoy")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: AttendanceView()) {
                    Text("Ver todo")
                        .font(.subheadline)
                }
            }
            
            let stats = attendanceVM.getAttendanceStats()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Presentes")
                        .font(.subheadline)
                    Text("\(stats.present)")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                VStack(alignment: .leading) {
                    Text("Ausentes")
                        .font(.subheadline)
                    Text("\(stats.absent)")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                VStack(alignment: .leading) {
                    Text("Total")
                        .font(.subheadline)
                    Text("\(attendanceVM.employees.count)")
                        .font(.title2)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 80)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            
            if !stats.frequentAbsentees.isEmpty {
                VStack(alignment: .leading) {
                    Text("Alertas:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(stats.frequentAbsentees.prefix(2)) { employee in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("\(employee.name) - \(employee.operatorNumber)")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
