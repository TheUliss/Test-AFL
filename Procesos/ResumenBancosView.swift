//
//  ResumenBancosView.swift
//  Test AFL
//
//  Created by Ulises Islas on 17/04/25.
//


import SwiftUI

struct ResumenBancosView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var mostrarListaArticulos = false
    @State private var bancoSeleccionado: Int = 0
    
    // Función actualizada para obtener bancos ocupados
    private var bancosOcupados: [Int] {
        dataManager.ordenesEnProceso.compactMap { Int($0.banco ?? "") }
    }
    
    private let todosBancos = Array(1...50)
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Bancos Ocupados (\(bancosOcupados.count))")) {
                    Text(bancosOcupados.map(String.init).joined(separator: ", "))
                }
                
                Section(header: Text("Asignar Nuevo Banco")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                        ForEach(todosBancos, id: \.self) { banco in
                            Button(action: {
                                if !bancosOcupados.contains(banco) {
                                    bancoSeleccionado = banco
                                    mostrarListaArticulos = true
                                }
                            }) {
                                Text("\(banco)")
                                    .frame(width: 40, height: 40)
                                    .background(
                                        bancosOcupados.contains(banco)
                                            ? Color.red.opacity(0.3)
                                            : Color.green.opacity(0.3)
                                    )
                                    .cornerRadius(8)
                            }
                            .disabled(bancosOcupados.contains(banco))
                        }
                    }
                }
            }
            .navigationTitle("Resumen de Bancos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .sheet(isPresented: $mostrarListaArticulos) {
                ListaArticulosParaBancoView(bancoSeleccionado: bancoSeleccionado)
                    .environmentObject(dataManager)
            }
            .onAppear {
                // Forzar actualización al aparecer
                dataManager.objectWillChange.send()
            }
        }
    }
}


/*
struct ResumenBancosView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var mostrarListaArticulos = false
    @State private var bancoSeleccionado: Int = 0
    
    private let bancosDisponibles = Array(1...50)
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Bancos Ocupados (\(dataManager.bancosOcupados().count))")) {
                    Text(dataManager.bancosOcupados().map(String.init).joined(separator: ", "))
                }
                
                Section(header: Text("Asignar Nuevo Banco")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                        ForEach(bancosDisponibles, id: \.self) { banco in
                            Button(action: {
                                if !dataManager.bancosOcupados().contains(banco) {
                                    bancoSeleccionado = banco
                                    mostrarListaArticulos = true
                                }
                            }) {
                                Text("\(banco)")
                                    .frame(width: 40, height: 40)
                                    .background(
                                        dataManager.bancosOcupados().contains(banco)
                                            ? Color.red.opacity(0.3)
                                            : Color.green.opacity(0.3)
                                    )
                                    .cornerRadius(8)
                            }
                            .disabled(dataManager.bancosOcupados().contains(banco))
                        }
                    }
                }
            }
            .navigationTitle("Resumen de Bancos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .sheet(isPresented: $mostrarListaArticulos) {
                ListaArticulosParaBancoView(bancoSeleccionado: bancoSeleccionado)
                    .environmentObject(dataManager)
            }
        }
    }
}*/



/*struct ResumenBancosView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var mostrarSelectorArticulo = false
    @State private var bancoSeleccionado: Int? = nil
    
    private let bancosDisponibles = Array(1...50)
    
    var body: some View {
        NavigationView {
            List {
                // Sección de bancos ocupados (existente)
                Section(header: Text("Bancos Ocupados (\(dataManager.bancosOcupados().count))")) {
                    Text(dataManager.bancosOcupados().map(String.init).joined(separator: ", "))
                }
                
                // Sección de bancos disponibles con acción
                Section(header: Text("Asignar Nuevo Banco")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                        ForEach(bancosDisponibles, id: \.self) { banco in
                            Button(action: {
                                if !dataManager.bancosOcupados().contains(banco) {
                                    bancoSeleccionado = banco
                                    mostrarSelectorArticulo = true
                                }
                            }) {
                                Text("\(banco)")
                                    .frame(width: 40, height: 40)
                                    .background(
                                        dataManager.bancosOcupados().contains(banco)
                                            ? Color.red.opacity(0.3)
                                            : Color.green.opacity(0.3)
                                    )
                                    .cornerRadius(8)
                            }
                            .disabled(dataManager.bancosOcupados().contains(banco))
                        }
                    }
                }
            }
            .navigationTitle("Resumen de Bancos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .sheet(isPresented: $mostrarSelectorArticulo) {
                if let banco = bancoSeleccionado {
                    SelectorArticuloView(dataManager: dataManager, banco: banco)
                }
            }
        }
    }
}
*/

