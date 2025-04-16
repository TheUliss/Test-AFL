//
//  EditarOrdenView.swift
//  Control de Piso
//
//  Created by Uli on 24/01/25.
//


//MARK: EDITAR ORDEN

import SwiftUI
import WidgetKit

struct EditarOrdenView: View {
    @EnvironmentObject var dataManager: DataManager
    @State var orden: Orden
    var articulo: Articulo
    @Environment(\.presentationMode) var presentationMode

    @State private var materiales: [Material] = []
    @State private var notaStandby: String = ""
    @State private var noWeek: String = ""
    @State private var showValidationError = false

    var body: some View {
        NavigationView {
            Form {
                ArticuloSection(articulo: articulo)
                InformacionOrdenSection(
                    orden: $orden,
                    noWeek: $noWeek,
                    notaStandby: $notaStandby
                )
                
                Button(action: guardarCambios) {
                    Text("Guardar Cambios")
                        .bold()
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundColor(.white)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .padding(.top, 12)
                MaterialesSection(materiales: materiales)

            }
            .navigationTitle("Editar Orden")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .onAppear {
                cargarMateriales()
                noWeek = orden.noWeek ?? ""
                notaStandby = orden.nota ?? ""
                
            }
            .alert(isPresented: $showValidationError) {
                Alert(
                    title: Text("Error de validación"),
                    message: Text("Asegúrese de completar todos los campos requeridos."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func cargarMateriales() {
        materiales = articulo.materiales
    }
        
    
    private func guardarCambios() {
        // Validación
        if !validarCampos() {
            showValidationError = true
            return
        }
        
        asignarValores()
        actualizarDataManager()
        
        // Actualización sincronizada
        DispatchQueue.main.async {
            // 1. Guardar cambios en el DataManager
            dataManager.objectWillChange.send()
            
            // 2. Guardar para el widget
            dataManager.guardarOrdenesParaWidget()
            
            // 3. Forzar actualización del widget usando el kind correcto
            WidgetCenter.shared.reloadTimelines(ofKind: "OrderWidget")
            
            // 4. Cerrar la vista
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func validarCampos() -> Bool {
        // Validar semana
        if noWeek.isEmpty {
            return false
        }
        // Validar nota para Stand-by
        if orden.clasificacion == .Stb && notaStandby.isEmpty {
            return false
        }
        // Validar campo Banco para Proceso
        if orden.clasificacion == .proceso && (orden.banco?.isEmpty ?? true) {
            return false
        }
        return true
        
    }
    private func asignarValores() {
        orden.noWeek = noWeek
        
        if orden.clasificacion == .Stb {
            orden.nota = notaStandby
        }
        if orden.clasificacion == .proceso {
            orden.banco = orden.banco ?? ""
        }
        // No sobrescribir fecha si ya fue modificada en el DatePicker
        if orden.fechaUltimaModificacion == nil {
            orden.fechaUltimaModificacion = Date() // Asigna fecha actual solo si no existe
        }
    }

    private func actualizarDataManager() {
        if let indexArticulo = dataManager.articulos.firstIndex(where: { $0.id == articulo.id }),
           let indexOrden = dataManager.articulos[indexArticulo].ordenes.firstIndex(where: { $0.id == orden.id }) {
            dataManager.articulos[indexArticulo].ordenes[indexOrden] = orden
        }
    }
}

struct ArticuloSection: View {
    var articulo: Articulo

    var body: some View {
        GroupBox {
            HStack(spacing: 12) {
                Image(systemName: "cube.fill") // Nueva imagen más representativa
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(articulo.nombre)
                        .font(.title3)
                        .bold()
                        .foregroundColor(.blue)

                    Text(articulo.descripcion)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2) // Evita que ocupe mucho espacio
                }

                Spacer() // Alinea todo correctamente a la izquierda
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

struct InformacionOrdenSection: View {
    @Binding var orden: Orden
    @Binding var noWeek: String
    @Binding var notaStandby: String

    @State private var mostrandoDatePicker = false // Controla la visibilidad del DatePicker
    @State private var bancoValue: Int = 1 // Valor inicial del banco
    @State private var tiempolimite: Int = 1

    var body: some View {
        GroupBox(label: Text("Información de la Orden").font(.headline).foregroundColor(.green)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Job:")
                        .font(.body)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(orden.nombre)
                        .fontWeight(.semibold)
                        .font(.body)
                        .foregroundColor(.primary)
                }

                Picker("Clasificación", selection: $orden.clasificacion) {
                    ForEach(Clasificacion.allCases, id: \.self) { clasificacion in
                        Text(clasificacion.rawValue.capitalized)
                            .tag(clasificacion)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.top, 8)
                .onChange(of: orden.clasificacion) { oldValue, newValue in
                    if newValue == .proceso {
                        // Establecer el valor predeterminado del banco si es nil o está vacío
                        if orden.banco == nil || orden.banco?.isEmpty == true {
                            orden.banco = "1"
                            bancoValue = 1
                        }
                        if orden.fechaInicioProceso == nil {
                            orden.fechaInicioProceso = Date() // Registrar fecha de inicio
                        }
                    }
                }

                // TextField para "Semana" con validación
                HStack {
                    Text("Semana #:")
                        .font(.body)
                        .foregroundColor(.gray)
                    Spacer()
                    TextField("# Semana", text: Binding(
                        get: { noWeek },
                        set: { newValue in
                            // Filtra solo números del 1 al 52
                            if newValue.isEmpty {
                                noWeek = newValue
                            } else if let numero = Int(newValue), (1...52).contains(numero) {
                                noWeek = newValue
                            }
                        }
                    ))
                    .keyboardType(.numberPad) // Teclado numérico
                    .multilineTextAlignment(.trailing) // Alinear el texto a la derecha
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    ) // Fondo gris claro
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.5), lineWidth: 1) // Borde azul
                    )
                    .padding(.horizontal, 4) // Espaciado horizontal
                }
                .padding(.top, 8)

                // TextField para "Stand-by" con diseño mejorado
                if orden.clasificacion == .Stb {
                    TextField("Nota para Stand-by", text: $notaStandby)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.top, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1)) // Fondo gris claro
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.5), lineWidth: 1) // Borde azul
                        )
                        .padding(.horizontal, 4) // Espaciado horizontal
                }
                
                if orden.clasificacion == .proceso {
                    HStack {
                        Text("Estacion:")
                            .font(.body)
                            .foregroundColor(.gray)
                        Spacer()
                        
                        // TextField para la entrada numérica del banco
                        TextField("", value: $bancoValue, formatter: NumberFormatter())
                            .keyboardType(.numberPad) // Teclado numérico
                            .multilineTextAlignment(.trailing) // Alinear el texto a la derecha
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .frame(width: 80) // Ancho fijo para el TextField
                            
                            .onChange(of: bancoValue) { _, newValue in
                                // Solo usar newValue
                                if newValue >= 1 && newValue <= 100 {
                                    orden.banco = "\(newValue)"
                                } else {
                                    bancoValue = Int(orden.banco ?? "1") ?? 1
                                }
                            }
                            
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.1))
                            ) // Fondo gris claro
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue.opacity(0.5), lineWidth: 1) // Borde azul
                            )
                            .padding(.horizontal, 4) // Espaciado horizontal
                    }
                    
                    HStack {
                        Text("Tiempo Limite: (hrs)")
                            .font(.body)
                            .foregroundColor(.gray)
                        Spacer()
                        
                        TextField("", value: $tiempolimite, formatter: NumberFormatter())
                            .keyboardType(.numberPad) // Teclado numérico
                            .multilineTextAlignment(.trailing) // Alinear el texto a la derecha
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .frame(width: 80) // Ancho fijo para el TextField
                            .onChange(of: tiempolimite) { _, newValue in
                                orden.tiempoLimiteHoras = newValue // Actualizar el valor del tiempo límite en la orden
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.1))
                            ) // Fondo gris claro
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue.opacity(0.5), lineWidth: 1) // Borde azul
                            )
                            .padding(.horizontal, 4) // Espaciado horizontal
                    }
                    
                    if let fechaInicio = orden.fechaInicioProceso {
                        let tiempoTranscurrido = Date().timeIntervalSince(fechaInicio)
                        let horas = Int(tiempoTranscurrido) / 3600
                        let minutos = (Int(tiempoTranscurrido) % 3600 / 60)

                        Text("Tiempo en Proceso: \(horas)h \(minutos)m")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }

                    Button(action: {
                        mostrandoDatePicker.toggle()
                    }) {
                        HStack {
                            Text("Fecha: \(orden.fechaInicioProceso ?? Date(), formatter: dateFormatter)")
                            Spacer()
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                        }
                        .font(.body)
                        .foregroundColor(.primary)
                    }

                    if mostrandoDatePicker {
                        DatePicker(
                            "Fecha y Hora",
                            selection: Binding(
                                get: { orden.fechaInicioProceso ?? Date() },
                                set: { orden.fechaInicioProceso = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .onChange(of: orden.fechaInicioProceso) { oldValue, newValue in
                            mostrandoDatePicker = false // Cierra el DatePicker al seleccionar una fecha
                        }
                    }
                }

                if orden.clasificacion == .terminada {
                    Button(action: {
                        mostrandoDatePicker.toggle()
                    }) {
                        HStack {
                            Text("Fecha: \(orden.fechaUltimaModificacion ?? Date(), formatter: dateFormatter)")
                            Spacer()
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                        }
                        .font(.body)
                        .foregroundColor(.primary)
                    }

                    if mostrandoDatePicker {
                        DatePicker(
                            "Fecha y Hora",
                            selection: Binding(
                                get: { orden.fechaUltimaModificacion ?? Date() },
                                set: { orden.fechaUltimaModificacion = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .onChange(of: orden.fechaUltimaModificacion) { oldValue, newValue in
                            mostrandoDatePicker = false // Cierra el DatePicker al seleccionar una fecha
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .onAppear {
            // Inicializar el valor del banco al aparecer la vista
            bancoValue = Int(orden.banco ?? "1") ?? 1
            tiempolimite = orden.tiempoLimiteHoras
        }
    }

    // Formateador para la fecha
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

struct MaterialesSection: View {
    var materiales: [Material]

    var body: some View {
        if !materiales.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("Componentes")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.bottom, 8)

                ForEach(materiales) { material in
                    HStack(alignment: .top) {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.blue)
                            .frame(width: 20, height: 20)
                        Text(material.nombre)
                            .font(.body)
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(material.cantidadRequerida)")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .padding(.trailing, 8)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        }
    }
}

