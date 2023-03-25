import Foundation
import SwiftUI
import CoreBluetooth
import Bluetooth
import GATT
import Govee

@main
struct GoveeApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(Store.shared)
        }
    }
}
