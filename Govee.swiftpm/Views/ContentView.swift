import SwiftUI
import Govee

struct ContentView: View {
    
    @EnvironmentObject
    var store: Store
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
    }
}
