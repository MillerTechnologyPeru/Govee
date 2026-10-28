//
//  ThermometerDetailView.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

import Foundation
import SwiftUI
import Govee

struct ThermometerDetailView: View {

    @EnvironmentObject
    var store: AccessoryManager

    let id: GoveeAccessory.ID

    @State
    private var status: AccessoryManager.ThermometerStatus?

    @State
    private var isBusy = false

    @State
    private var error: String?

    var body: some View {
        Form {
            DeviceConnectionSection(id: id, isBusy: isBusy, error: error, refresh: refresh)
            if let reading = status?.reading {
                Section("Reading") {
                    Text("Temperature: \(reading.temperature, specifier: "%.2f") °C")
                    Text("Humidity: \(reading.humidity, specifier: "%.2f")%")
                    Text("Battery: \(reading.batteryLevel)%")
                }
            }
            if let firmware = status?.firmwareVersion {
                Section("Device") {
                    Text("Firmware: \(firmware)")
                }
            }
        }
        .task { refresh() }
    }
}

private extension ThermometerDetailView {

    var action: DeviceAction {
        DeviceAction(isBusy: $isBusy, error: $error)
    }

    func refresh() {
        action {
            status = try await store.thermometerStatus(id)
        }
    }
}
