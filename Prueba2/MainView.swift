//
//  ContentView.swift
//  Control de Piso
//
//  Created by Ulises Islas on 22/01/25.
//

 import SwiftUI
 import UIKit
 import UserNotifications

 @main

/*
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("✅ La app ha iniciado correctamente")

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Permisos de notificación concedidos")
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("Error en permisos: \(error.localizedDescription)")
            }
        }

        return true
    }

}
*/
    
 struct Prueba2App: App {
     @StateObject private var dataManager = DataManager()
    //@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

     var body: some Scene {
         WindowGroup {
            // DashboardView()
             ContentView()
             .environmentObject(dataManager)
         }
     }
 }
     
