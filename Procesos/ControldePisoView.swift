//
//  REs.swift
//  Control de Piso
//
//  Created by Uls on 24/01/25.
//

//MARK: CONTROL DE PISO
import SwiftUI

struct ControlDePisoView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var filtroClasificacion: Clasificacion? = nil
    @State private var textoBusqueda: String = ""
    @State private var ordenSeleccionada: Orden? = nil
    @State private var articuloSeleccionado: Articulo? = nil
    @State private var mostrandoEditorOrden = false
    @State private var notaStandby: String = ""
    @State private var criterioOrden: CriterioOrden = .nombreArticulo
    @State private var semanasColapsadas: Set<String> = []
    @State private var mostrarToast = false
    @State private var mensajeCopiado: String? = nil
    @State private var mostrarSelectorDeImagen = false
    @State private var fuenteDeImagen: UIImagePickerController.SourceType = .photoLibrary
    @State private var mostrandoImagePicker: Bool = false
    @State private var imagenSeleccionada: UIImage? = nil
    @State private var irAListaBancos = false
    
    
    enum CriterioOrden: String, CaseIterable, Identifiable {
        case nombreArticulo = "Nombre del Artículo"
        case noWeek = "Semana"
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Buscador y filtros compactos
                VStack(spacing: 8) {
                    // Buscador con teclado numérico
                    buscadorYFiltros()
                    
                    // Nota para Stand-by
                    if filtroClasificacion == .Stb {
                        TextField("Nota para Stand-by", text: $notaStandby)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                    }
                    
                    // Lista de órdenes
                listaDeOrdenes()
                .listStyle(InsetGroupedListStyle())
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Control de Piso")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: compartirReportePDF) {
                            Label("Exportar", systemImage: "square.and.arrow.up")
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { irAListaBancos = true }) {
                                Label("Bancos", systemImage: "list.number")
                            }
                        }
                }
               
                .sheet(isPresented: $mostrandoEditorOrden) {
                    if let orden = ordenSeleccionada, let articulo = articuloSeleccionado {
                    EditarOrdenView(orden: orden, articulo: articulo)
                    }
                }
            }
           .toast(message: mensajeCopiado ?? "", isShowing: $mostrarToast, duration: 2)
            
        }
        

    }
   
        // MARK: - Subvistas
            private func buscadorYFiltros() -> some View {
                VStack(spacing: 8) {
                    // Buscador
                    buscadorView()
                        .padding(.horizontal)

                    // Filtro por clasificación
                    filtroClasificacionPicker()
                        .padding(.horizontal)

                    // Ordenación
                    criterioOrdenPicker()
                        .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .onTapGesture { ocultarTeclado() }
            }

            private func buscadorView() -> some View {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Buscar órdenes...", text: $textoBusqueda)
                        .keyboardType(.numberPad)
                        .font(.body)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }

    private func filtroClasificacionPicker() -> some View {
                Picker("Filtrar por Clasificación", selection: $filtroClasificacion) {
                    Text("Todas").tag(Clasificacion?.none)
                    ForEach(Clasificacion.allCases, id: \.self) { clasificacion in
                        Text(clasificacion.rawValue).tag(clasificacion)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        
    private func criterioOrdenPicker() -> some View {
                Picker("Ordenar por", selection: $criterioOrden) {
                    ForEach(CriterioOrden.allCases) { criterio in
                        Text(criterio.rawValue).tag(criterio)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }

    private func listaDeOrdenes() -> some View {
        // ScrollView {
        // LazyVStack {
        List {
            if criterioOrden == .nombreArticulo {
                listaPorArticulo()
            } else if criterioOrden == .noWeek {
                listaPorSemana()
            }
        }
        //}
    //}
    }
    
    
    // MARK: - Ocultar Teclado
    private func ocultarTeclado() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func listaPorArticulo() -> some View {
        ForEach(dataManager.articulos) { articulo in
            let ordenesFiltradas = ordenesFiltradas(para: articulo)

            if !ordenesFiltradas.isEmpty {
                Section(header:
                    HStack(spacing: 8) {
                        Text(articulo.nombre)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(6)
                        
                        Text(articulo.descripcion)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.6))
                            .cornerRadius(6)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                ) {
                    ForEach(ordenesFiltradas) { orden in
                        ordenFila(orden: orden, criterio: .nombreArticulo)
                    }
                }

                // Indicador de total de órdenes
                HStack {
                    Spacer()
                    Text("Total órdenes: \(ordenesFiltradas.count)")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.blue.opacity(0.8)))
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
        }
    }


    private func listaPorSemana() -> some View {
        let agrupadasPorNoWeek = Dictionary(grouping: ordenesOrdenadasPorNoWeek(), by: { $0.noWeek ?? "Sin Semana" })

        return ForEach(agrupadasPorNoWeek.keys.sorted(by: >), id: \.self) { noWeek in
            let ordenesGrupo = agrupadasPorNoWeek[noWeek] ?? []
            DisclosureGroup(isExpanded: Binding(
                get: { !semanasColapsadas.contains(noWeek) },
                set: { isExpanded in
                    if isExpanded {
                        semanasColapsadas.remove(noWeek)
                    } else {
                        semanasColapsadas.insert(noWeek)
                    }
                }
            )) {
                // Contenido de la semana: Lista de órdenes
                ForEach(ordenesGrupo) { orden in
                    ordenFila(orden: orden, criterio: .noWeek)
                }
            } label: {
                // Encabezado del grupo
                HStack {
                    Text("Semana: \(noWeek)")
                        //.font(.body)
                        //.foregroundColor(.blue)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.8))
                        .cornerRadius(6)
                    Spacer()
                    Text("Total órdenes: \(ordenesGrupo.count)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(6)
                }
            }
            .padding(.vertical, 5)
        }
    }

    private func ordenFila(orden: Orden, criterio: CriterioOrden) -> some View {
        let esDuplicada = dataManager.articulos
            .flatMap { $0.ordenes }
            .filter { $0.nombre == orden.nombre }
            .count > 1

        return VStack(alignment: .leading, spacing: 4) {
            // Información principal de la orden
            HStack {
                Text(orden.nombre)
                    .font(.headline)
                Spacer()
                Text(orden.clasificacion.rawValue)
                    .foregroundColor(colorParaClasificacion(orden.clasificacion))
                    .bold()
            }

            HStack{
                // Mostrar fecha de última modificación debajo de la clasificación y Banco
                if let fecha = orden.fechaUltimaModificacion {
                    Text("\(fecha, formatter: dateFormatter)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Spacer()
                    if orden.clasificacion == .proceso {
                        if let datoBanco = orden.banco { // Asegúrate de que 'banco' existe en el modelo Orden
                            // Mostrar información adicional de Banco debajo de la clasificación
                            Text("Est.: \(datoBanco)")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        } else {
                            Text("Est.?")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }

            // Detalles adicionales según criterio de ordenación
            switch criterio {
            case .nombreArticulo:
                if let noWeek = orden.noWeek {
                    Text("Semana: \(noWeek)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            case .noWeek:
                if let descripcion = articuloParaOrden(orden)?.descripcion {
                    Text(descripcion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
        .background(esDuplicada ? Color.yellow.opacity(0.3) : Color.clear) // Fondo amarillo para duplicados
        .padding(.vertical, 4)
        .swipeActions {
            // Opciones de acción: Editar y compartir
            Button(action: {
                ordenSeleccionada = orden
                articuloSeleccionado = articuloParaOrden(orden)
                mostrandoEditorOrden = true
            }) {
                Label("Editar", systemImage: "pencil")
            }
            .tint(.blue)
            
            Button(action: {
                compartirInformacion(orden: orden)
            }) {
                Label("Compartir", systemImage: "square.and.arrow.up")
            }
            .tint(.green)
        }
    }

    
//->
    struct ActivityView: UIViewControllerRepresentable {
        var activityItems: [Any]
        var applicationActivities: [UIActivity]? = nil

        func makeUIViewController(context: Context) -> UIActivityViewController {
            let controller = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: applicationActivities
            )
            return controller
        }

        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
            // No es necesario actualizar el controlador
        }
    }
//-<
    // Función para copiar texto y mostrar un toast
    private func compartirInformacion(orden: Orden) {
        guard let articulo = articuloParaOrden(orden) else { return }
        
        // Calcular el tiempo transcurrido
        let tiempoTranscurrido: String
        if let fechaInicio = orden.fechaInicioProceso {
            let intervaloTiempo = Date().timeIntervalSince(fechaInicio)
            let horas = Int(intervaloTiempo) / 3600
            let minutos = (Int(intervaloTiempo) % 3600) / 60
            tiempoTranscurrido = "\(horas)h \(minutos)m"
        } else {
            tiempoTranscurrido = "Sin fecha de inicio"
        }
        
        // Formatear el mensaje
        let mensaje = """
        > Orden: *\(orden.nombre)* | Stat.: *\(orden.clasificacion.rawValue.capitalized)*
        *\(articulo.nombre)* | ```\(articulo.descripcion)```
        > Tiempo de Proceso: *\(tiempoTranscurrido)*
        """
        
        // Copiar texto al portapapeles
        UIPasteboard.general.string = mensaje
        
        // Mostrar el Toast indicando que el texto se copió
        mensajeCopiado = "Texto copiado"
        mostrarToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            mostrarToast = false
        }
        
        // Crear el ActivityView con el mensaje
        let activityView = ActivityView(activityItems: [mensaje])
        
        // Presentar el ActivityView en la vista actual
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            let hostingController = UIHostingController(rootView: activityView)
            rootViewController.present(hostingController, animated: true, completion: nil)
        }
    }
   
    // Función para obtener el artículo correspondiente para la orden
    private func articuloParaOrden(_ orden: Orden) -> Articulo? {
        dataManager.articulos.first { $0.ordenes.contains { $0.id == orden.id } }
    }

    // MARK: - Filtrado de órdenes
    /// Filtra las órdenes según la clasificación y el texto de búsqueda.
    private func ordenesFiltradas(para articulo: Articulo) -> [Orden] {
        var ordenes = articulo.ordenes
        if let filtro = filtroClasificacion {
            ordenes = ordenes.filter { $0.clasificacion == filtro }
        }
        if !textoBusqueda.isEmpty {
            ordenes = ordenes.filter {
                $0.nombre.localizedCaseInsensitiveContains(textoBusqueda) ||
                $0.clasificacion.rawValue.localizedCaseInsensitiveContains(textoBusqueda)
            }
        }
        return ordenes
    }
    
    private func ordenesOrdenadasPorNoWeek() -> [Orden] {
        let todasOrdenes = dataManager.articulos.flatMap { $0.ordenes }
        var ordenes = todasOrdenes

        // Filtrar por clasificación si aplica
        if let filtro = filtroClasificacion {
            ordenes = ordenes.filter { $0.clasificacion == filtro }
        }

        // Filtrar por texto de búsqueda si aplica
        if !textoBusqueda.isEmpty {
            ordenes = ordenes.filter {
                $0.nombre.localizedCaseInsensitiveContains(textoBusqueda) ||
                $0.clasificacion.rawValue.localizedCaseInsensitiveContains(textoBusqueda)
            }
        }
        // Ordenar las órdenes por semana en orden descendente
        return ordenes.sorted {
            guard let noWeek1 = $0.noWeek, let noWeek2 = $1.noWeek else {
                // Las órdenes sin semana se colocan al final
                return $0.noWeek != nil
            }
            return noWeek1 > noWeek2 // Descendente
        }
    }


    private func mostrarEditor(para orden: Orden) {
        ordenSeleccionada = orden
        articuloSeleccionado = articuloParaOrden(orden)
        mostrandoEditorOrden = true
    }


    private func colorParaClasificacion(_ clasificacion: Clasificacion) -> Color {
        switch clasificacion {
        case .revision: return .purple
      //  case .eb: return .blue
        case .Stb: return .red
        case .proceso: return .orange
        case .terminada: return .green
        }
    }

    private func totalOrdenesTexto(total: Int) -> Text {
        Text("Total órdenes: \(total)")
            .font(.footnote)
            .foregroundColor(.gray)
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE dd/MMM/yy hh:mm"
        return formatter
    }()
    

    private func compartirReportePDF() {
        let generator = PDFGenerator(ordenes: dataManager.articulos.flatMap { $0.ordenes }, articulos: dataManager.articulos, dateFormatter: dateFormatter)
        let pdfData = generator.generarPDF()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("reporte_ordenes.pdf")

        do {
            try pdfData.write(to: tempURL)
            let actividad = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
                .first {
                rootVC.present(actividad, animated: true, completion: nil)
            }
        } catch {
            print("Error al guardar el PDF: \(error)")
            // Mostrar un mensaje de error al usuario
            mensajeCopiado = "Error al generar el PDF"
            mostrarToast = true
        }
    }

//MARK: PDF PARA CONTROL DE PISO
    class PDFGenerator {
        private let ordenes: [Orden]
        private let articulos: [Articulo]
        private let dateFormatter: DateFormatter

        init(ordenes: [Orden], articulos: [Articulo], dateFormatter: DateFormatter) {
            self.ordenes = ordenes
            self.articulos = articulos
            self.dateFormatter = dateFormatter
        }

        func generarPDF() -> Data {
            let pdfMetaData = [
                kCGPDFContextCreator: "Control de Piso",
                kCGPDFContextAuthor: "Tu App",
                kCGPDFContextTitle: "Reporte de Órdenes"
            ]
            let format = UIGraphicsPDFRendererFormat()
            format.documentInfo = pdfMetaData as [String: Any]

            let pageWidth = 612.0
            let pageHeight = 792.0
            let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)

            let data = renderer.pdfData { context in
                context.beginPage()

                // Definir colores para las clasificaciones
                let clasificacionColores: [Clasificacion: UIColor] = [
                    .revision: .systemPurple,
                 //   .eb: .systemBlue,
                    .Stb: .systemRed,
                    .proceso: .systemOrange,
                    .terminada: .systemGreen
                ]

                // Encabezado: Título, Autor y Fecha
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 20),
                    .foregroundColor: UIColor.black
                ]
                let subtitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.darkGray
                ]
                let title = "Reporte de Órdenes"
                let author = "Autor: Ulises I."
                let fechaReporte = "Fecha: \(dateFormatter.string(from: Date()))"

                NSString(string: title).draw(at: CGPoint(x: 20, y: 20), withAttributes: titleAttributes)
                NSString(string: author).draw(at: CGPoint(x: 20, y: 50), withAttributes: subtitleAttributes)
                NSString(string: fechaReporte).draw(at: CGPoint(x: 20, y: 70), withAttributes: subtitleAttributes)

                // Espaciado después del encabezado
                var yPos: CGFloat = 100

                // Encabezados de la tabla
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.black
                ]
                let columnWidths: [CGFloat] = [60, 130, 80, 100, 100, 100]
                let headers = ["Artículo", "Descripción", "Semana", "Orden", "Clasificación", "Fecha"]
                var xPos: CGFloat = 20

                for (index, header) in headers.enumerated() {
                    let headerRect = CGRect(x: xPos, y: yPos, width: columnWidths[index], height: 20)
                    NSString(string: header).draw(in: headerRect, withAttributes: attributes)
                    xPos += columnWidths[index]
                }
                yPos += 30

                // **Ordenar las órdenes por el número de semana**
                let ordenesOrdenadas = ordenes.sorted { (orden1, orden2) -> Bool in
                    let semana1 = orden1.noWeek ?? "0" // Si no hay semana, usar "0" como valor predeterminado
                    let semana2 = orden2.noWeek ?? "0"
                    return semana1 < semana2
                }

                // Dibujar filas
                for orden in ordenesOrdenadas {
                    xPos = 20
                    if let articulo = articulos.first(where: { $0.ordenes.contains { $0.id == orden.id } }) {
                        let ordenData = [
                            articulo.nombre,
                            articulo.descripcion,
                            orden.noWeek ?? "Sin semana",
                            orden.nombre,
                            orden.clasificacion.rawValue,
                            orden.fechaUltimaModificacion != nil ? dateFormatter.string(from: orden.fechaUltimaModificacion!) : "Sin fecha"
                            
                        ]

                        for (index, data) in ordenData.enumerated() {
                            let textColor: UIColor = index == 4 ? clasificacionColores[orden.clasificacion] ?? .black : .black
                            let textAttributes: [NSAttributedString.Key: Any] = [
                                .font: UIFont.systemFont(ofSize: 12),
                                .foregroundColor: textColor
                            ]

                            let textRect = CGRect(x: xPos, y: yPos, width: columnWidths[index], height: 20)
                            NSString(string: data).draw(in: textRect, withAttributes: textAttributes)
                            xPos += columnWidths[index]
                        }
                        yPos += 20

                        // Salto de página si se excede la altura
                        if yPos > pageHeight - 50 {
                            context.beginPage()
                            yPos = 20
                        }
                    }
                }
            }
            return data
        }
    }
}
