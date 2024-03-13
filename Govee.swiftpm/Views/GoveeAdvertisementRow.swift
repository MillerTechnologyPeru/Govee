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
    
    let advertisement: GoveeAccessory
    
    var body: some View {
        switch advertisement {
        case .thermometer(let thermometer):
            return AnyView(Thermometer(advertisement: thermometer))
        case .heater(let heater):
            return AnyView(Heater(advertisement: heater))
        case .kettle(let kettle):
            return AnyView(Kettle(advertisement: kettle))
        }
    }
}

extension GoveeAdvertisementRow {
    
    struct Thermometer: View {
        
        let advertisement: GoveeAccessory.Thermometer
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "thermometer")
                    Text(verbatim: advertisement.model.rawValue)
                        .font(.title3)
                }
                Text(verbatim: advertisement.name.rawValue)
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
    
    var batteryLevel: String {
        advertisement.manufacturerData.batteryLevel.description
    }
    
    var temperature: String {
        format(advertisement.manufacturerData.temperature)
    }
    
    var humidity: String {
        format(advertisement.manufacturerData.humidity)
    }
    
    func format(_ float: Float) -> String {
        String(format: "%.2f", float)
    }
}

extension GoveeAdvertisementRow {
    
    struct Heater: View {
        
        let advertisement: GoveeAccessory.Heater
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "heater.vertical")
                    Text(verbatim: advertisement.model.rawValue)
                        .font(.title3)
                }
                Text(verbatim: advertisement.name.rawValue)
                    .foregroundColor(.gray)
                    .font(.subheadline)
                Text("Heating: \(advertisement.manufacturerData.isActive)")
                    .font(.subheadline)
            }
        }
    }
}

extension GoveeAdvertisementRow {
    
    struct Kettle: View {
        
        let advertisement: GoveeAccessory.Kettle
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "cup.and.saucer.fill")
                    Text(verbatim: advertisement.model.rawValue)
                        .font(.title3)
                }
                Text(verbatim: advertisement.name.rawValue)
                    .foregroundColor(.gray)
                    .font(.subheadline)
                Text("State: \(advertisement.manufacturerData.state)")
            }
        }
    }
}

#if DEBUG
struct GoveeAdvertisementRow_Previews: PreviewProvider {
    static var previews: some View {
        GoveeAdvertisementRow(advertisement: .thermometer(.mock))
    }
}
#endif
