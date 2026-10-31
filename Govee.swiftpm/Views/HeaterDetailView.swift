//
//  HeaterDetailView.swift
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

struct HeaterDetailView: View {

    typealias Command = GoveeAccessory.Heater.Command

    @EnvironmentObject
    var store: AccessoryManager

    let id: GoveeAccessory.ID

    @State
    private var status: AccessoryManager.HeaterStatus?

    /// Last mode set from this screen; the heater's mode cannot be queried yet.
    @State
    private var mode: ModeOption?

    @State
    private var isDisplayOn = true

    @State
    private var isLocked = false

    @State
    private var isBusy = false

    @State
    private var error: String?

    var body: some View {
        Form {
            DeviceConnectionSection(id: id, isBusy: isBusy, error: error, refresh: refresh)
            if let status {
                Section("Power") {
                    Toggle("On", isOn: Binding(
                        get: { status.isOn },
                        set: { isOn in send(.power(isOn)) { self.status?.isOn = isOn } }
                    ))
                }
                Section("Mode") {
                    Picker("Mode", selection: Binding(
                        get: { mode },
                        set: { option in
                            guard let option else { return }
                            send(.mode(option.mode)) { mode = option }
                        }
                    )) {
                        ForEach(ModeOption.allCases) {
                            Text($0.title).tag(Optional($0))
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("Auto mode is not supported yet.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                Section("Settings") {
                    Toggle("Display", isOn: Binding(
                        get: { isDisplayOn },
                        set: { isOn in send(.display(isOn)) { isDisplayOn = isOn } }
                    ))
                    Toggle("Lock", isOn: Binding(
                        get: { isLocked },
                        set: { isOn in send(.lock(isOn)) { isLocked = isOn } }
                    ))
                }
                if let temperature = status.temperature, let humidity = status.humidity {
                    Section("Linked Thermometer") {
                        Text("Temperature: \(temperature, specifier: "%.1f") °C")
                        Text("Humidity: \(humidity, specifier: "%.1f")%")
                    }
                }
            }
        }
        .task { refresh() }
    }
}

private extension HeaterDetailView {

    var action: DeviceAction {
        DeviceAction(isBusy: $isBusy, error: $error)
    }

    func refresh() {
        action {
            status = try await store.heaterStatus(id)
        }
    }

    func send(_ command: Command, update: @escaping () -> ()) {
        action {
            try await store.send(command, to: id)
            update()
        }
    }

    enum ModeOption: String, CaseIterable, Identifiable {

        case low
        case medium
        case high
        case fan

        var id: String { rawValue }

        var mode: GoveeAccessory.Heater.Mode {
            switch self {
            case .low: return .heat(level: 1)
            case .medium: return .heat(level: 2)
            case .high: return .heat(level: 3)
            case .fan: return .fan
            }
        }

        var title: LocalizedStringKey {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .fan: return "Fan"
            }
        }
    }
}
