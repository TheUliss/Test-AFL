//  SimuladorView.swift
//  Control de Piso
//
//  Created by Uls on 24/01/25.
//


//MARK: Pedido Materiales

import SwiftUI
import PDFKit

struct PedidosView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var cantidades: [UUID: Int] = [:]
    @State private var seleccionados: Set<UUID> = []
 //   @State private var showingResumenView = false
    @State private var showingExportConfig = false
    @State private var showingResumenMaterialesView = false
    
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { hideKeyboard() }
                
                VStack(spacing: 0) {
                    // Lista de artículos
                    List {
                        ForEach(dataManager.articulos) { articulo in
                            ArticuloRow(
                                articulo: articulo,
                                cantidades: $cantidades,
                                isSelected: seleccionados.contains(articulo.id)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleSeleccion(articulo: articulo)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    
                    // Botón de Generar Resumen
                    Button(action: generarResumen) {
                    Label("Generar Resumen", systemImage: "list.bullet")
                                                    .frame(maxWidth: .infinity)
                                            }
                    .buttonStyle(ActionButtonStyle(disabled: seleccionados.isEmpty))
                    .disabled(seleccionados.isEmpty)
                    .padding()
                }
            }
            .navigationTitle("Pedido de Materiales")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingExportConfig.toggle() }) {
                        Image(systemName: "gear")
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: toggleSeleccionTodos) {
                        Label(
                            seleccionados.count == dataManager.articulos.count ? "Todos" : "Todos",
                            systemImage: seleccionados.count == dataManager.articulos.count ?
                                "checkmark.rectangle.stack.fill" : "rectangle.stack"
                        )
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.blue)
                        .font(.subheadline)
                    }
                }
            }
            .sheet(isPresented: $showingExportConfig) {
                ExportConfigView()
                    .environmentObject(dataManager)
            }
        /*    .sheet(isPresented: $showingResumenView) {
                ResumenView(materiales: $dataManager.materialesResumen)
                    .environmentObject(dataManager)
            }*/
            .sheet(isPresented: $showingResumenMaterialesView) {
                ResumenMaterialesView()
                    .environmentObject(dataManager)
            }
        }
    }
    
    
    // Función para alternar selección
    private func toggleSeleccionTodos() {
        if seleccionados.count == dataManager.articulos.count {
            seleccionados.removeAll()
        } else {
            seleccionados = Set(dataManager.articulos.map { $0.id })
        }
    }
    
    // Resto de tus funciones existentes...
    private func toggleSeleccion(articulo: Articulo) {
        if seleccionados.contains(articulo.id) {
            seleccionados.remove(articulo.id)
        } else {
            seleccionados.insert(articulo.id)
        }
    }
    
    private func generarResumen() {
        let resumen = calcularResumenMaterialesLista()
        dataManager.materialesResumen = resumen
   //     showingResumenView = true
        showingResumenMaterialesView = true
    }
    
    private func calcularResumenMaterialesLista() -> [Material] {
        var resumen: [Material] = []
        
        for articulo in dataManager.articulos where seleccionados.contains(articulo.id) {
            let cantidadArticulo = cantidades[articulo.id, default: 1]
            for material in articulo.materiales {
                if let index = resumen.firstIndex(where: { $0.nombre == material.nombre }) {
                    resumen[index].cantidadRequerida += material.cantidadRequerida * cantidadArticulo
                } else {
                    let nuevoMaterial = Material(
                        id: material.id,
                        nombre: material.nombre,
                        cantidadRequerida: material.cantidadRequerida * cantidadArticulo
                    )
                    resumen.append(nuevoMaterial)
                }
            }
        }
        return resumen
    }
}

