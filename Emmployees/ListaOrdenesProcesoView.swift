import SwiftUI

struct ListaOrdenesProcesoView: View {
    @EnvironmentObject var dataManager: DataManager

    var ordenesEnProceso: [Orden] {
        dataManager.ordenes.filter { $0.clasificacion == "Proceso" }
    }

    var body: some View {
        NavigationView {
            List(ordenesEnProceso) { orden in
                NavigationLink(destination: EditarProcesosView(orden: orden)) {
                    VStack(alignment: .leading) {
                        Text("Orden: \(orden.codigo)")
                        Text("Banco: \(orden.banco)").font(.subheadline).foregroundColor(.gray)
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
                            set: { cantidades[op] = $0 }
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
        .navigationTitle("Editar \(orden.codigo)")
    }

    func guardarCambios() {
        guard let index = dataManager.ordenes.firstIndex(where: { $0.id == orden.id }) else { return }
        for (op, val) in cantidades {
            if let cantidad = Int(val) {
                dataManager.ordenes[index].cantidadesPorOperacion[op] = cantidad
            }
        }
        dataManager.guardar()
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

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading) {
                HStack {
                    Text("Operación").frame(width: 200)
                    ForEach(dataManager.ordenes.filter { $0.clasificacion == "Proceso" }) { orden in
                        Text(orden.codigo).frame(width: 80)
                    }
                    Text("Total").bold().frame(width: 80)
                }

                ForEach(operaciones, id: \.self) { op in
                    HStack {
                        Text(op).frame(width: 200)
                        var total = 0
                        ForEach(dataManager.ordenes.filter { $0.clasificacion == "Proceso" }) { orden in
                            let val = orden.cantidadesPorOperacion[op] ?? 0
                            total += val
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
