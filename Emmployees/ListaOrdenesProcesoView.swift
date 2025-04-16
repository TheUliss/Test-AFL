//
//  ListaOrdenesProcesoView.swift
//  Test AFL
//
//  Created by Uls on 11/04/25.
//


import SwiftUI
import PDFKit

//MARK: RESUMEN PRINCIPAL
struct ListaOrdenesProcesoView: View {
    @EnvironmentObject var dataManager: DataManager
    
    // Colores personalizados para urgencias
    private let colorAlta = Color(red: 0.8, green: 0.2, blue: 0.2)    // Rojo oscuro
    private let colorMedia = Color(red: 0.9, green: 0.6, blue: 0.1)   // Naranja
    private let colorBaja = Color(red: 0.3, green: 0.7, blue: 0.3)    // Verde
    private let colorTextoPrincipal = Color.primary
    private let colorTextoSecundario = Color.secondary

    var ordenesOrdenadas: [Orden] {
        dataManager.ordenesEnProceso.sorted {
            (Int($0.banco ?? "") ?? 0) < (Int($1.banco ?? "") ?? 0)
        }
    }

    var body: some View {
        NavigationView {
            List(ordenesOrdenadas) { orden in
                NavigationLink(destination: EditarProcesosView(orden: orden)) {
                    HStack {
                        // Contenido principal de la orden
                        VStack(alignment: .leading, spacing: 4) {
                            Text(orden.nombre)
                                .font(.headline)
                                .foregroundColor(colorTextoPrincipal)
                            
                            if let banco = orden.banco {
                                Text("Estación: \(banco)")
                                    .font(.subheadline)
                                    .foregroundColor(colorTextoSecundario)
                            }
                            
                            // Mostrar urgencia con color correspondiente
                            Text("Urgencia: \(orden.nivelUrgencia)")
                                .font(.subheadline)
                                .foregroundColor(colorParaUrgencia(orden.nivelUrgencia))
                        }
                        
                        Spacer()
                        
                        // Toggle para incluir en resumen (ahora visible directamente)
                        Toggle("", isOn: incluirEnResumenBinding(for: orden))
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            .labelsHidden()
                        
                        // Menú de configuración (solo para cambiar urgencia)
                        menuConfiguracion(for: orden)
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Órdenes en Proceso")
            .toolbar {
                NavigationLink(destination: ResumenProcesosView()) {
                    Text("Resumen")
                        .font(.headline)
                }
            }
        }
    }

    // Menú simplificado solo para cambiar urgencia
    func menuConfiguracion(for orden: Orden) -> some View {
        Menu {
            Picker("Urgencia", selection: urgenciaBinding(for: orden)) {
                Text("Baja").tag("Baja")
                Text("Media").tag("Media")
                Text("Alta").tag("Alta")
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
                .imageScale(.medium)
                .foregroundColor(.blue)
        }
    }

    // Función para determinar color según urgencia
    func colorParaUrgencia(_ urgencia: String) -> Color {
        switch urgencia.lowercased() {
        case "alta": return colorAlta
        case "media": return colorMedia
        case "baja": return colorBaja
        default: return colorTextoSecundario
        }
    }

    // Bindings (se mantienen igual)
    func urgenciaBinding(for orden: Orden) -> Binding<String> {
        Binding<String>(
            get: { orden.nivelUrgencia },
            set: { newValue in
                updateOrden(orden) { $0.nivelUrgencia = newValue }
            }
        )
    }

    func incluirEnResumenBinding(for orden: Orden) -> Binding<Bool> {
        Binding<Bool>(
            get: { orden.incluirEnResumen },
            set: { newValue in
                updateOrden(orden) { $0.incluirEnResumen = newValue }
            }
        )
    }

    func updateOrden(_ orden: Orden, update: (inout Orden) -> Void) {
        for i in dataManager.articulos.indices {
            if let j = dataManager.articulos[i].ordenes.firstIndex(where: { $0.id == orden.id }) {
                update(&dataManager.articulos[i].ordenes[j])
                break
            }
        }
    }
}

//MARK: EDICION DE OPERACIONES
struct EditarProcesosView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    var orden: Orden

    @State private var cantidades: [String: String] = [:]
    @State private var numeroReferencia: String = ""
    @State private var showAlert = false
    @FocusState private var focusedField: String?

    let operaciones = [
        "01 - Deschaquetado", "02 - Malla Grande", "03 - Malla Chica", "04 - Paso de luz", "05 - Foto",
        "06 - Retrabajos de Ensamble", "07 - Ribonizado", "08 - Depilado", "09 - Repulido", "10 - Pulido",
        "11 - Limpieza", "12 - Geometria", "13 - Armado", "14 - Crimpado", "15 - Quemado de Termo",
        "16 - Etiquetado", "17 - Inyeccion de Transferencia", "18 - Polaridad", "19 - Prueba", "20 - Limpieza",
        "21 - Calidad", "22 - Puntas Finales", "23 - Puntas Empacadas"
    ]

    // Colores para diseño
    private let colorPrincipal = Color.blue
    private let colorSecundario = Color.gray.opacity(0.2)
    private let colorError = Color.red
    private let colorExito = Color.green
    private let colorFondo = Color(.systemGroupedBackground)
    private let colorTexto = Color.primary
    private let colorTextoCampo = Color(.label)

    var body: some View {
        VStack(spacing: 0) {
            // Botones de acción en la parte superior
            actionButtons
                .padding(.horizontal)
                .padding(.top, 8)
                .background(colorFondo)
            
            Divider()
            
            // Sección de referencia
            referenciaSection
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            Divider()
            
            // Lista de operaciones
            operacionesList
                .background(colorFondo)
        }
        .background(colorFondo)
        .navigationTitle("Est: \(orden.banco ?? "-") - \(orden.nombre)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { cargarDatos() }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Limpiar Datos"),
                message: Text("¿Estás seguro de que quieres limpiar todos los campos excepto el número de referencia?"),
                primaryButton: .destructive(Text("Limpiar")) { limpiarCampos() },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - Componentes
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Botón Limpiar
            Button(action: { showAlert = true }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Limpiar")
                }
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(colorSecundario)
                .foregroundColor(colorTexto)
                .cornerRadius(8)
            }
            
            // Botón Guardar
            Button(action: guardarCambios) {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Guardar")
                }
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(colorPrincipal)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }
    
    private var referenciaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cantidad Puntas")
                .font(.headline)
                .foregroundColor(colorPrincipal)
            
            TextField("Puntas Totales", text: $numeroReferencia)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.body)
                .focused($focusedField, equals: "referencia")
            
            if let diferencia = diferencia {
                HStack {
                    Text("Total ingresado: \(totalIngresado)")
                        .foregroundColor(colorPrincipal)
                    
                    Spacer()
                    
                    if diferencia > 0 {
                        Text("Sobran: \(diferencia)")
                            .foregroundColor(colorError)
                    } else if diferencia < 0 {
                        Text("Faltan: \(-diferencia)")
                            .foregroundColor(colorError)
                    } else {
                        Text("Correcto")
                            .foregroundColor(colorExito)
                    }
                }
                .font(.subheadline)
            }
        }
    }
    
    private var operacionesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(operaciones, id: \.self) { op in
                    HStack(spacing: 16) {
                        Text(op)
                            .font(.subheadline)
                            .foregroundColor(colorTexto)
                            .frame(width: 200, alignment: .leading)
                            .padding(.vertical, 8)
                        
                        Spacer()
                        
                        TextField("0", text: Binding(
                            get: { cantidades[op] ?? "" },
                            set: {
                                if $0.isEmpty || Int($0) != nil {
                                    cantidades[op] = $0
                                }
                            }
                        ))
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                        .multilineTextAlignment(.center)
                        .focused($focusedField, equals: op)
                        .foregroundColor(colorTextoCampo)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Funciones
    
    private func cargarDatos() {
        // Cargar número de referencia si existe
        if let ref = orden.numeroReferencia {
            numeroReferencia = orden.numeroReferencia.map { String($0) } ?? ""
        }
        
        // Cargar cantidades
        for op in operaciones {
            if let cantidad = orden.cantidadesPorOperacion[op] {
            cantidades[op] = "\(cantidad)"
            }
        }
    }
    
    private func limpiarCampos() {
        // Limpiar todos los campos excepto número de referencia
        for op in operaciones {
            cantidades[op] = ""
        }
    }
    
    private func guardarCambios() {
        for (i, articulo) in dataManager.articulos.enumerated() {
            if let j = articulo.ordenes.firstIndex(where: { $0.id == orden.id }) {
                // Guardar cantidades
                for (op, val) in cantidades {
                    dataManager.articulos[i].ordenes[j].cantidadesPorOperacion[op] = Int(val) ?? 0
                }
                
                // Guardar número de referencia (manejo seguro del Optional)
                    dataManager.articulos[i].ordenes[j].numeroReferencia = Int(numeroReferencia)
                }
            }
            presentationMode.wrappedValue.dismiss()
    }
    
    // MARK: - Computed Properties
    
    var operacionesComparables: [String] {
        Array(operaciones.prefix(22))
    }
    
    var totalIngresado: Int {
        operacionesComparables.compactMap { Int(cantidades[$0] ?? "") }.reduce(0, +)
    }
    
    var diferencia: Int? {
        if let referencia = Int(numeroReferencia) {
            return totalIngresado - referencia
        }
        return nil
    }
}


//MARK:  ResumenProcesosView.swift

struct ResumenProcesosView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var mostrarShareSheet = false
    @State private var pdfURL: URL?
    @State private var debugInfo: String = ""
    @State private var showDebugInfo = false
    @State private var mostrarFormularioDatos = false
    @State private var datosPDF = DatosPDF()
    
    let operaciones = [
        "01 - Deschaquetado", "02 - Malla Grande", "03 - Malla Chica", "04 - Paso de luz", "05 - Foto",
        "06 - Retrabajos de Ensamble", "07 - Ribonizado", "08 - Depilado", "09 - Repulido", "10 - Pulido",
        "11 - Limpieza", "12 - Geometria", "13 - Armado", "14 - Crimpado", "15 - Quemado de Termo",
        "16 - Etiquetado", "17 - Inyeccion de Transferencia", "18 - Polaridad", "19 - Prueba", "20 - Limpieza",
        "21 - Calidad", "22 - Puntas Finales", "23 - Puntas Empacadas"
    ]
    
    // Modelo para los datos del PDF
    struct DatosPDF {
        var realizo: String = ""
        var area: String = ""
        var turno: String = "N2"
    }
    
    var ordenesFiltradasParaResumen: [Orden] {
        let filtered = dataManager.ordenes.filter { $0.clasificacion == .proceso && $0.incluirEnResumen }
        debugInfo += "Órdenes filtradas: \(filtered.count)\n"
        filtered.forEach { debugInfo += "- \($0.nombre) (\($0.banco ?? "sin Est:"))\n" }
        return filtered
    }
    
    var body: some View {
        VStack {
            // Vista previa del resumen
            ScrollView([.horizontal, .vertical]) {
                ResumenProcesosPDFViewFormal(
                    operaciones: operaciones,
                    ordenes: ordenesFiltradasParaResumen,
                    realizo: datosPDF.realizo,
                    area: datosPDF.area,
                    turno: datosPDF.turno
                )
                .padding()
                .background(Color(.systemBackground))
                .frame(width: 1000)
            }
            .frame(maxHeight: 500)
            
            // Botones de acción
            VStack(spacing: 10) {
                Button(action: {
                    if datosPDF.realizo.isEmpty || datosPDF.area.isEmpty {
                        mostrarFormularioDatos = true
                    } else {
                        generarPDF()
                    }
                }) {
                    Text("Exportar PDF")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: { showDebugInfo.toggle() }) {
                    Text("Ver información de depuración")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .navigationTitle("Estatus de Turno")
        .sheet(isPresented: $mostrarShareSheet) {
            if let url = pdfURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $mostrarFormularioDatos) {
            FormularioDatosPDF(datosPDF: $datosPDF) {
                generarPDF()
            }
        }
        .alert("Información", isPresented: $showDebugInfo) {
            Button("OK") {}
        } message: {
            Text(debugInfo)
        }
    }
    
    @MainActor
    private func generarPDF() {
        debugInfo = ""
        
        // Verificar datos primero
        guard !ordenesFiltradasParaResumen.isEmpty else {
            debugInfo += "ERROR: No hay órdenes para generar el resumen\n"
            return
        }
        
        // Configuración del PDF
      //  let pageSize = CGSize(width: 842, height: 595) // A4 landscape
        let pageSize = CGSize(width: 1250, height: 950) // A4 landscape
        let format = UIGraphicsPDFRendererFormat()// Initialization of immutable value 'format' was never used; consider replacing with assignment to '_' or removing it
       // let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
         
        // Crear vista PDF con los datos ingresados
        let pdfView = ResumenProcesosPDFViewFormal(
            operaciones: operaciones,
            ordenes: ordenesFiltradasParaResumen,
            realizo: datosPDF.realizo,
            area: datosPDF.area,
            turno: datosPDF.turno
        )
        .frame(width: pageSize.width - 40, height: pageSize.height - 40)
        .padding(20)
        .background(Color.white)
        
        // Generar PDF
        let data = renderPDF(view: pdfView, pageSize: pageSize)
        
        // Guardar archivo
        let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateString = dateFormatter.string(from: Date())
            let fileName = "ResumenProcesos_\(dateString).pdf"
            
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(fileName)
            
            do {
                try data.write(to: tempURL)
                pdfURL = tempURL
                mostrarShareSheet = true
                debugInfo += "PDF guardado en: \(tempURL.path)\n"
            } catch {
                debugInfo += "ERROR al guardar PDF: \(error.localizedDescription)\n"
                debugInfo += "Ruta intentada: \(tempURL.path)\n"
            }
    }
    
    private func renderPDF(view: some View, pageSize: CGSize) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        
        return renderer.pdfData { context in
            context.beginPage()
            
            let hostingController = UIHostingController(rootView: view)
            hostingController.view.frame = CGRect(origin: .zero, size: pageSize)
            hostingController.view.backgroundColor = .white
            
            hostingController.view.setNeedsLayout()
            hostingController.view.layoutIfNeeded()
            
            hostingController.view.drawHierarchy(in: hostingController.view.bounds, afterScreenUpdates: true)
        }
    }
}

// Vista para ingresar los datos del PDF
struct FormularioDatosPDF: View {
    @Binding var datosPDF: ResumenProcesosView.DatosPDF
    var onGenerarPDF: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    let turnosDisponibles = ["N1", "N2", "N3", "N4"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información del Reporte")) {
                    TextField("Realizado por", text: $datosPDF.realizo)
                        .textContentType(.name)
                    
                    TextField("Área", text: $datosPDF.area)
                        .textContentType(.organizationName)
                    
                    Picker("Turno", selection: $datosPDF.turno) {
                        ForEach(turnosDisponibles, id: \.self) { turno in
                            Text(turno).tag(turno)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Datos del Reporte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generar") {
                        onGenerarPDF()
                        dismiss()
                    }
                    .disabled(datosPDF.realizo.isEmpty || datosPDF.area.isEmpty)
                }
            }
        }
    }
}