//MARK: ARTICULOROW
// Versión simplificada de ArticuloRow
struct ArticuloRow: View {
    let articulo: Articulo
    @Binding var cantidades: [UUID: Int]
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                // Nombre del artículo
                Text(articulo.nombre)
                    .font(.headline)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // Campo de cantidad (alineado a la derecha con padding)
                if isSelected {
                    Spacer(minLength: 10)
                    
                    Text("Cant:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("1", value: Binding(
                        get: { cantidades[articulo.id, default: 1] },
                        set: { newValue in
                            if newValue > 0 && newValue <= 1000 {
                                cantidades[articulo.id] = newValue
                            }
                        }
                    ), formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .frame(width: 50)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.trailing, 8) // Margen derecho adicional
                }
            }
            .padding(.horizontal, 8) // Padding interno del HStack
            
            // Lista de materiales
            if isSelected {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(articulo.materiales) { material in
                        MaterialRow(material: material,
                                    cantidad: cantidades[articulo.id, default: 1])
                    }
                }
                .padding(.leading, 24)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12) // Padding general aumentado
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.blue.opacity(0.08) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.blue.opacity(0.2) : Color.clear,
                                lineWidth: 1)))
    }
}

/*
// Estilos (igual que antes)
struct SelectionButtonStyle: ButtonStyle {
    let backgroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(10)
            .background(backgroundColor)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
*/
struct ActionButtonStyle: ButtonStyle {
    let disabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(disabled ? Color.gray : Color.blue)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

    // Extensión para ocultar teclado
    extension View {
        func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    //MARK: MATERIALROW
    // Componente para mostrar los materiales de un artículo
    struct MaterialRow: View {
        var material: Material
        var cantidad: Int
        
        var body: some View {
            HStack {
                Text("- \(material.nombre)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(material.cantidadRequerida) = \(material.cantidadRequerida * cantidad)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }


/*
    //MARK: VISTA DATOS PDF
 
    struct ExportView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var pdfURL: URL?
    @State private var showingShareSheet = false
    var materiales: [Material]
    @State private var inputImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Resumen de configuración
                VStack(spacing: 12) {
                    if let logoData = dataManager.logoData, let logo = UIImage(data: logoData) {
                        Image(uiImage: logo)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                    }
                    
                    VStack(spacing: 4) {
                        Text(dataManager.empresa)
                            .font(.headline)
                        Text(dataManager.usuario)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top)
                
                Divider()
                
                // Vista previa del PDF
                Text("Vista Previa del Reporte")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(materiales.prefix(5)) { material in
                            HStack {
                                Text(material.nombre)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(material.cantidadRequerida)")
                                    .frame(width: 60, alignment: .trailing)
                            }
                            .padding(.horizontal)
                        }
                        
                        if materiales.count > 5 {
                            Text("+ \(materiales.count - 5) materiales más...")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxHeight: 200)
                
                Spacer()
                
                // Botón de generación
                Button(action: generarPDF) {
                    Label("Generar y Compartir PDF", systemImage: "doc.fill")
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
            .padding(.horizontal)
            .navigationTitle("Exportar a PDF")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingShareSheet) {
                if let pdfURL = pdfURL {
                    ShareSheet(activityItems: [pdfURL])
                }
            }
        }
    }
    
    private func generarPDF() {
        guard !dataManager.empresa.isEmpty, !dataManager.usuario.isEmpty else {
            return
        }
        
        if let pdfURL = PDFGenerator.createPDF(
            empresa: dataManager.empresa,
            usuario: dataManager.usuario,
            logo: dataManager.logoData != nil ? UIImage(data: dataManager.logoData!) : nil,
            materiales: materiales
            )   {
            self.pdfURL = pdfURL
            showingShareSheet = true
                }
            }
        }
        
 */
        
        private func resizeImage(image: UIImage, maxSize: CGFloat) -> UIImage {
            let aspectRatio = image.size.width / image.size.height
            let newSize: CGSize
            if aspectRatio > 1 {
                newSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
            } else {
                newSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
            }
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return resizedImage ?? image
        }
        
   

//MARK: PDF GENERATOR

import UIKit
import PDFKit

class PDFGenerator {
    static func createPDF(empresa: String, usuario: String, logo: UIImage?, materiales: [Material]) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Control de Inventario",
            kCGPDFContextAuthor: usuario,
            kCGPDFContextTitle: "Reporte de Inventario"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth: CGFloat = 612.0 // Tamaño carta
        let pageHeight: CGFloat = 792.0
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)

        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("ReporteInventario.pdf")

        do {
            try renderer.writePDF(to: fileURL) { context in
                context.beginPage()
                dibujarEncabezado(context: context, empresa: empresa, usuario: usuario, logo: logo, pageWidth: pageWidth)
                dibujarTabla(context: context, materiales: materiales, yPos: 140, pageWidth: pageWidth)
            }
            return fileURL
        } catch {
            print("Error al crear PDF: \(error)")
            return nil
        }
    }

    private static func dibujarEncabezado(context: UIGraphicsPDFRendererContext, empresa: String, usuario: String, logo: UIImage?, pageWidth: CGFloat) {
        if let logo = logo {
            let logoRect = CGRect(x: 20, y: 20, width: 80, height: 80)
            logo.draw(in: logoRect)
        }

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24)
        ]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.gray
        ]

