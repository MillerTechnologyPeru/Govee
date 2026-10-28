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
        case .riceCooker(let riceCooker):
            return AnyView(RiceCooker(advertisement: riceCooker))
        case .airPurifier(let airPurifier):
            return AnyView(AirPurifier(advertisement: airPurifier))
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
                    Text(verbatim: advertisement.id.model.rawValue)
                        .font(.title3)
                }
                Text(verbatim: advertisement.id.rawValue)
                    .foregroundColor(.gray)
                    .font(.subheadline)
                Text("Battery: \(batteryLevel)%")
                    .font(.subheadline)
                Text("Temperature: \(temperature)C°")
                    .font(.subheadline)
                Text("Humidity: \(humidity)%")
                    .font(.subheadline)
            }
        }
    }
}

private extension GoveeAdvertisementRow.Thermometer {
    
    var batteryLevel: String {
        advertisement.batteryLevel.description
    }
    
    var temperature: String {
        format(advertisement.temperature)
    }
    
    var humidity: String {
        format(advertisement.humidity)
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
                    Text(verbatim: advertisement.id.model.rawValue)
                        .font(.title3)
                }
                Text(verbatim: advertisement.id.rawValue)
                    .foregroundColor(.gray)
                    .font(.subheadline)
                Text("Active: \(advertisement.isActive)")
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
                    Text(verbatim: advertisement.id.model.rawValue)
                        .font(.title3)
                }
                Text(verbatim: advertisement.id.rawValue)
                    .foregroundColor(.gray)
                    .font(.subheadline)
                Text("State: \(advertisement.state)")
            }
        }
    }
}

extension GoveeAdvertisementRow {
    
    struct RiceCooker: View {
        
        let advertisement: GoveeAccessory.RiceCooker
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "cooktop.fill")
                    Text(verbatim: advertisement.id.model.rawValue)
                        .font(.title3)
                }
                Text(verbatim: advertisement.id.rawValue)
                    .foregroundColor(.gray)
                    .font(.subheadline)
                Text("Cooking: \(advertisement.isActive)")
                    .font(.subheadline)
            }
        }
    }
}

extension GoveeAdvertisementRow {
    
    struct AirPurifier: View {
        
        let advertisement: GoveeAccessory.AirPurifier
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "wind")
                    Text(verbatim: advertisement.id.model.rawValue)
                        .font(.title3)
                }
                Text(verbatim: advertisement.id.rawValue)
                    .foregroundColor(.gray)
                    .font(.subheadline)
                Text("Active: \(advertisement.isActive)")
                    .font(.subheadline)
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
