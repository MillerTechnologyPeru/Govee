//
//  AirPurifier.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

import Bluetooth
import GATT

public extension GoveeAccessory {

    struct AirPurifier: Equatable, Hashable, Sendable, GoveeAccessoryProtocol {

        public static var type: GoveeAccessoryType { .airPurifier }

        public let id: GoveeAdvertisementName

        internal let manufacturerData: ManufacturerData

        public var isActive: Bool {
            manufacturerData.isActive
        }
    }
}

public extension GoveeAccessory.AirPurifier {

    init?<T: GATT.AdvertisementData>(_ advertisementData: T) {
        guard let manufacturerData = advertisementData.manufacturerData,
              let name = advertisementData.localName else {
            return nil
        }
        self.init(name: name, manufacturerData: manufacturerData)
    }

    init?<T: DataContainer>(
        name: String,
        manufacturerData: GATT.ManufacturerSpecificData<T>
    ) {
        guard let name = GoveeAdvertisementName(rawValue: name),
              let manufacturerData = ManufacturerData(manufacturerData) else {
            return nil
        }
        self.init(name: name, manufacturerData: manufacturerData)
    }

    internal init?(
        name: GoveeAdvertisementName,
        manufacturerData: ManufacturerData
    ) {
        guard name.model.type == Self.type else {
            return nil
        }
        self.id = name
        self.manufacturerData = manufacturerData
    }
}

extension GoveeAccessory.AirPurifier {

    struct ManufacturerData: Equatable, Hashable, Sendable {

        internal static var length: Int { 6 }

        internal let companyIdentifier: GoveeCompanyIdentifier

        internal let reserved0: UInt8

        internal let reserved1: UInt8

        internal let reserved2: UInt8

        public let isActive: Bool

        internal let reserved4: UInt8
    }
}

extension GoveeAccessory.AirPurifier.ManufacturerData {

    init?<T: DataContainer>(_ manufacturerSpecificData: GATT.ManufacturerSpecificData<T>) {
        let data = manufacturerSpecificData.additionalData
        guard let companyIdentifier = GoveeCompanyIdentifier(rawValue: manufacturerSpecificData.companyIdentifier.rawValue),
              data.count == Self.length,
              data.first == 0xEC else {
            return nil
        }
        self.companyIdentifier = companyIdentifier
        self.reserved0 = data[1]
        self.reserved1 = data[2]
        self.reserved2 = data[3]
        self.isActive = data[4] != 0x00
        self.reserved4 = data[5]
    }
}