/*
struct SelectorArticuloView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager: DataManager
    let banco: Int
    
    @State private var ordenTemporal = Orden(
        nombre: "",
        clasificacion: .proceso,
        banco: "",
        articuloNombre: "",
        articuloDescripcion: "",
        tiempoLimiteHoras: 24
    )
    
    var body: some View {
        NavigationView {
            List(dataManager.articulos) { articulo in
                NavigationLink {
                    EditarOrdenView(
                        orden: Orden(
                            nombre: "Nueva orden",
                            clasificacion: .proceso,
                            banco: "\(banco)", // Banco pre-seleccionado
                            articuloNombre: articulo.nombre,
                            articuloDescripcion: articulo.descripcion,
                            tiempoLimiteHoras: 24
                        ),
                        articulo: articulo
                    )
                    .environmentObject(dataManager)
                } label: {
                    VStack(alignment: .leading) {
                        Text(articulo.nombre)
                            .font(.headline)
                        Text(articulo.descripcion)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Selecciona Artículo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}



struct EditarArticuloConBancoView: View {
    @EnvironmentObject var dataManager: DataManager
    var articulo: Articulo
    let bancoSeleccionado: Int
    @State private var noWeek: String = ""
    @Environment(\.dismiss) var dismiss // For going back
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información del Artículo")) {
                    Text(articulo.nombre)
                    Text(articulo.descripcion)
                }
                
                Section(header: Text("Nueva Orden para Banco \(bancoSeleccionado)")) {
                    TextField("Número de Orden", text: $noWeek)
                        .keyboardType(.numberPad)
                    
                    Button("Agregar Orden") {
                        agregarOrden()
                    }
                    .disabled(noWeek.isEmpty)
                }
                
                Section(header: Text("Órdenes Existentes")) {
                    ForEach(articulo.ordenes) { orden in
                        VStack(alignment: .leading) {
                            Text(orden.nombre)
                            if let banco = orden.banco {
                                Text("Banco: \(banco)")
                                    .font(.footnote)
                                    .foregroundColor(.blue)
                            }
                            Text("Semana: \(orden.noWeek ?? "-")")
                                .font(.footnote)
                        }
                    }
                }
            }
            .navigationTitle("Agregar Orden")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Obtener semana actual (formato 1-52)
                let calendar = Calendar.current
                let weekOfYear = calendar.component(.weekOfYear, from: Date())
                noWeek = String(weekOfYear)
            }
        }
    }
    
    private func agregarOrden() {
        let nuevaOrden = Orden(
            nombre: noWeek,
            clasificacion: .proceso,
            banco: "\(bancoSeleccionado)",
            noWeek: noWeek,
            articuloNombre: articulo.nombre,
            articuloDescripcion: articulo.descripcion,
            tiempoLimiteHoras: 24 // Valor por defecto
        )
        
        if let index = dataManager.articulos.firstIndex(where: { $0.id == articulo.id }) {
            dataManager.articulos[index].ordenes.append(nuevaOrden)
            dataManager.guardarArticulos()
            noWeek = "" // Limpiar campo después de agregar
        }
    }
}
*/

///---<
///
///
struct ListaArticulosParaBancoView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    let bancoSeleccionado: Int
    @State private var articuloSeleccionado: Articulo? = nil
    
    var body: some View {
        NavigationView {
            List(dataManager.articulos) { articulo in
                Button(action: {
                    articuloSeleccionado = articulo
                }) {
                    VStack(alignment: .leading) {
                        Text(articulo.nombre)
                            .font(.headline)
                        Text(articulo.descripcion)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("\(articulo.ordenes.count) órdenes")
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Seleccionar Artículo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") { dismiss() }
                }
            }
          /*  .sheet(item: $articuloSeleccionado) { articulo in
                EditarArticuloConBancoView(articulo: articulo, bancoSeleccionado: bancoSeleccionado)
                    .environmentObject(dataManager)
            }*/
            .sheet(item: $articuloSeleccionado) { articulo in
                EditarOrdenConBancoView(articulo: articulo, bancoSeleccionado: bancoSeleccionado)
                    .environmentObject(dataManager)
            }
        }
    }
}