        let title = "Materiales en Piso"
        title.draw(at: CGPoint(x: 120, y: 30), withAttributes: titleAttributes)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: Date())
        
        let subtitle = "Generado por: \(usuario) - \(empresa)\nFecha: \(dateString)"
        subtitle.draw(at: CGPoint(x: 120, y: 60), withAttributes: subtitleAttributes)

        // Línea divisoria
        context.cgContext.move(to: CGPoint(x: 20, y: 110))
        context.cgContext.addLine(to: CGPoint(x: pageWidth - 20, y: 110))
        context.cgContext.strokePath()
    }

    private static func dibujarTabla(context: UIGraphicsPDFRendererContext, materiales: [Material], yPos: CGFloat, pageWidth: CGFloat) {
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14)
        ]
        let columnTitles = ["Material", "Requerido", "Disponible", "A Pedir"]
        var xPos: CGFloat = 20
        let columnWidths: [CGFloat] = [200, 100, 100, 100]

        // Dibujar encabezados de la tabla
        for (index, title) in columnTitles.enumerated() {
            title.draw(at: CGPoint(x: xPos, y: yPos), withAttributes: headerAttributes)
            xPos += columnWidths[index] + 10 // Espacio entre columnas
        }

        var currentYPos = yPos + 20
        let rowAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12)
        ]

        // Dibujar filas de materiales
        for material in materiales {
            xPos = 20
            let materialData = [
                material.nombre,
                "\(material.cantidadRequerida)",
                "\(material.cantidadDisponible)",
                "\(material.cantidadAPedir)" // Usar la cantidad a pedir
            ]

            for (index, data) in materialData.enumerated() {
                data.draw(at: CGPoint(x: xPos, y: currentYPos), withAttributes: rowAttributes)
                xPos += columnWidths[index] + 10 // Espacio entre columnas
            }

            currentYPos += 20 // Espacio entre filas
        }
    }
}

    
//MARK: SELECCION DE IMAGEN
import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}


