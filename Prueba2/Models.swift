//
//  Models.swift
//  Control de Piso
//
//  Created by Uls on 24/01/25.
//

//MARK: Models.swift
import SwiftUI
import UIKit
import Foundation
import WidgetKit
import AppIntents

struct Material: Identifiable, Codable, Hashable  {
    var id: UUID
    var nombre: String
    var cantidadDisponible: Int
    var cantidadRequerida: Int
    var info1: String = "-" // Valor inicial
    var info2: String = "-" // Valor inicial
    var cantidadAPedir: Int // Nueva propiedad: Int  // Nueva propiedad
    //var cantidadAPedir: Int {max(0, cantidadRequerida - cantidadDisponible)}
    init(id: UUID = UUID(), nombre: String = "", cantidadDisponible: Int = 0, cantidadRequerida: Int = 0, cantidadAPedir: Int = 0) {
        self.id = id
        self.nombre = nombre
        self.cantidadDisponible = cantidadDisponible
        self.cantidadRequerida = cantidadRequerida
        self.cantidadAPedir = (max(0, cantidadRequerida - cantidadDisponible))
    }
}


 public enum Clasificacion: String, CaseIterable, Codable {
    case revision = "Revision"
    case Stb = "Stand-By"
    case proceso = "Proceso"
    case terminada = "Terminada"
}

//----
public struct Orden: Identifiable, Codable {
    public var id: UUID
    public var nombre: String
    public var clasificacion: Clasificacion
    public var banco: String?
    public var fechaUltimaModificacion: Date?
    public var fechaInicioProceso: Date? // 🔹 Nueva variable para registrar el tiempo de inicio en proceso
    public var noWeek: String?
    public var nota: String?
    public var articuloNombre: String  // ← Nuevo
    public var articuloDescripcion: String // ← Nuevo
    public var tiempoLimiteHoras: Int // 🔹 Nuevo campo para el tiempo límite personalizado
    public var fueNotificadaRetraso: Bool
    
    
    
    public init(id: UUID = UUID(),
                nombre: String,
                clasificacion: Clasificacion,
                banco: String? = nil,
                fechaUltimaModificacion: Date? = nil,
                fechaInicioProceso: Date? = nil, // 🔹 Incluir en el inicializador
                noWeek: String? = nil,
                nota: String? = nil,
                articuloNombre: String,
                articuloDescripcion: String, // ← Nuevos parámetros
                tiempoLimiteHoras: Int = 1,
                fueNotificadaRetraso: Bool = false) {
        
        self.id = id
        self.nombre = nombre
        self.clasificacion = clasificacion
        self.banco = banco
        self.fechaUltimaModificacion = fechaUltimaModificacion
        self.fechaInicioProceso = fechaInicioProceso
        self.noWeek = noWeek
        self.nota = nota
        self.articuloNombre = articuloNombre
        self.articuloDescripcion = articuloDescripcion
        self.tiempoLimiteHoras = tiempoLimiteHoras
        self.fueNotificadaRetraso = fueNotificadaRetraso
    }
}

struct Articulo: Identifiable, Codable {
    var id = UUID()
    var nombre: String
    var descripcion: String // Añadir este campo
    var materiales: [Material]
    var ordenes: [Orden] // Almacena las órdenes con clasificación
    var cantidadOrdenes: Int {
        return ordenes.filter { $0.clasificacion != .terminada }.count // Excluye las terminadas
    }
}

struct ComponenteResumen: Identifiable {
    let id = UUID()
    let nombre: String
    let cantidadRequerida: Int
    let cantidadConsumida: Int
    let onHand: Int
}

struct ComponenteOrden: Identifiable {
    let id: UUID
    var nombre: String
    var cantidad: Int // Cantidad de este componente en esta orden
}


struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No es necesario actualizar nada en este caso
    }
}



struct OrdenParaWidget: Codable, Identifiable {
//struct OrderWidgetEntry: Codable, Identifiable, TimelineEntry {
    let id: UUID
    let nombre: String
    let clasificacion: Clasificacion
    let banco: String
    let fechaUltimaModificacion: Date
    let fechaInicioProceso: Date?
    let noWeek: String
    let nota: String
    let articuloNombre: String
    let articuloDescripcion: String
    let tiempoLimiteHoras: Int
    let fueNotificadaRetraso: Bool
}


struct OrderWidgetEntry: TimelineEntry {
    let date: Date
    let ordenes: [Orden]
    let configuration: ConfigurationAppIntent
}

/*
public struct OrderWidgetEntry: TimelineEntry {
    public let date: Date
    public let ordenes: [Orden]
    public let configuration: ConfigurationAppIntent
    
    public init(date: Date, ordenes: [Orden], configuration: ConfigurationAppIntent) {
        self.date = date
        self.ordenes = ordenes
        self.configuration = configuration
    }
}
*/

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuración"
    static var description: IntentDescription = "Cantidad de órdenes que se muestran en el widget."

    @Parameter(title: "Número de Órdenes", default: 5)
    var maxOrdenes: Int
}
