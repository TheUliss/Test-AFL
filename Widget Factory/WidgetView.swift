//
//  WidgetView.swift
//  Widget FactoryExtension
//
//  Created by Uls on 20/02/25.
//

import SwiftUI
import WidgetKit

struct WidgetEntryView: View {
    var entry: OrderWidgetEntry
    @Environment(\.widgetFamily) var widgetFamily
    
    struct OrdenWidgetData {
        var orden: Orden
        var tiempoTranscurrido: TimeInterval
        var estaRetrasada: Bool
    }
    
    
    var ordenesEnProceso: [Orden] {
        entry.ordenes.filter { $0.clasificacion == .proceso }
    }
    
    var ordenesTerminadas: Int {
        entry.ordenes.filter { $0.clasificacion == .terminada }.count
    }

    // Calcula el tiempo actualizado al momento de renderizar
    var ordenesActualizadas: [OrdenWidgetData] {
        entry.ordenes.map { orden in
            let tiempoTranscurrido = orden.fechaInicioProceso.map { Date().timeIntervalSince($0) } ?? 0
            let estaRetrasada = tiempoTranscurrido > Double(orden.tiempoLimiteHoras * 3600)
            
            return OrdenWidgetData(orden: orden, tiempoTranscurrido: tiempoTranscurrido, estaRetrasada: estaRetrasada)
        }
    }

    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(ordenes: ordenesEnProceso)
        case .systemMedium:
            MediumWidgetView(ordenes: ordenesEnProceso, totalTerminadas: ordenesTerminadas)
        case .systemLarge:
            LargeWidgetView(ordenes: ordenesEnProceso)
        default:
            Text("Tamaño no soportado")
        }
    }
}

// MARK: - Vistas para cada tamaño de widget

struct SmallWidgetView: View {
    var ordenes: [Orden]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Órdenes en Proceso")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.5))

            if ordenes.isEmpty {
                Text("No hay órdenes activas")
                    .font(.caption2)
                    .foregroundColor(.gray)
            } else {
                let topOrdenes = ordenes
                    .sorted { $0.tiempoTranscurrido > $1.tiempoTranscurrido }
                    .prefix(5)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(topOrdenes) { orden in
                        HStack(spacing: 4) {
                            Text("\(orden.banco ?? "N/A")")
                                .font(.caption2)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.8))
                                .cornerRadius(4)

                            ProgressView(value: orden.progreso)
                                .progressViewStyle(LinearProgressViewStyle(tint: orden.estaRetrasada ? .red : .green))
                                .frame(height: 3)

                            Text(orden.tiempoTranscurridoFormateado)
                                .font(.system(size: 10))
                                .foregroundColor(orden.estaRetrasada ? .red : .white)
                        }
                    }
                }

                if ordenes.count > 5 {
                    Text("+\(ordenes.count - 5) más")
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 2)
                }
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .containerBackground(Color.black, for: .widget)
    }
}

//MARK: MEDIUM
struct MediumWidgetView: View {
    var ordenes: [Orden]
    var totalTerminadas: Int // Nueva propiedad para recibir el conteo
    
    init(ordenes: [Orden], totalTerminadas: Int) {
        self.ordenes = ordenes
        self.totalTerminadas = totalTerminadas
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Columna izquierda: Lista de órdenes (se mantiene igual)
            VStack(alignment: .leading, spacing: 4) {
                Text("Órdenes Activas")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.5))

