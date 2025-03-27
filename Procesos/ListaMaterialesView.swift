//
//  ListaMaterialesView.swift
//  Control de Piso
//
//  Created by Ulises Islas on 24/01/25.
//
    //MARK: DESCRIPCION DE MATERIALES
  

struct ListaMaterialesView: View {
        @EnvironmentObject var dataManager: DataManager
        @State private var searchText: String = ""
        @State private var materialesFiltrados: [Material] = []
        
        var body: some View {
            NavigationView {
                VStack(spacing: 0) { // Espaciado reducido entre secciones
                    // Buscador
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Buscar material", text: $searchText)
                            .onChange(of: searchText) { _, newValue in
                                filtrarMateriales()
                            }
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Lista de materiales
                    List {
                        Section(header: Text("Lista de Materiales").font(.headline)) {
                            ForEach(materialesFiltrados, id: \.id) { material in
                                NavigationLink(destination: EditarMaterialView(material: material)) {
                                    HStack(spacing: 10) { // Espaciado reducido
                                        Text(material.nombre)
                                            .font(.system(size: 14)) // Fuente más pequeña
                                            .frame(maxWidth: 150, alignment: .leading)
                                        
                                        Divider() // Línea divisoria entre columnas
                                            .frame(height: 20)
                                        
                                        Text(material.info1)
                                            .font(.system(size: 14))
                                            .frame(width: 80, alignment: .center)
                                        
                                        Divider() // Línea divisoria entre columnas
                                            .frame(height: 20)
                                        
                                        Text(material.info2)
                                            .font(.system(size: 14))
                                            .frame(width: 80, alignment: .center)
                                    }
                                }
                                .padding(.vertical, 4) // Relleno vertical reducido
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle()) // Estilo más limpio para la lista
                }
                .navigationTitle("Materiales")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    cargarMateriales()
                }
            }
        }
        
        private func cargarMateriales() {
            // Obtén materiales únicos por nombre usando un diccionario
            let allMaterials = dataManager.articulos.flatMap { $0.materiales }
            var uniqueMaterials: [String: Material] = [:] // Diccionario para asegurar unicidad por nombre
            
            for material in allMaterials {
                uniqueMaterials[material.nombre] = material
            }
            materialesFiltrados = Array(uniqueMaterials.values) // Convertir a un array
        }
        private func filtrarMateriales() {
            if searchText.isEmpty {
                cargarMateriales()
            } else {
                let allMaterials = dataManager.articulos
                    .flatMap { $0.materiales }
                    .filter { $0.nombre.localizedCaseInsensitiveContains(searchText) }
                
                var uniqueMaterials: [String: Material] = [:]
                
                for material in allMaterials {
                    uniqueMaterials[material.nombre] = material
                }
                
                materialesFiltrados = Array(uniqueMaterials.values)
            }
        }
    }

//MARK: EDITAR VISTA

import SwiftUI

struct EditarMaterialView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode

    let material: Material
    @State private var info1: String
    @State private var info2: String

    init(material: Material) {
        self.material = material
        _info1 = State(initialValue: material.info1)
        _info2 = State(initialValue: material.info2)
    }

    var body: some View {
        Form {
            Section(header: Text("Editar Material")) {
                HStack {
                    Text("Nombre:")
                        .frame(width: 100, alignment: .leading)
                    Text(material.nombre)
                }

                HStack {
                    Text("Info1:")
                        .frame(width: 100, alignment: .leading)
                    TextField("Info1", text: $info1)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                HStack {
                    Text("Info2:")
                        .frame(width: 100, alignment: .leading)
                    TextField("Info2", text: $info2)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
        .navigationTitle("Editar \(material.nombre)")
            .font(.system(size: 16, weight: .medium))
        .navigationBarItems(
            leading: Button("Cancelar") {
                presentationMode.wrappedValue.dismiss()
            },
            trailing: Button("Guardar") {
                guardarCambios()
                presentationMode.wrappedValue.dismiss()
            }
        )
    }

    private func guardarCambios() {
        for articuloIndex in dataManager.articulos.indices {
            if let materialIndex = dataManager.articulos[articuloIndex].materiales.firstIndex(where: { $0.id == material.id }) {
                dataManager.articulos[articuloIndex].materiales[materialIndex].info1 = info1
                dataManager.articulos[articuloIndex].materiales[materialIndex].info2 = info2
            }
        }
        dataManager.objectWillChange.send()
    }
}