//MARK: RESUMEN FORNAL

struct ResumenProcesosPDFViewFormal: View {
    let operaciones: [String]
    let ordenes: [Orden]
    let realizo: String
    let area: String
    let turno: String
    
    // Configuración de paginación
    private let maxColumnsPerPage = 8 // Máximo de columnas por página
    private let pdfBackgroundColor = Color.white
    private let pdfTextColor = Color(red: 0.2, green: 0.2, blue: 0.2)
    private let pdfHeaderColor = Color(red: 0.95, green: 0.95, blue: 0.95)
    
    private var fechaCreacion: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: Date())
    }
    
    // Divide las órdenes en grupos para paginación
    private var ordenesPaginated: [[Orden]] {
        let sorted = ordenes.sorted {
            urgenciaValor($0.nivelUrgencia) < urgenciaValor($1.nivelUrgencia)
        }
        return stride(from: 0, to: sorted.count, by: maxColumnsPerPage).map {
            Array(sorted[$0..<min($0 + maxColumnsPerPage, sorted.count)])
        }
    }
    
    var body: some View {
        // Vista contenedora para el PDF
        ForEach(0..<ordenesPaginated.count, id: \.self) { pageIndex in
            VStack(alignment: .leading, spacing: 12) {
                // Encabezado (se repite en cada página)
                headerView
                
                // Tabla principal (diferente por página)
                tablaView(for: ordenesPaginated[pageIndex])
                
                // Pie de página (se repite en cada página)
                footerView(page: pageIndex + 1, total: ordenesPaginated.count)
            }
            .padding()
            .background(pdfBackgroundColor)
            .environment(\.colorScheme, .light)
            //.frame(width: 842 - 40, height: 595 - 40) // A4 landscape con márgenes
            .frame(width: 1150 - 40, height: 890 - 40) // A4 landscape con márgenes
            .pageBreak(after: pageIndex < ordenesPaginated.count - 1)
        }
    }
    
    // MARK: - Componentes reutilizables
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "gear")
                    .font(.system(size: 24))
                Text("Estatus de Turno")
                    .font(.system(size: 20, weight: .bold))
            }
            .foregroundColor(pdfTextColor)
            
            Divider()
            
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                GridRow {
                    Text("Fecha:").bold()
                    Text(fechaCreacion)
                    Text("Realizó:").bold()
                    Text(realizo)
                }
                
                GridRow {
                    Text("Área:").bold()
                    Text(area)
                    Text("Turno:").bold()
                    Text(turno)
                }
            }
            .font(.system(size: 12))
            .foregroundColor(pdfTextColor)
            
            Divider()
        }
    }
    
    private func tablaView(for ordenesPagina: [Orden]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Grid(alignment: .center, horizontalSpacing: 0, verticalSpacing: 0) {
                // Encabezados de columnas
                GridRow {
                    Text("Operación")
                        .frame(width: 200, alignment: .leading)
                        .padding(8)
                        .background(pdfHeaderColor)
                        .border(Color.gray.opacity(0.2))
                    
                    ForEach(ordenesPagina, id: \.id) { orden in
                        VStack(spacing: 4) {
                            Text("Est: \(orden.banco ?? "-")")
                            Text("(\(orden.nombre))")
                                .font(.caption)
                        }
                        .frame(width: 100)
                        .padding(8)
                        .background(colorParaUrgencia(orden.nivelUrgencia).opacity(0.7))
                        .border(Color.gray.opacity(0.2))
                    }
                    
                    Text("Total")
                        .frame(width: 80)
                        .padding(8)
                        .background(pdfHeaderColor)
                        .border(Color.gray.opacity(0.2))
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(pdfTextColor)
                
                // Filas de datos
                ForEach(operaciones, id: \.self) { op in
                    GridRow {
                        Text(op)
                            .frame(width: 200, alignment: .leading)
                            .padding(8)
                            .border(Color.gray.opacity(0.2))
                        
                        ForEach(ordenesPagina, id: \.id) { orden in
                            Text("\(orden.cantidadesPorOperacion[op] ?? 0)")
                                .frame(width: 100)
                                .padding(8)
                                .border(Color.gray.opacity(0.2))
                        }
                        
                        let total = ordenesPagina.reduce(0) { $0 + ($1.cantidadesPorOperacion[op] ?? 0) }
                        Text("\(total)")
                            .frame(width: 80)
                            .padding(8)
                            .border(Color.gray.opacity(0.2))
                    }
                    .font(.system(size: 12))
                    .foregroundColor(pdfTextColor)
                }
            }
        }
    }
    
    private func footerView(page: Int, total: Int) -> some View {
        VStack(spacing: 4) {
            Divider()
            HStack {
                Text("Página \(page) de \(total)")
                Spacer()
                Text("Generado el \(fechaCreacion)")
            }
            .font(.caption)
            .foregroundColor(pdfTextColor.opacity(0.7))
        }
        .padding(.top, 8)
    }
    
    func urgenciaValor(_ urgencia: String) -> Int {
        switch urgencia.lowercased() {
        case "alta": return 0
        case "media": return 1
        case "baja": return 2
        default: return 3
        }
    }
    
    func colorParaUrgencia(_ urgencia: String) -> Color {
        switch urgencia.lowercased() {
        case "alta": return Color.red.opacity(0.3)
        case "media": return Color.yellow.opacity(0.3)
        case "baja": return Color.green.opacity(0.3)
        default: return Color.gray.opacity(0.2)
        }
    }
}

