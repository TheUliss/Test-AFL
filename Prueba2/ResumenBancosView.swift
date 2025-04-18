import SwiftUI

struct ResumenBancosView: View {
    @EnvironmentObject var dataManager: DataManager
    
    // Rango de bancos a mostrar (1...50)
    private let bancosDisponibles = Array(1...50)
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Bancos Ocupados (\(dataManager.bancosOcupados().count))")) {
                    // Mostrar bancos ocupados en una lista compacta
                    Text(dataManager.bancosOcupados().map(String.init).joined(separator: ", "))
                        .font(.subheadline)
                }
                
                Section(header: Text("Todos los Bancos (1-50)")) {
                    // Grid de bancos (ocupados vs. disponibles)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                        ForEach(bancosDisponibles, id: \.self) { banco in
                            Text("\(banco)")
                                .frame(width: 50, height: 50)
                                .background(dataManager.bancosOcupados().contains(banco) ? Color.red.opacity(0.3) : Color.green.opacity(0.3))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(dataManager.bancosOcupados().contains(banco) ? Color.red : Color.green, lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .navigationTitle("Resumen de Bancos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Opción para exportar o actualizar
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}