//MARK: RESUMEN
/*import SwiftUI
import UIKit

struct ResumenView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var materiales: [Material]
    @State private var cantidadesDisponibles: [UUID: Int] = [:]
    @Environment(\.presentationMode) var presentationMode
    @State private var pdfURL: URL? = nil
    @State private var showingShareSheet = false
    @State private var resaltados: Set<UUID> = [] // Materiales con cambios en "A Pedir"

    var body: some View {
        NavigationView {
            VStack {
                // Encabezado de tabla
                HStack {
                    Text("Material")
                        .font(.footnote) // Cambiar el tamaño de la letra a .footnote
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Requerido")
                        .font(.footnote) // Cambiar el tamaño de la letra a .footnote
                        .frame(width: 70, alignment: .trailing)
                    
                    Text("Disponible")
                        .font(.footnote) // Cambiar el tamaño de la letra a .footnote
                        .frame(width: 70, alignment: .trailing)
                    
                    Text("A Pedir")
                        .font(.footnote) // Cambiar el tamaño de la letra a .footnote
                        .frame(width: 50, alignment: .trailing)
                }
                .font(.headline)
                .padding()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(12)
                .padding(.horizontal)

                // Lista de materiales en un ScrollView
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(materiales) { material in
                            HStack {
                                Text(material.nombre)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("\(material.cantidadRequerida)")
                                    .frame(width: 50, alignment: .center)

                                TextField("", value: Binding(
                                    get: { cantidadesDisponibles[material.id, default: 0] },
                                    set: { newValue in
                                        let oldValue = cantidadesDisponibles[material.id, default: 0]
                                        cantidadesDisponibles[material.id] = newValue
                                        actualizarCantidadAPedir(materialID: material.id, oldValue: oldValue, newValue: newValue)
                                    }
                                ), formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .frame(width: 60, alignment: .trailing)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onSubmit {
                                    hideKeyboard()
                                }

                                Text("\(material.cantidadAPedir)")
                                    .frame(width: 50, alignment: .center)
                                    .foregroundColor(resaltados.contains(material.id) ? .red : .primary) // Mantiene resaltado si hubo cambios
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    }
                    .onTapGesture {
                        hideKeyboard() // Oculta el teclado al tocar fuera
                    }
                }

                // Botón para generar PDF
                Button(action: generarPDF) {
                    Label("Generar PDF", systemImage: "doc.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .navigationTitle("Pedido de Materiales")
            .sheet(isPresented: $showingShareSheet) {
                if let pdfURL = pdfURL {
                    ShareSheet(activityItems: [pdfURL])
                }
            }
        }
    }

    // Función para actualizar "A Pedir" y resaltar cambios
    private func actualizarCantidadAPedir(materialID: UUID, oldValue: Int, newValue: Int) {
        if let index = materiales.firstIndex(where: { $0.id == materialID }) {
            let cantidadDisponible = cantidadesDisponibles[materialID, default: 0]
            let cantidadRequerida = materiales[index].cantidadRequerida
            let nuevaCantidadAPedir = max(0, cantidadRequerida - cantidadDisponible)

            // Si el valor cambió, añadirlo al conjunto de resaltados
            if newValue != oldValue {
                resaltados.insert(materialID)
            }

            materiales[index].cantidadDisponible = cantidadDisponible
            materiales[index].cantidadAPedir = nuevaCantidadAPedir
        }
    }

    // Función para generar PDF
    private func generarPDF() {
        hideKeyboard()
        
        for index in materiales.indices {
            materiales[index].cantidadDisponible = cantidadesDisponibles[materiales[index].id, default: 0]
            materiales[index].cantidadAPedir = max(0, materiales[index].cantidadRequerida - materiales[index].cantidadDisponible)
        }
        
        if let pdfURL = PDFGenerator.createPDF(
            empresa: dataManager.empresa,
            usuario: dataManager.usuario,
            logo: UIImage(data: dataManager.logoData ?? Data()),
            materiales: materiales
        ) {
            self.pdfURL = pdfURL
            showingShareSheet = true
        }
    }

    // Función para ocultar el teclado
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
 */

struct ExportConfigView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información de Empresa")) {
                    TextField("Nombre de la Empresa", text: $dataManager.empresa)
                    TextField("Nombre del Contacto", text: $dataManager.usuario)
                }
                
                Section(header: Text("Logo")) {
                    HStack {
                        if let logoData = dataManager.logoData, let logoImage = UIImage(data: logoData) {
                            Image(uiImage: logoImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        Button(action: { showingImagePicker = true }) {
                            Text(dataManager.logoData == nil ? "Seleccionar Logo" : "Cambiar Logo")
                        }
                    }
                    
                    if dataManager.logoData != nil {
                        Button(role: .destructive, action: {
                            dataManager.logoData = nil
                        }) {
                            Text("Eliminar Logo")
                        }
                    }
                }
                
                Section {
                    Text("Configuración guardada automáticamente")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Configuración PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ulises") {
                        // Cierra la vista
                    }
                    
                    
                }
            }
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: $inputImage)
            }
        }
    }
    
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        let resizedImage = resizeImage(image: inputImage, maxSize: 500)
        dataManager.logoData = resizedImage.pngData() ?? resizedImage.jpegData(compressionQuality: 0.8)
    }
    
    private func resizeImage(image: UIImage, maxSize: CGFloat) -> UIImage {
        let aspectRatio = image.size.width / image.size.height
        let newSize: CGSize
        
        if aspectRatio > 1 {
            newSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
        } else {
            newSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
}
