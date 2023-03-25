//
//  GoveeAdvertisementRow.swift
//  
//
//  Created by Alsey Coleman Miller on 3/25/23.
//

import Foundation
import SwiftUI
import Govee

struct GoveeAdvertisementRow: View {
    
    let advertisement: GoveeAdvertisement
    
    var body: some View {
        switch advertisement {
        case .thermometer(let thermometer):
            return AnyView(Thermometer(advertisement: thermometer))
        }
    }
}

extension GoveeAdvertisementRow {
    
    struct Thermometer: View {
        
        let advertisement: GoveeAdvertisement.Thermometer
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(verbatim: model)
                    .font(.title3)
                Text(verbatim: address)
                    .foregroundColor(.gray)
                    .font(.subheadline)
                Text("Battery: \(batteryLevel) %")
                    .font(.subheadline)
                Text("Temperature: \(temperature) C°")
                    .font(.subheadline)
                Text("Humidity: \(humidity) %")
                    .font(.subheadline)
            }
        }
    }
}

private extension GoveeAdvertisementRow.Thermometer {
    
    var model: String {
        advertisement.name.model.rawValue
    }
    
    var address: String {
        advertisement.name.address.rawValue
    }
    
    var batteryLevel: String {
        advertisement.manufacturingData.batteryLevel.description
    }
    
    var temperature: String {
        format(advertisement.manufacturingData.temperature)
    }
    
    var humidity: String {
        format(advertisement.manufacturingData.humidity)
    }
    
    func format(_ float: Float) -> String {
        String(format: "%.2f", float)
    }
}

#if DEBUG
struct GoveeAdvertisementRow_Previews: PreviewProvider {
    static var previews: some View {
        GoveeAdvertisementRow(advertisement: .thermometer(.mock))
    }
}
#endif
