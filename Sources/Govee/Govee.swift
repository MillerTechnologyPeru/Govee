import Foundation
import Bluetooth
import GATT

public enum GoveeAdvertisement: Equatable, Hashable {
    
    case thermometer(Thermometer)
}

extension GoveeAdvertisement: Identifiable {
    
    public var id: BluetoothAddress {
        switch self {
        case .thermometer(let thermometer):
            return thermometer.name.address
        }
    }
}

public extension GoveeAdvertisement {
    
    init?<T: GATT.AdvertisementData>(_ advertisementData: T) {
        if let thermometer = Thermometer(advertisementData) {
            self = .thermometer(thermometer)
        } else {
            return nil
        }
    }
}
