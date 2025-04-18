//
//  Inventario.swift
//  Control de Piso
//
//  Created by Ulises Islas on 24/01/25.
//

import SwiftUI

struct ListaBancosView: View {
    @State var maxBancos = 10
    @State var mostrarSelectorArticulo = false
    @State var bancoSeleccionado: Int?
    
    @ObservedObject var dataManager: DataManager
    @State private var mostrarToast = false

    var body: some View {
        NavigationView {
            VStack {
                List(1...maxBancos, id: \.self) { banco in
                    Button(action: {
                        bancoSeleccionado = banco
                        mostrarSelectorArticulo = true
                    }) {
                        Text("Banco \(banco)")
                    }
                }
                
                Button(action: {
                    dataManager.guardarArticulos()
                    mostrarToast = true
                }) {
                    HStack {
                        Image(systemName: "tray.and.arrow.down.fill")
                        Text("Guardar Cambios")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Bancos disponibles")
            .sheet(isPresented: $mostrarSelectorArticulo) {
                if let banco = bancoSeleccionado {
                    SelectorArticuloView(dataManager: dataManager, banco: banco)
                }
            }
        }
        .toast(message: "Cambios guardados", isShowing: $mostrarToast, duration: 2)
    }
}


struct SelectorArticuloView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager: DataManager
    let banco: Int

    var body: some View {
        NavigationView {
            List {
                ForEach(dataManager.articulos) { articulo in
                    Button(action: {
                       // agregarOrden(al: articulo)
                        dismiss()
                    }) {
                        VStack(alignment: .leading) {
                            Text(articulo.nombre)
                                .font(.headline)
                            Text(articulo.descripcion)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Selecciona Artículo")
        }
    }
    
}

