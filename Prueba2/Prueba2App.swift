//
//
//  Control de Piso
//
//  Created by Uls on 22/01/25.
//

//MARK: DATAMANAGER

import SwiftUI
import Foundation
import WidgetKit
import UserNotifications

class DataManager: ObservableObject {
    
    private var timer: Timer?
    static let shared = DataManager()
    
    
    @Published var articulos: [Articulo] = [] {
        didSet {
            guardarArticulos()
            // actualizarOrdenes() // Actualizar las órdenes cuando cambian los artículos
        }
    }
    
    // Propiedades computadas para mantener los datos sincronizados
    var ordenes: [Orden] {
        articulos.flatMap { $0.ordenes }
    }
    var ordenesEnProceso: [Orden] {
        ordenes.filter { $0.clasificacion == .proceso }
    }
    var ordenesTerminadas: [Orden] {
        ordenes.filter { $0.clasificacion == .terminada }
    }
    var ordenesStandby: [Orden] {
        ordenes.filter { $0.clasificacion == .Stb }
    }
    
    var ordenesRetrasadas: [Orden] {
        ordenes.filter { orden in
            guard orden.clasificacion == .proceso,
                  let fechaInicio = orden.fechaInicioProceso else { return false }
            let horasTranscurridas = Int(Date().timeIntervalSince(fechaInicio)) / 3600
            return horasTranscurridas > orden.tiempoLimiteHoras
        }
    }
    
    
    private let articulosURL: URL = {
        let directorio = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directorio.appendingPathComponent("articulos.json")
    }()
    
    
    
    init() {
        cargarArticulos()
        solicitarPermisosNotificaciones()   //permiso para las notificaciones
        startBackgroundMonitoring()
    }
 
    
    
    ///--->
    // Cambia de private a internal o public
    func startBackgroundMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            DispatchQueue.global(qos: .background).async {
                self?.checkForDelayedOrders()
            }
        }
    }

           
    private func checkForDelayedOrders() {
        let now = Date()

        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }

            print("Verificando órdenes en proceso: \(self.ordenesEnProceso.count)")
            print("Verificando artículos: \(self.articulos.count)")

            let ordenesRetrasadas = self.ordenesEnProceso.filter { orden in
                guard let inicio = orden.fechaInicioProceso else { return false }
                let tiempoTranscurrido = now.timeIntervalSince(inicio)
                return tiempoTranscurrido > Double(orden.tiempoLimiteHoras * 3600) && !orden.fueNotificadaRetraso
            }

            DispatchQueue.main.async {
                for orden in ordenesRetrasadas {
                    if let articulo = self.articulos.first(where: { $0.ordenes.contains { $0.id == orden.id } }) {
                        self.sendDelayNotification(orden: orden, articulo: articulo)
                        self.markOrderAsNotified(orden: orden)
                    }
                }
            }
        }
    }

        
        private func sendDelayNotification(orden: Orden, articulo: Articulo) {
                let content = UNMutableNotificationContent()
                content.title = "⚠️ Orden Retrasada"
                content.body = """
                \(orden.nombre) - \(articulo.nombre)
                Banco: \(orden.banco ?? "N/A")
                Retraso: \(orden.tiempoTranscurridoFormateado)
                """
                content.sound = .default
                content.userInfo = ["ordenId": orden.id.uuidString]
                
                let request = UNNotificationRequest(
                    identifier: "delay-\(orden.id.uuidString)",
                    content: content,
                    trigger: nil // Notificación inmediata
                )
                
                UNUserNotificationCenter.current().add(request)
            }
        
