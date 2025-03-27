//
//  WidgetTimelineProvider.swift
//  Widget FactoryExtension
//
//  Created by Ul on 20/02/25.
//

import WidgetKit
import Intents
/*
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
        

   /*     func getTimeline(in context: Context, completion: @escaping (Timeline<OrderEntry>) -> ()) {
            let now = Date()
            let ordenesEnProceso = fetchOrdersInProceso()
            let entry = OrderEntry(date: now, ordenes: ordenesEnProceso)
            
            // Actualizar el widget solo cuando sea necesario
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 60))) // Actualizar en una hora
            completion(timeline)
        }*/
    
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

/*
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
            
            var timelineEntries: [OrderEntry] = []
            
            for minuteOffset in 0..<60 { // 🔹 Actualizar cada minuto
                let updateDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: now)!
                let entry = OrderEntry(date: updateDate, ordenes: ordenesEnProceso)
                timelineEntries.append(entry)
            }
            
            let timeline = Timeline(entries: timelineEntries, policy: .atEnd)
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