struct EditarOrdenConBancoView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    let articulo: Articulo
    let bancoSeleccionado: Int
    
    @State private var numeroOrden: String = ""
    @State private var noWeek: String = ""
    @State private var tiempoLimiteHoras: String = "24"
    @State private var ordenesTemporales: [Orden] = []
    @State private var mostrarAlertaCancelar = false
    
    @FocusState private var focusedField: Field?
    enum Field: Hashable { case numeroOrden, noWeek, tiempoLimiteHoras }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información del Artículo")) {
                    Text(articulo.nombre)
                    Text(articulo.descripcion)
                }
                
                Section(header: Text("Nueva Orden")) {
                    // Banco seleccionado (solo lectura)
                    HStack {
                        Text("Banco:")
                        Spacer()
                        Text("\(bancoSeleccionado)")
                            .foregroundColor(.blue)
                            .fontWeight(.bold)
                    }
                    
                    // Campo número de orden
                    TextField("Número de Orden", text: $numeroOrden)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .numeroOrden)
                    
                    // Campo semana
                    TextField("Semana", text: $noWeek)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .noWeek)
                    
                    // Campo tiempo límite
                    TextField("Tiempo Límite (horas)", text: $tiempoLimiteHoras)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .tiempoLimiteHoras)
                    
                    Button(action: agregarOrdenTemporal) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Agregar a lista")
                        }
                    }
                    .disabled(numeroOrden.isEmpty || noWeek.isEmpty || tiempoLimiteHoras.isEmpty)
                }
                
                // Sección de órdenes pendientes por guardar
                if !ordenesTemporales.isEmpty {
                    Section(header: Text("Órdenes a Guardar")) {
                        List {
                            ForEach(ordenesTemporales.indices, id: \.self) { index in
                                VStack(alignment: .leading) {
                                    Text("Orden: \(ordenesTemporales[index].nombre)")
                                    Text("Banco: \(ordenesTemporales[index].banco ?? "")")
                                        .font(.footnote)
                                    Text("Semana: \(ordenesTemporales[index].noWeek ?? "") • Límite: \(ordenesTemporales[index].tiempoLimiteHoras) hrs")
                                        .font(.footnote)
                                }
                            }
                            .onDelete(perform: eliminarOrdenTemporal)
                        }
                    }
                }
                
                // Sección de órdenes existentes
                if !articulo.ordenes.isEmpty {
                    Section(header: Text("Órdenes Existentes")) {
                        List {
                            ForEach(articulo.ordenes.indices, id: \.self) { index in
                                ordenRow(orden: articulo.ordenes[index])
                            }
                            .onDelete(perform: eliminarOrdenExistente)
                        }
                    }
                }
            }
            .navigationTitle("Nueva Orden")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        if !ordenesTemporales.isEmpty {
                            mostrarAlertaCancelar = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guardarOrdenes()
                    }
                    .disabled(ordenesTemporales.isEmpty)
                }
            }
            .alert("¿Descartar cambios?", isPresented: $mostrarAlertaCancelar) {
                Button("Descartar", role: .destructive) { dismiss() }
                Button("Continuar editando", role: .cancel) {}
            }
            .onAppear {
                // Configurar semana actual
                let weekOfYear = Calendar.current.component(.weekOfYear, from: Date())
                noWeek = String(weekOfYear)
                
                // Inicializar con órdenes existentes (solo para visualización)
                ordenesTemporales = []
            }
        }
    }
    
    // Fila para mostrar orden
    private func ordenRow(orden: Orden) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(orden.nombre)
                Spacer()
                Text("Banco: \(orden.banco ?? "-")")
                    .foregroundColor(.blue)
            }
            HStack {
                Text("Semana: \(orden.noWeek ?? "-")")
                Spacer()
                Text("Límite: \(orden.tiempoLimiteHoras) hrs")
            }
            .font(.footnote)
            .foregroundColor(.gray)
        }
    }
    
    private func agregarOrdenTemporal() {
        guard let tiempo = Int(tiempoLimiteHoras), tiempo > 0 else { return }
        
        let nuevaOrden = Orden(
            nombre: numeroOrden,
            clasificacion: .proceso,
            banco: "\(bancoSeleccionado)",
            noWeek: noWeek,
            articuloNombre: articulo.nombre,
            articuloDescripcion: articulo.descripcion,
            tiempoLimiteHoras: tiempo
        )
        
        ordenesTemporales.append(nuevaOrden)
        
        // Limpiar campos
        numeroOrden = ""
        tiempoLimiteHoras = "24"
        focusedField = .numeroOrden
    }
    
    private func eliminarOrdenTemporal(at offsets: IndexSet) {
        ordenesTemporales.remove(atOffsets: offsets)
    }
    
    private func eliminarOrdenExistente(at offsets: IndexSet) {
        // Solo marcamos para eliminación, se aplicará al guardar
        var articuloModificado = articulo
        articuloModificado.ordenes.remove(atOffsets: offsets)
        
        if let index = dataManager.articulos.firstIndex(where: { $0.id == articulo.id }) {
            dataManager.articulos[index] = articuloModificado
            dataManager.guardarArticulos()
        }
    }
    
    private func guardarOrdenes() {
        var articuloModificado = articulo
        articuloModificado.ordenes.append(contentsOf: ordenesTemporales)
        
        if let index = dataManager.articulos.firstIndex(where: { $0.id == articulo.id }) {
            dataManager.articulos[index] = articuloModificado
            dataManager.guardarArticulos()
            dismiss()
        }
    }
}

