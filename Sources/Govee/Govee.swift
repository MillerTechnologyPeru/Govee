import Foundation
import Bluetooth

public enum GoveeAdvertisement: Equatable, Hashable {
    
    case thermometer(Thermometer)
}
