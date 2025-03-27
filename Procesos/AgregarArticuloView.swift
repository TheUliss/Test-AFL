//
//  AgregarArticuloView.swift
//  Control de Piso
//
//  Created by Ulises Islas on 24/01/25.
//

//MARK: AGREGAR NUEVOS ARTICULOS
import SwiftUI

// Formatter global
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
}()

struct AgregarArticuloView: View {
    @EnvironmentObject var dataManager: DataManager
    @Binding var articuloEditable: Articulo?
    @State private var nombreArticulo = ""
    @State private var descripcionArticulo = ""
    @State private var materiales: [Material] = []
    @State private var ordenes: [Orden] = []
    @State private var mostrarError: Bool = false
    @State private var mostrarAlertaBorrar: Bool = false
    @State private var indiceAEliminar: Int?
    @State private var numeroOrden = ""
    @State private var noWeek = ""
    @State private var tiempoLimiteHoras = "" // 🔹 Nuevo campo para capturar el tiempo límite
    @State private var editMode: EditMode = .inactive // Agrega esta línea
    // Variable de estado para controlar el foco
    @FocusState private var focusedField: Field?
    
    // Enumeración para identificar los campos de texto
        enum Field: Hashable {
            case numeroOrden
            case noWeek
            case tiempoLimiteHoras
        }
    
    var body: some View {
        Form {
            nombreArticuloSection()
            componentesSection()
            guardarButton()
            ordenesSection()
        }
        .navigationTitle("Agregar Artículo")
        .navigationBarItems(trailing: EditButton()) // Botón para habilitar edición
        .environment(\.editMode, $editMode) // Vincula el estado de edición
        .onAppear {
            cargarArticulo()
        }
        .alert(isPresented: $mostrarError) {
            Alert(
                title: Text("Error"),
                message: Text("El artículo debe tener al menos un componente y una orden para guardarse."),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $mostrarAlertaBorrar) {
            confirmacionEliminarAlert()
        }
    }
}

// MARK: - Sección: Nombre del Artículo

extension AgregarArticuloView {
   
    private func nombreArticuloSection() -> some View {
        Section(header: Text("Información del Artículo")) {
            // Campo para el nombre del artículo
            TextField("Nombre", text: Binding(
                get: { nombreArticulo },
                set: { nombreArticulo = $0.uppercased() }
            ))
            .autocapitalization(.allCharacters) // Opcional: Fuerza el teclado a mayúsculas

            // Campo para la descripción del artículo
            TextField("Descripción", text: Binding(
                get: { descripcionArticulo },
                set: { descripcionArticulo = $0.uppercased() }
            ))
            .autocapitalization(.allCharacters) // Opcional: Fuerza el teclado a mayúsculas
        }
    }
    
    // MARK: - Sección: Componentes
    
    private func componentesSection() -> some View {
        Section(header: Text("Componentes del Artículo")) {
            List {
                ForEach(materiales.indices, id: \.self) { index in
                    HStack {
                        TextField("Componente", text: $materiales[index].nombre)

                        TextField("Cantidad", text: Binding(
                            get: { "\(materiales[index].cantidadRequerida)" },
                            set: { newValue in
                                if let cantidad = Int(newValue), (1...3000).contains(cantidad) {
                                    materiales[index].cantidadRequerida = cantidad
                                }
                            }
                        ))
                        .keyboardType(.numberPad)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .onDelete(perform: { indexSet in materiales.remove(atOffsets: indexSet) })
            }

            Button("Agregar Componente") {
                materiales.append(Material(nombre: "", cantidadDisponible: 0, cantidadRequerida: 1))
            }
        }
    }

    

    private func componenteRow(index: Int) -> some View {
        HStack {
            TextField("Componente", text: $materiales[index].nombre)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: .infinity) // Asegura que el campo se ajuste
            
            Spacer()
            
            Stepper("QTY: \(materiales[index].cantidadRequerida)", value: $materiales[index].cantidadRequerida, in: 0...100)
            
            Button(action: {
                indiceAEliminar = index
                mostrarAlertaBorrar = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4) // Aumenta el espacio vertical entre filas
    }

    private func guardarButton() -> some View {
        Section {
            Button(action: {
                guardarArticulo()
            }) {
                Text("Guardar Artículo")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.green)
                    .cornerRadius(10)
            }
        }
    }
    // MARK: - Sección: Órdenes
    
    private func ordenesSection() -> some View {
            Section(header: Text("Órdenes de Producción")) {
                HStack {
                    TextField("Orden", text: $numeroOrden)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .numeroOrden) // Vincular con el foco
                        .onSubmit {
                                focusedField = .noWeek // Mover el foco al siguiente campo
                            }
                    TextField("Semana", text: $noWeek)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .noWeek) // Vincular con el foco
                        .onSubmit {
                                focusedField = .tiempoLimiteHoras // Mover el foco al siguiente campo
                            }
                    TextField("(hrs)", text: $tiempoLimiteHoras) // 🔹 Nuevo campo de entrada
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .tiempoLimiteHoras) // Vincular con el foco
                    
                    Button("Agregar Orden") {
                        agregarNuevaOrden()
                        focusedField = .numeroOrden
                    }
                    .disabled(numeroOrden.isEmpty || noWeek.isEmpty || tiempoLimiteHoras.isEmpty)
                }

                .padding(.bottom, 8  )
                // Lista de órdenes existentes
                if ordenes.isEmpty {
                    Text("Debe agregar al menos una orden.")
                        .foregroundColor(.red)
                }
                List {
                    ForEach(ordenes.indices, id: \.self) { index in
                        ordenRow(index: index)
                    }
                    .onMove(perform: moverOrden) // Habilitar reordenamiento
                }
            }
        }
        
    
    private func moverComponente(from source: IndexSet, to destination: Int) {
    materiales.move(fromOffsets: source, toOffset: destination)
    }

