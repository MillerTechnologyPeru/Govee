import SwiftUI
import Govee

struct ContentView: View {
    
    @EnvironmentObject
    var store: Store
    
    var body: some View {
        NavigationView {
            NearbyDevicesView()
        }
    }
}
