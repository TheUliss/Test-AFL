//
//  ListaOrdenesProcesoView.swift
//  Test AFL
//
//  Created by Ulises Islas on 11/04/25.
//


import SwiftUI

struct ListaOrdenesProcesoView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            List(dataManager.ordenesEnProceso) { orden in
                NavigationLink(destination: EditarProcesosView(orden: orden)) {
                    VStack(alignment: .leading) {
                        Text("Orden: \(orden.nombre)")
                        if let banco = orden.banco {
                            Text("Banco: \(banco)").font(.subheadline).foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Órdenes en Proceso")
            .toolbar {
                NavigationLink("Resumen", destination: ResumenProcesosView())
            }
        }
    }
}

struct EditarProcesosView: View {
    @EnvironmentObject var dataManager: DataManager
    var orden: Orden

    @State private var cantidades: [String: String] = [:]

    let operaciones = [
        "01 - Deschaquetado", "04 - Paso de luz", "05 - Retrabajos de Ensamble", "06 - Ribonizado",
        "07 - Depilado", "08 - Repulido", "09 - Pulido", "10 - Limpieza", "11 - Geometria",
        "12 - Armado", "14 - Quemado de Termo", "15 - Etiquetado", "16 - Inyeccion de Transferencia",
        "17 - Polaridad", "18 - Prueba", "20 - Calidad", "21 - Puntas Finales", "22 - Puntas Empacadas"
    ]

    var body: some View {
        Form {
            Section(header: Text("Asignar Cantidades")) {
                ForEach(operaciones, id: \.self) { op in
                    HStack {
                        Text(op).frame(width: 180, alignment: .leading)
                        TextField("Cantidad", text: Binding(
                            get: { cantidades[op] ?? "" },
                            set: {
                                // Solo permite números
                                if $0.isEmpty || Int($0) != nil {
                                    cantidades[op] = $0}}
                        ))
                        .keyboardType(.numberPad)
                    }
                }
            }

            Button("Guardar") {
                guardarCambios()
            }
        }
        .onAppear {
            for op in operaciones {
                if let cantidad = orden.cantidadesPorOperacion[op] {
                    cantidades[op] = "\(cantidad)"
                }
            }
        }
        .navigationTitle("Editar \(orden.nombre)")
    }
    func guardarCambios() {
        // Buscar el artículo que contiene esta orden
        for (i, articulo) in dataManager.articulos.enumerated() {
            if let j = articulo.ordenes.firstIndex(where: { $0.id == orden.id }) {
                for (op, val) in cantidades {
                    if let cantidad = Int(val) {
                        dataManager.articulos[i].ordenes[j].cantidadesPorOperacion[op] = cantidad
                    }
                }
            }
        }
    }
   
}


struct ResumenProcesosView: View {
    @EnvironmentObject var dataManager: DataManager

    let operaciones = [
        "01 - Deschaquetado", "04 - Paso de luz", "05 - Retrabajos de Ensamble", "06 - Ribonizado",
        "07 - Depilado", "08 - Repulido", "09 - Pulido", "10 - Limpieza", "11 - Geometria",
        "12 - Armado", "14 - Quemado de Termo", "15 - Etiquetado", "16 - Inyeccion de Transferencia",
        "17 - Polaridad", "18 - Prueba", "20 - Calidad", "21 - Puntas Finales", "22 - Puntas Empacadas"
    ]

    var ordenesEnProceso: [Orden] {
        dataManager.ordenes.filter { $0.clasificacion == .proceso }
    }

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading) {
                HStack {
                    Text("Operación").frame(width: 200)
                    ForEach(ordenesEnProceso) { orden in
                        Text(orden.nombre).frame(width: 80)
                    }
                    Text("Total").bold().frame(width: 80)
                }

                ForEach(operaciones, id: \.self) { op in
                    let valores = ordenesEnProceso.map { $0.cantidadesPorOperacion[op] ?? 0 }
                    let total = valores.reduce(0, +)

                    HStack {
                        Text(op).frame(width: 200)
                        ForEach(valores, id: \.self) { val in
                            Text("\(val)").frame(width: 80)
                        }
                        Text("\(total)").bold().frame(width: 80)
                    }
                }
            }
        }
        .navigationTitle("Resumen de Procesos")
    }
}
