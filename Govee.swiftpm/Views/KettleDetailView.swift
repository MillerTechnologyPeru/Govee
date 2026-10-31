//
//  KettleDetailView.swift
//
//
//  Created by Alsey Coleman Miller on 10/28/26.
//

#if canImport(FoundationEmbedded)
import FoundationEmbedded
#else
import Foundation
#endif
import SwiftUI
import Govee

struct KettleDetailView: View {

    typealias Command = GoveeAccessory.Kettle.Command

    @EnvironmentObject
    var store: AccessoryManager

    let id: GoveeAccessory.ID

    @State
    private var status: AccessoryManager.KettleStatus?

    /// Target temperature in degrees Fahrenheit.
    @State
    private var target: Double = 180

    @State
    private var isBusy = false

    @State
    private var error: String?

    var body: some View {
        Form {
            DeviceConnectionSection(id: id, isBusy: isBusy, error: error, refresh: refresh)
            if let status {
                Section("Status") {
                    Text("Water: \(status.temperature, specifier: "%.0f") °F")
                    Text(status.isHeating ? "Heating" : "Idle")
                        .foregroundColor(status.isHeating ? .orange : .gray)
                    HStack {
                        Button("Start") { send(.heating(true)) }
                            .disabled(status.isHeating)
                        Spacer()
                        Button("Cancel", role: .destructive) { send(.heating(false)) }
                            .disabled(status.isHeating == false)
                    }
                    .buttonStyle(.borderless)
                }
                Section("Temperature") {
                    Stepper("Target: \(Int(target)) °F", value: $target, in: 104 ... 212, step: 1)
                    Button("Set Target") { send(.targetTemperature(fahrenheit: Float(target))) }
                    Button("Boil (212 °F)") { send(.boil) }
                }
                Section("Presets") {
                    Button("Tea 1") { send(.preset(.tea, index: 1)) }
                    Button("Tea 2") { send(.preset(.tea, index: 2)) }
                    Button("Tea 3") { send(.preset(.tea, index: 3)) }
                    Button("Coffee 1") { send(.preset(.coffee, index: 1)) }
                    Button("DIY 1") { send(.preset(.diy, index: 1)) }
                }
                Section("Keep Warm") {
                    Toggle("Keep Warm (\(status.keepWarmMinutes) min)", isOn: Binding(
                        get: { status.isKeepWarmOn },
                        set: { isOn in send(.keepWarm(isOn, minutes: status.keepWarmMinutes)) }
                    ))
                }
            }
        }
        .task { refresh() }
    }
}

private extension KettleDetailView {

    var action: DeviceAction {
        DeviceAction(isBusy: $isBusy, error: $error)
    }

    func refresh() {
        action {
            status = try await store.kettleStatus(id)
        }
    }

    /// Sends the command, then reloads the status.
    func send(_ command: Command) {
        action {
            try await store.send(command, to: id)
            status = try await store.kettleStatus(id)
        }
    }
}
