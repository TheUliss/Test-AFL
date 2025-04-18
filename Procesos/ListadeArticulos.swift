//
//  GestionarInventarioView.swift
//  Control de Piso
//
//  Created by Uls on 24/01/25.
//

//MARK: GESTION DE ARTICULOS
import SwiftUI
import MobileCoreServices

struct GestionarInventarioView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var articuloSeleccionado: Articulo? = nil
    @State private var mostrandoEditor = false
    @State private var ListaMaterialesVer = false
    @State private var mostrarConfirmacion = false
    @State private var seleccionados: Set<UUID> = [] // Almacena IDs de artículos seleccionados
    @State private var modoSeleccion = false // Controla el modo de selección múltiple
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dataManager.articulos) { articulo in
                    HStack {
                        // Mostrar checkbox solo en modo selección
                        if modoSeleccion {
                            Image(systemName: seleccionados.contains(articulo.id) ? "checkmark.square.fill" : "square")
                                .foregroundColor(.blue)
                                .onTapGesture {
                                    toggleSeleccion(articulo: articulo)
                                }
                        }
                        
                        Button(action: {
                            if modoSeleccion {
                                toggleSeleccion(articulo: articulo)
                            } else {
                                articuloSeleccionado = articulo
                                mostrandoEditor = true
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(articulo.nombre)
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Text(articulo.descripcion)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("(\(articulo.ordenes.count) \(articulo.ordenes.count == 1 ? "órden" : "órdenes"))")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                                
                                ForEach(articulo.materiales) { material in
                                    HStack {
                                        Text("- \(material.nombre)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(material.cantidadRequerida) \(material.cantidadRequerida == 1 ? "pieza" : "piezas")")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive, action: {
                            mostrarConfirmacion = true
                            articuloSeleccionado = articulo
                        }) {
                            Label("Eliminar", systemImage: "trash.fill")
                        }
                    }
                }
                .onMove(perform: moverArticulos)
            }
            .navigationTitle("Lista de Artículos")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: HStack {
                    Button(action: {
                        ListaMaterialesVer = true
                    }) {
                        Image(systemName: "folder.fill")
                    }
                    
                    if modoSeleccion {
                        Button(action: {
                            seleccionarTodos()
                        }) {
                            Text(seleccionados.count == dataManager.articulos.count ? "Deseleccionar" : "Seleccionar")
                        }
                    } else {
                        EditButton()
                    }
                },
                trailing: HStack {
                    if modoSeleccion {
                        Button(action: {
                            eliminarSeleccionados()
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(seleccionados.isEmpty ? .gray : .red)
                        }
                        .disabled(seleccionados.isEmpty)
                        
                        Button("Listo") {
                            modoSeleccion = false
                            seleccionados.removeAll()
                        }
                    } else {
                        Button(action: {
                            articuloSeleccionado = nil
                            mostrandoEditor = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                        }
                        
                        Button(action: {
                            modoSeleccion = true
                        }) {
                            Text("Seleccionar")
                        }
                    }
                }
            )
            .sheet(isPresented: $mostrandoEditor) {
                AgregarArticuloView(articuloEditable: $articuloSeleccionado)
            }
            .sheet(isPresented: $ListaMaterialesVer) {
                ListaMaterialesView()
                    .environmentObject(dataManager)
            }
            .confirmationDialog(
                "¿Eliminar \(articuloSeleccionado != nil ? "este artículo" : "los artículos seleccionados")?",
                isPresented: $mostrarConfirmacion,
                titleVisibility: .visible
            ) {
                Button("Eliminar", role: .destructive) {
                    if let articulo = articuloSeleccionado {
                        eliminarArticulo(articulo)
                    } else {
                        eliminarSeleccionados()
                    }
                }
                Button("Cancelar", role: .cancel) {}
            }
        }
    }
    
    // Función para alternar selección de un artículo
    private func toggleSeleccion(articulo: Articulo) {
        if seleccionados.contains(articulo.id) {
            seleccionados.remove(articulo.id)
        } else {
            seleccionados.insert(articulo.id)
        }
    }
    
    // Función para seleccionar/deseleccionar todos
    private func seleccionarTodos() {
        if seleccionados.count == dataManager.articulos.count {
            seleccionados.removeAll()
        } else {
            seleccionados = Set(dataManager.articulos.map { $0.id })
        }
    }
    
    // Función para eliminar artículos seleccionados
    private func eliminarSeleccionados() {
        dataManager.articulos.removeAll { seleccionados.contains($0.id) }
        seleccionados.removeAll()
        mostrarConfirmacion = false
    }
    
    // Función para eliminar un artículo individual
    private func eliminarArticulo(_ articulo: Articulo) {
        if let index = dataManager.articulos.firstIndex(where: { $0.id == articulo.id }) {
            dataManager.articulos.remove(at: index)
        }
        articuloSeleccionado = nil
    }
    
    // Función para mover artículos
    private func moverArticulos(from source: IndexSet, to destination: Int) {
        dataManager.articulos.move(fromOffsets: source, toOffset: destination)
    }
}



