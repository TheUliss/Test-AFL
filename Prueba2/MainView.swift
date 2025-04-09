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

    
 struct Prueba2App: App {
     @StateObject private var dataManager = DataManager()
     @StateObject private var attendanceVM = AttendanceViewModel()
    //@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

     var body: some Scene {
         WindowGroup {
            // DashboardView()
             ContentView()
             .environmentObject(dataManager)
             .environmentObject(attendanceVM)
         }
     }
 }
     
