//
//  Widget_FactoryBundle.swift
//  Widget Factory
//
//  Created by Uls on 19/02/25.
//
/*
import WidgetKit
import SwiftUI

@main
struct OrderWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        OrderWidget()
    }
}

struct OrderWidget: Widget {
    let kind: String = "OrderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OrderTimelineProvider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Órdenes en Proceso")
        .description("Muestra las órdenes en proceso y su progreso.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        //.supportedFamilies([.systemMedium, .systemLarge]) // Configura el tamaño grande
    }
}

struct OrderTimelineProvider: TimelineProvider {
func placeholder(in context: Context) -> OrderEntry {
   // OrderEntry.placeholder
    OrderEntry(date: Date(), ordenes: [
        Orden(
            id: UUID(),
            nombre: "Orden de prueba",
            clasificacion: .proceso,
            banco: "1", // Añadimos el banco
            fechaInicioProceso: Date().addingTimeInterval(-3600),
            articuloNombre: "Artículo test", // Nuevo campo requerido
            articuloDescripcion: "Descripción de prueba" // Nuevo campo requerido
                        
        )
    ])
}

func getSnapshot(in context: Context, completion: @escaping (OrderEntry) -> Void) {
    let entry = OrderEntry(date: Date(), ordenes: fetchOrdersInProceso())
    completion(entry)
}

func getTimeline(in context: Context, completion: @escaping (Timeline<OrderEntry>) -> ()) {
  let now = Date()
  let ordenesEnProceso = fetchOrdersInProceso()
  let entry = OrderEntry(date: now, ordenes: ordenesEnProceso)
  
  // Actualizar cada 1 minutos
  let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 1, to: now)!
  let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
  completion(timeline)
}


private func fetchOrdersInProceso() -> [Orden] {
    let defaults = UserDefaults(suiteName: "group.com.pruebas.ordenesproceso") // Debe coincidir con el App Group
    if let data = defaults?.data(forKey: "ordenes"),
       let ordenes = try? JSONDecoder().decode([Orden].self, from: data) {
        return ordenes
    }
    return []
}
}
*/
