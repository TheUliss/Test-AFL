//
//  AppIntent.swift
//  Widget Factory
//
//  Created by Ulises Islas on 19/02/25.
//


import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Configuración del Widget Bundle
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
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: OrderTimelineProvider()
        ) { entry in
            WidgetEntryView(entry: entry) // Aquí se usa WidgetEntryView en lugar de OrderWidgetView
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Órdenes en Proceso")
        .description("Muestra las órdenes en proceso y su progreso.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}


// MARK: - Timeline Provider
struct OrderTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = OrderWidgetEntry
    typealias Intent = ConfigurationAppIntent
    
    func placeholder(in context: Context) -> OrderWidgetEntry {
        OrderWidgetEntry(
            date: Date(),
            ordenes: [
                Orden(
                    id: UUID(),
                    nombre: "Orden de prueba",
                    clasificacion: .proceso,
                    banco: "1",
                    fechaInicioProceso: Date().addingTimeInterval(-3600),
                    articuloNombre: "Artículo test",
                    articuloDescripcion: "Descripción de prueba",
                    tiempoLimiteHoras: 24
                )
            ],
            configuration: ConfigurationAppIntent()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> OrderWidgetEntry {
        OrderWidgetEntry(
            date: Date(),
            ordenes: fetchOrders(),
            configuration: configuration
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<OrderWidgetEntry> {
        let entry = OrderWidgetEntry(
            date: Date(),
            ordenes: fetchOrders(),
            configuration: configuration
        )
        
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60)))
    }

    private func fetchOrders() -> [Orden] {
        let defaults = UserDefaults(suiteName: "group.com.pruebas.ordenesproceso")
        guard let data = defaults?.data(forKey: "ordenes"),
              let ordenes = try? JSONDecoder().decode([Orden].self, from: data) else {
            return []
        }
        return ordenes
    }
    
    //-->
    func getTimeline(in context: Context, completion: @escaping (Timeline<OrderEntry>) -> Void) {
        let ordenes = fetchOrdersInProceso()
        let entry = OrderEntry(date: Date(), ordenes: ordenes)
        
        // Actualizar cada 15 minutos y cuando haya cambios
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func fetchOrdersInProceso() -> [Orden] {
        let defaults = UserDefaults(suiteName: "group.com.pruebas.ordenesproceso")
        guard let data = defaults?.data(forKey: "ordenes"),
              let ordenes = try? JSONDecoder().decode([Orden].self, from: data) else {
            return []
        }
        return ordenes.filter { $0.clasificacion == .proceso }
    }
    //--<
    
}