                if ordenes.isEmpty {
                    Text("No hay órdenes en producción")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                } else {
                    let topOrdenes = ordenes
                        .sorted { $0.tiempoTranscurrido > $1.tiempoTranscurrido }
                        .prefix(5)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(topOrdenes) { orden in
                            HStack(spacing: 4) {
                                Text("\(orden.banco ?? "N/A")")
                                    .font(.system(size: 12))
                                    .bold()
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.8))
                                    .cornerRadius(4)

                                ProgressView(value: orden.progreso)
                                    .progressViewStyle(LinearProgressViewStyle(tint: orden.estaRetrasada ? .red : .green))
                                    .frame(height: 3)

                                Text(orden.tiempoTranscurridoFormateado)
                                    .font(.system(size: 10))
                                    .foregroundColor(orden.estaRetrasada ? .red : .white)
                            }
                        }
                    }

                    if ordenes.count > 5 {
                        Text("+\(ordenes.count - 5) más")
                            .font(.system(size: 10))
                            .bold()
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 2)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Columna derecha: Resumen (actualizada)
            VStack(alignment: .leading, spacing: 8) {
                Text("Resumen")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.5))

                VStack(alignment: .leading, spacing: 6) {
                    // Órdenes en proceso
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        Text("En proceso: \(ordenes.count)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    // Órdenes retrasadas
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                        
                        let retrasadas = ordenes.filter { $0.estaRetrasada }.count
                        Text("Retrasadas: \(retrasadas)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    // Nueva sección para órdenes terminadas
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        
                        Text("Terminadas: \(totalTerminadas)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .containerBackground(Color.black, for: .widget)
    }
}

//MARK: LARGE
struct LargeWidgetView: View {
    var ordenes: [Orden]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Órdenes en Producción")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray)
            
            if ordenes.isEmpty {
                Text("No hay órdenes activas")
                    .font(.caption2)
                    .foregroundColor(.gray)
            } else {
                let topOrdenes = ordenes
                    .sorted { $0.tiempoTranscurrido > $1.tiempoTranscurrido }
                    .prefix(5)
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(topOrdenes) { orden in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(orden.banco ?? "N/A")
                                    .font(.caption2)
                                    .bold()
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .cornerRadius(4)
                                
                                Text("\(orden.articuloNombre) - \(orden.nombre)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                            
                            ProgressView(value: orden.progreso)
                                .progressViewStyle(LinearProgressViewStyle(tint: orden.estaRetrasada ? .red : .green))
                                .frame(height: 3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(2)
                            
                            HStack {
                                Image(systemName: orden.estaRetrasada ? "exclamationmark.triangle.fill" : "clock.fill")
                                    .foregroundColor(orden.estaRetrasada ? .red : .green)
                                    .font(.caption2)
                                
                                Text(orden.detalleTiempo)
                                    .font(.caption2)
                                    .foregroundColor(orden.estaRetrasada ? .red : .gray)
                            }
                        }
                        .padding(4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    }
                    
                    if ordenes.count > 5 {
                        Text("+\(ordenes.count - 5) órdenes más")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 4)
                    }
                }
            }
            Spacer()
        }
        .padding(6)
        .background(Color.black)
        .containerBackground(Color.black, for: .widget)
    }
}
    
    // MARK: - Extensiones para facilitar el cálculo de tiempos
    
    extension Orden {
        var tiempoTranscurrido: TimeInterval {
            fechaInicioProceso.map { Date().timeIntervalSince($0) } ?? 0
        }
        
        var tiempoTranscurridoFormateado: String {
            guard let fechaInicio = fechaInicioProceso else { return "Sin iniciar" }
            let tiempo = Int(Date().timeIntervalSince(fechaInicio))
            let horas = tiempo / 3600
            let minutos = (tiempo % 3600) / 60
            return "\(horas)h \(minutos)m"
        }
        
        var progreso: Double {
            min(max(tiempoTranscurrido / Double(tiempoLimiteHoras * 3600), 0), 1.0)
        }
        
        var estaRetrasada: Bool {
            guard let fechaInicio = fechaInicioProceso else { return false }
            let tiempoTranscurrido = Date().timeIntervalSince(fechaInicio)
            return tiempoTranscurrido > Double(tiempoLimiteHoras * 3600)
        }
        
        var detalleTiempo: String {
            let horas = Int(tiempoTranscurrido) / 3600
            let minutos = (Int(tiempoTranscurrido) % 3600) / 60
            let restanteHoras = max(tiempoLimiteHoras - horas, 0)
            let restanteMinutos = max(60 - minutos, 0)
            
            if estaRetrasada {
                let retrasoHoras = horas - tiempoLimiteHoras
                let retrasoMinutos = minutos
                return "Retraso: \(retrasoHoras)h \(retrasoMinutos)m"
            } else {
                return "\(horas)h \(minutos)m / \(tiempoLimiteHoras)h (Restan: \(restanteHoras)h \(restanteMinutos)m)"
            }
        }
    }
    


/*
 extension Orden {
     
     var tiempoTranscurrido: TimeInterval {
         fechaInicioProceso.map { Date().timeIntervalSince($0) } ?? 0
         }
     
    var tiempoTranscurridoFormateado: String {
        let tiempo = self.tiempoTranscurrido ?? {
            guard let inicio = fechaInicioProceso else { return 0 }
            return Date().timeIntervalSince(inicio)
        }()
        let horas = Int(tiempo) / 3600
        let minutos = (Int(tiempo) % 3600) / 60
        return "\(horas)h \(minutos)m"
    }
}

  */