// Extensión para control de paginación
extension View {
    func pageBreak(after: Bool) -> some View {
        self.background(
            GeometryReader { geometry in
                if after {
                    Color.clear
                        .preference(
                            key: PageBreakPreferenceKey.self,
                            value: [geometry.frame(in: .global).maxY]
                        )
                }
            }
        )
    }
}

struct PageBreakPreferenceKey: PreferenceKey {
    static var defaultValue: [CGFloat] = []
    
    static func reduce(value: inout [CGFloat], nextValue: () -> [CGFloat]) {
        value.append(contentsOf: nextValue())
    }
}

// Vista para compartir
struct ShareSheet2: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct GridStack<Content: View>: View {
    let rows: Int
    let columns: Int
    let content: (Int, Int) -> Content

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<columns, id: \.self) { column in
                        content(row, column)
                    }
                }
            }
        }
    }
}


struct PDFCreator {
    static func export(view: some View, completion: @escaping (URL?) -> Void) {
        let hosting = UIHostingController(rootView: view)
        let size = CGSize(width: 842, height: 1191) // Tamaño A4 en puntos

        hosting.view.bounds = CGRect(origin: .zero, size: size)
        hosting.view.backgroundColor = .white

        let renderer = UIGraphicsPDFRenderer(bounds: hosting.view.bounds)

        DispatchQueue.main.async {
            let data = renderer.pdfData { context in
                context.beginPage()
                hosting.view.drawHierarchy(in: hosting.view.bounds, afterScreenUpdates: true)
            }

            let url = FileManager.default.temporaryDirectory.appendingPathComponent("ResumenTurno.pdf")
            do {
                try data.write(to: url)
                completion(url)
            } catch {
                print("Error al guardar PDF: \(error)")
                completion(nil)
            }
        }
    }
}


