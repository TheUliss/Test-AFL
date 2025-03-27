//
//  OnHand.swift
//  Control de Piso
//
//  Created by Ulises Islas on 24/01/25.
//

//MARK: ON HAND

import SwiftUI

struct ResumenSemanalView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var semanasDisponibles: [String] = [] // Semanas únicas
    @State private var resumenSemanal: [(nombre: String, requerida: Int, consumida: Int, onHand: Int)] = []
    @State private var semanaSeleccionada: Int = 0 // Valor inicial predeterminado

    var body: some View {
        NavigationView {
            VStack {
                // Selector de Semana
                HStack {
                    Text("Selecciona la Semana:")
                        .font(.headline)
                    Picker("Semana", selection: $semanaSeleccionada) {
                        // Ordenamos semanasDisponibles de mayor a menor
                        ForEach(semanasDisponibles.sorted(by: >), id: \.self) { semana in
                            if let semanaInt = Int(semana) {
                                Text("Semana \(semana)").tag(semanaInt)
                            }
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: semanaSeleccionada) { _, newValue in
                        calcularResumenSemanal()
                    }
                }
                .padding()
                .onAppear {
                    cargarSemanasDisponibles()
                    if let semanaMaxima = semanasDisponibles.compactMap({ Int($0) }).max() {
                        semanaSeleccionada = semanaMaxima
                        calcularResumenSemanal()
                    }
                }

                // Tabla de Resumen
                List {
                    Section(header: HStack {
                        Text("Item")
                            .frame(maxWidth: 250, alignment: .leading)
                        Text("Requerida")
                            .frame(maxWidth: 80, alignment: .center)
                        Text("Consumida")
                            .frame(maxWidth: 80, alignment: .center)
                        Text("ON-HAND")
                            .frame(maxWidth: 80, alignment: .center)
                    }) {
                        ForEach(resumenSemanal, id: \.nombre) { entry in
                            HStack {
                                Text(entry.nombre)
                                    .frame(maxWidth: 250, alignment: .leading) // Aumentar el ancho máximo
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                                    .lineLimit(1) // Limitar a una sola línea
                                    .truncationMode(.tail) // Mostrar "..." si el texto es muy largo
                                Text("\(entry.requerida)")
                                    .frame(maxWidth: 80, alignment: .center)
                                Text("\(entry.consumida)")
                                    .frame(maxWidth: 80, alignment: .center)
                                    .foregroundColor(entry.consumida > 0 ? .red : .blue)
                                Text("\(entry.onHand)")
                                    .frame(maxWidth: 80, alignment: .center)
                                    .foregroundColor(entry.onHand >= 0 ? .green : .red)
                            }
                        }
                    }
                }
                .navigationTitle("Resumen Semanal")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    // MARK: - Cargar semanas únicas disponibles
    private func cargarSemanasDisponibles() {
        semanasDisponibles = dataManager.articulos
            .flatMap { $0.ordenes.map { $0.noWeek ?? "" } }
            .filter { !$0.isEmpty }
            .removingDuplicates()
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    // MARK: - Calcular el resumen semanal
    private func calcularResumenSemanal() {
        resumenSemanal = []

        // Validar que la semana seleccionada sea válida
        guard semanaSeleccionada > 0 else { return }

        var conteoMateriales: [String: (requerida: Int, consumida: Int)] = [:]

        for articulo in dataManager.articulos {
            for orden in articulo.ordenes where Int(orden.noWeek ?? "") == semanaSeleccionada {
                for material in articulo.materiales {
                    if let existente = conteoMateriales[material.nombre] {
                        conteoMateriales[material.nombre] = (
                            requerida: existente.requerida + material.cantidadRequerida,
                            consumida: existente.consumida + (orden.clasificacion == .terminada ? material.cantidadRequerida : 0)
                        )
                    } else {
                        conteoMateriales[material.nombre] = (
                            requerida: material.cantidadRequerida,
                            consumida: orden.clasificacion == .terminada ? material.cantidadRequerida : 0
                        )
                    }
                }
            }
        }

        resumenSemanal = conteoMateriales.map { (nombre, conteo) in
            let onHand = conteo.requerida - conteo.consumida
            return (nombre: nombre, requerida: conteo.requerida, consumida: conteo.consumida, onHand: onHand)
        }
    }
}

// MARK: - Extensiones para eliminar duplicados
extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}
