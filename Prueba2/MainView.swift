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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            .environmentObject(dataManager)
            .environmentObject(attendanceVM) //Cannot find 'attendanceVM' in scope

        }
    }
}
    
