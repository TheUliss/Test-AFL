//
//  WidgetTimelineEntry.swift
//  Widget FactoryExtension
//
//  Created by Ulises Islas on 20/02/25.
//

import WidgetKit
import SwiftUI

struct OrderEntry: TimelineEntry {
    let date: Date
    let ordenes: [Orden]

    static var placeholder: OrderEntry {
        OrderEntry(date: Date(), ordenes: [
    Orden(id: UUID(), nombre: "123456", clasificacion: .proceso, banco: "1", fechaInicioProceso: Date().addingTimeInterval(-3600),articuloNombre: "Artículo A",articuloDescripcion: "Descripción A"), // Hace 1 hora
    Orden(id: UUID(), nombre: "654321", clasificacion: .proceso, banco: "2", fechaInicioProceso: Date().addingTimeInterval(-7200),articuloNombre: "Artículo B",articuloDescripcion: "Descripción B") // Hace 2 horas
        ])
    }
}
