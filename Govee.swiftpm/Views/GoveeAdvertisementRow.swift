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
                Text(verbatim: advertisement.name.model.rawValue)
                    .font(.title3)
                Text(verbatim: advertisement.name.address.rawValue)
                    .foregroundColor(.gray)
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