//---<

    private let notificationQueue = DispatchQueue(label: "com.tuapp.notifications", qos: .background)
        
        func guardarArticulos() {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            do {
                let data = try encoder.encode(articulos)
                try data.write(to: articulosURL)
                print("Artículos guardados correctamente")
                
                // Procesar en segundo plano después de guardar
                DispatchQueue.global(qos: .background).async {
                    self.verificarYNotificarRetrasos()
                    self.actualizarWidgets()
                }
            } catch {
                print("Error al guardar los artículos: \(error)")
            }
        }
        
        private func actualizarWidgets() {
            DispatchQueue.main.async {
                self.guardarOrdenesParaWidget()
                WidgetCenter.shared.reloadAllTimelines()
                print("Widgets actualizados")
            }
        }
        
        private func verificarYNotificarRetrasos() {
            notificationQueue.async {
                let center = UNUserNotificationCenter.current()
                center.getNotificationSettings { settings in
                    guard settings.authorizationStatus == .authorized else { return }
                    
                    let ordenesRetrasadas = self.ordenesRetrasadas
                    for orden in ordenesRetrasadas {
                        if let articulo = self.articulos.first(where: { $0.ordenes.contains { $0.id == orden.id } }),
                           !orden.fueNotificadaRetraso {
                            
                            self.enviarNotificacionRetraso(orden: orden, articulo: articulo)
                            DispatchQueue.main.async {
                                self.marcarOrdenComoNotificada(orden: orden)
                            }
                        }
                    }
                }
            }
        }
        
  
    private func cargarArticulos() {
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: articulosURL)
            articulos = try decoder.decode([Articulo].self, from: data)
            print("Artículos cargados correctamente desde \(articulosURL.path)")
        } catch {
            print("No se encontraron artículos guardados o hubo un error al cargarlos: \(error)")
        }
    }
    
    // MARK: - App Groups

    
    func guardarOrdenesParaWidget() {
        DispatchQueue.global(qos: .userInitiated).async {
            let ordenesParaWidget = self.articulos.flatMap { articulo in
                articulo.ordenes.compactMap { orden -> OrdenParaWidget? in
                    guard [.proceso, .terminada, .Stb].contains(orden.clasificacion) else {
                        return nil
                    }
                    
                    return OrdenParaWidget(
                        id: orden.id,
                        nombre: orden.nombre,
                        clasificacion: orden.clasificacion,
                        banco: orden.banco ?? "N/A",
                        fechaUltimaModificacion: orden.fechaUltimaModificacion ?? Date(),
                        fechaInicioProceso: orden.fechaInicioProceso,
                        noWeek: orden.noWeek ?? "",
                        nota: orden.nota ?? "",
                        articuloNombre: articulo.nombre,
                        articuloDescripcion: articulo.descripcion,
                        tiempoLimiteHoras: orden.tiempoLimiteHoras,
                        fueNotificadaRetraso: orden.fueNotificadaRetraso
                    )
                }
            }

            do {
                let data = try JSONEncoder().encode(ordenesParaWidget)
                if let sharedDefaults = UserDefaults(suiteName: "group.com.pruebas.ordenesproceso") {
                    sharedDefaults.set(data, forKey: "ordenes")
                    print("✅ Datos actualizados para widget")
                }
            } catch {
                print("❌ Error al guardar para widget:", error)
            }
        }
    }
    
    func cambiarEstadoOrden(orden: Orden, nuevoEstado: Clasificacion) {
        if let articuloIndex = articulos.firstIndex(where: { $0.ordenes.contains { $0.id == orden.id } }) {
            // Crear copia mutable del artículo
            var articuloModificado = articulos[articuloIndex]
            
            if let indiceOrden = articuloModificado.ordenes.firstIndex(where: { $0.id == orden.id }) {
                // Modificar la orden
                articuloModificado.ordenes[indiceOrden].clasificacion = nuevoEstado
                
                // Actualizar el array de artículos
                articulos[articuloIndex] = articuloModificado
                
                guardarArticulos()
                guardarOrdenesParaWidget()
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    // MARK: - Gestión de Configuración (Empresa, Usuario, Logo)
        @Published var empresa: String = ""
        @Published var usuario: String = ""
        @Published var logoData: Data? = nil
        @Published var cantidades: [UUID: Int] = [:]
        @Published var materialesResumen: [Material] = [] // Resumen de materiales

}


extension View {
func toast(message: String, isShowing: Binding<Bool>, duration: TimeInterval) -> some View {
ZStack {
    self
    if isShowing.wrappedValue {
        VStack {
            Spacer()
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding()
                //.background(Color.black.opacity(0.8))
                .background(Color.blue.opacity(0.8))
                .cornerRadius(10)
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity)
                .transition(.move(edge: .bottom))
               // .animation(.easeInOut, value: mostrarToast)
                .padding(.bottom, 20)
        }
        .transition(.move(edge: .bottom))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                isShowing.wrappedValue = false
            }
        }
    }
}
}
}


extension DataManager {
    
    func saveChanges() {
        // Implementación de guardado
        do {
            let encoder = JSONEncoder()
            let encodedArticulos = try encoder.encode(articulos)
            UserDefaults.standard.set(encodedArticulos, forKey: "articulosData")
        } catch {
            print("Error al guardar artículos:", error)
        }
    }
    
    private func enviarNotificacionRetraso(orden: Orden, articulo: Articulo) {
        let contenido = UNMutableNotificationContent()
        contenido.title = "¡Orden Retrasada!"
        contenido.subtitle = "\(orden.nombre) - \(articulo.nombre)"
        contenido.body = """
        Banco: \(orden.banco ?? "N/A")
        Tiempo límite: \(orden.tiempoLimiteHoras) horas
        Tiempo transcurrido: \(orden.tiempoTranscurridoFormateado)
        Artículo: \(articulo.nombre)
        Descripción: \(articulo.descripcion)
        """
        contenido.sound = UNNotificationSound.default
        contenido.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "retraso_\(orden.id.uuidString)",
            content: contenido,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error al programar notificación: \(error.localizedDescription)")
            }
        }
    }
    
    
    private func marcarOrdenComoNotificada(orden: Orden) {
        if let articuloIndex = articulos.firstIndex(where: { $0.ordenes.contains { $0.id == orden.id } }) {
            if let ordenIndex = articulos[articuloIndex].ordenes.firstIndex(where: { $0.id == orden.id }) {
                articulos[articuloIndex].ordenes[ordenIndex].fueNotificadaRetraso = true
                guardarArticulos()
            }
        }
    }
    
    private func markOrderAsNotified(orden: Orden) {
            if let articuloIndex = articulos.firstIndex(where: { $0.ordenes.contains { $0.id == orden.id } }),
               let ordenIndex = articulos[articuloIndex].ordenes.firstIndex(where: { $0.id == orden.id }) {
                
                // Crear copia mutable
                var articuloModificado = articulos[articuloIndex]
                var ordenModificada = articuloModificado.ordenes[ordenIndex]
                
                // Actualizar propiedad
                ordenModificada.fueNotificadaRetraso = true
                
                // Reemplazar en el array
                articuloModificado.ordenes[ordenIndex] = ordenModificada
                articulos[articuloIndex] = articuloModificado
                
                // Guardar cambios
                guardarArticulos()
                
                print("Orden marcada como notificada: \(orden.nombre)")
            }
        }
    
}


private func solicitarPermisosNotificaciones() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if granted {
            print("Permiso para notificaciones concedido")
        } else if let error = error {
            print("Error al solicitar permisos: \(error.localizedDescription)")
        }
    }
}