/*
struct EditarOrdenConBancoView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    let articulo: Articulo
    let bancoSeleccionado: Int
    
    // Campos de la orden
    @State private var numeroOrden: String = ""
    @State private var noWeek: String = ""
    @State private var tiempoLimiteHoras: String = "24"
    @State private var ordenes: [Orden] = []
    
    // Manejo de foco
    @FocusState private var focusedField: Field?
    enum Field: Hashable {
        case numeroOrden, noWeek, tiempoLimiteHoras
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Sección de información del artículo
                Section(header: Text("Artículo")) {
                    Text(articulo.nombre)
                    Text(articulo.descripcion)
                }
                
                // Sección de datos de la orden (como solicitaste)
                ordenesSection()
                
                // Sección de órdenes existentes
                if !ordenes.isEmpty {
                    Section(header: Text("Órdenes Existentes")) {
                        List {
                            ForEach(ordenes.indices, id: \.self) { index in
                                ordenRow(index: index)
                            }
                            .onDelete(perform: eliminarOrden)
                        }
                    }
                }
            }
            .navigationTitle("Nueva Orden")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guardarCambios()
                    }
                    .disabled(numeroOrden.isEmpty)
                }
            }
            .onAppear {
                // Configurar semana actual al aparecer
                let calendar = Calendar.current
                let weekOfYear = calendar.component(.weekOfYear, from: Date())
                noWeek = String(weekOfYear)
                
                // Cargar órdenes existentes
                ordenes = articulo.ordenes
            }
        }
    }
    
    // Sección de órdenes (adaptada a tus requerimientos)
    private func ordenesSection() -> some View {
        Section(header: Text("Datos de la Orden")) {
            // Mostrar banco seleccionado (solo lectura)
            HStack {
                Text("Banco asignado:")
                Spacer()
                Text("\(bancoSeleccionado)")
                    .foregroundColor(.blue)
            }
            
            // Campo para número de orden (numérico)
            TextField("Número de Orden", text: $numeroOrden)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .numeroOrden)
                .onSubmit { focusedField = .noWeek }
            
            // Campo para semana (numérico)
            TextField("Semana", text: $noWeek)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .noWeek)
                .onSubmit { focusedField = .tiempoLimiteHoras }
            
            // Campo para tiempo límite (numérico)
            TextField("Tiempo Límite (horas)", text: $tiempoLimiteHoras)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .tiempoLimiteHoras)
            
            Button(action: agregarNuevaOrden) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Agregar Orden")
                }
            }
            .disabled(numeroOrden.isEmpty || noWeek.isEmpty || tiempoLimiteHoras.isEmpty)
        }
    }
    
    // Fila para orden existente
    private func ordenRow(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Orden: \(ordenes[index].nombre)")
                Spacer()
                if let banco = ordenes[index].banco {
                    Text("Banco: \(banco)")
                        .foregroundColor(.blue)
                }
            }
            
            HStack {
                Text("Semana: \(ordenes[index].noWeek ?? "-")")
                Spacer()
                Text("Límite: \(ordenes[index].tiempoLimiteHoras) hrs")
            }
            .font(.footnote)
            .foregroundColor(.gray)
        }
    }
    
    private func agregarNuevaOrden() {
        guard !numeroOrden.isEmpty,
              let tiempo = Int(tiempoLimiteHoras),
              tiempo > 0 else {
            return
        }
        
        let nuevaOrden = Orden(
            nombre: numeroOrden,
            clasificacion: .proceso,
            banco: "\(bancoSeleccionado)",
            noWeek: noWeek,
            articuloNombre: articulo.nombre,
            articuloDescripcion: articulo.descripcion,
            tiempoLimiteHoras: tiempo
        )
        
        ordenes.append(nuevaOrden)
        
        // Limpiar campos después de agregar
        numeroOrden = ""
        tiempoLimiteHoras = "24" // Restablecer valor por defecto
        
        // Mantener el foco en el campo de número de orden
        focusedField = .numeroOrden
    }
    
    private func eliminarOrden(at offsets: IndexSet) {
        ordenes.remove(atOffsets: offsets)
    }
    
    private func guardarCambios() {
        if let index = dataManager.articulos.firstIndex(where: { $0.id == articulo.id }) {
            dataManager.articulos[index].ordenes = ordenes
            dataManager.guardarArticulos()
            dismiss()
        }
    }
}

*/