    private func moverOrden(from source: IndexSet, to destination: Int) {
    ordenes.move(fromOffsets: source, toOffset: destination)
    }

    private func ordenRow(index: Int) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(ordenes[index].nombre)
                Spacer()
               // Text(ordenes[index].tiempoLimiteHoras)
               // Spacer()
                Text("Fecha Moficacion: \(ordenes[index].fechaUltimaModificacion ?? Date(), formatter: dateFormatter)")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            HStack {
                Spacer()
                Text("Num. Semana: \(ordenes[index].noWeek ?? "")")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            Button(action: {
                indiceAEliminar = index + materiales.count // Ajustar el índice para órdenes
                mostrarAlertaBorrar = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Alertas
    private func confirmacionEliminarAlert() -> Alert {
        Alert(
            title: Text("Confirmar eliminación"),
            message: Text("¿Estás seguro de que deseas eliminar este elemento?"),
            primaryButton: .destructive(Text("Eliminar")) {
                if let indice = indiceAEliminar {
                    eliminarElementoEnIndice(indice)
                }
            },
            secondaryButton: .cancel()
        )
    }

    private func eliminarElementoEnIndice(_ indice: Int) {
        // Verifica si el índice pertenece a materiales o a órdenes
        if indice < materiales.count {
            materiales.remove(at: indice)
        } else {
            let indiceOrden = indice - materiales.count
            if indiceOrden < ordenes.count {
                ordenes.remove(at: indiceOrden)
            }
        }
    }
    
   private func cargarArticulo() {
            guard let articulo = articuloEditable else { return }
            nombreArticulo = articulo.nombre
            descripcionArticulo = articulo.descripcion // Cargar la descripción del artículo
            materiales = articulo.materiales
            ordenes = articulo.ordenes
        }
    
    private func agregarNuevaOrden() {
        if let tiempo = Int(tiempoLimiteHoras), tiempo > 0, !numeroOrden.isEmpty, !noWeek.isEmpty {
            let nuevaOrden = Orden(
                id: UUID(),
                nombre: numeroOrden,
                clasificacion: .revision,
                fechaUltimaModificacion: Date(),
                noWeek: noWeek,
                articuloNombre: "Nombre Articulo",
                articuloDescripcion: "Descripción.",
                tiempoLimiteHoras: tiempo // 🔹 Guardar el valor ingresado
            )
            ordenes.append(nuevaOrden)
            numeroOrden = ""
            noWeek = ""
            tiempoLimiteHoras = ""
            
        } else {
            mostrarError = true
        }
    }
    
    private func guardarArticulo() {
            if sePuedeGuardar() {
                let nuevoArticulo = Articulo(
                    nombre: nombreArticulo,
                    descripcion: descripcionArticulo, // Guardar la descripción
                    materiales: materiales,
                    ordenes: ordenes
                )
                if let index = dataManager.articulos.firstIndex(where: { $0.id == articuloEditable?.id }) {
                    dataManager.articulos[index] = nuevoArticulo
                } else {
                    dataManager.articulos.append(nuevoArticulo)
                }
                limpiarFormulario()
            } else {
                mostrarError = true
            }
        }
        
        private func limpiarFormulario() {
            nombreArticulo = ""
            descripcionArticulo = "" // Limpiar el campo de descripción
            materiales = []
            ordenes = []
        }
    private func sePuedeGuardar() -> Bool {
            return !materiales.isEmpty && !ordenes.isEmpty
        }
    }

