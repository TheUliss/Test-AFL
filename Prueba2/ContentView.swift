//
//  Views.swift
//  Control de Piso
//
//  Created by Ulises Islas on 24/01/25.
//

//MARK: VISTAS

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var mostrarAgregarArticulo = false

    var body: some View {
        ZStack {
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "list.bullet.clipboard.fill")
                    }
                ControlDePisoView()
                    .tabItem {
                        Label("Control de Piso", systemImage: "waveform.path.ecg.rectangle.fill")
                    }
                
                GestionarInventarioView()
                    .environmentObject(dataManager)
                    .tabItem {
                        Label("Artículos", systemImage: "cube.box")
                    }
                ListaOrdenesProcesoView()
                    .environmentObject(dataManager)
                    .tabItem {
                        Label("Proceso", systemImage: "arrow.triangle.2.circlepath")
                    }
                ResumenSemanalView()
                    .environmentObject(dataManager)
                    .tabItem {
                        Label("On Hand", systemImage: "hand.point.up.left.and.text")
                    }
                PedidosView()
                    .tabItem {
                        Label("Pedidos", systemImage: "cart.badge.clock.fill")
                    }
            }

      /*      GeometryReader { geometry in
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            mostrarAgregarArticulo = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 35, height: 35)
                                .foregroundColor(Color.green.opacity(0.7)) // Verde claro
                                .background(Circle().fill(Color.white).shadow(radius: 4))
                        }
                        .offset(x: geometry.size.width * -0.05, y: -65) // Posiciona el botón entre las pestañas "On Hand" y "Artículos"
                    }
                }
            } */
        }
        /*.sheet(isPresented: $mostrarAgregarArticulo) {
            AgregarArticuloView(articuloEditable: .constant(nil))
                .environmentObject(dataManager)
        } */
    }
}

