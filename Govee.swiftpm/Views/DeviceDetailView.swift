//
//  DeviceDetailView.swift
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

/// Connects to the selected device and shows its controls.
struct DeviceDetailView: View {

    @EnvironmentObject
    var store: AccessoryManager

    let accessory: GoveeAccessory

    var body: some View {
        content
            .navigationTitle(accessory.id.model.rawValue)
            .onDisappear {
                let id = accessory.id
                Task {
                    await store.disconnect(id)
                }
            }
    }
}

private extension DeviceDetailView {

    @ViewBuilder
    var content: some View {
        switch accessory {
        case let .airPurifier(value):
            AirPurifierDetailView(id: value.id)
        case let .heater(value):
            HeaterDetailView(id: value.id)
        case let .kettle(value):
            KettleDetailView(id: value.id)
        case let .thermometer(value):
            ThermometerDetailView(id: value.id)
        case .riceCooker:
            Text("Controlling the rice cooker is not supported yet.")
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Supporting Views

/// Connection state, errors and refresh, shared by the device views.
struct DeviceConnectionSection: View {

    @EnvironmentObject
    var store: AccessoryManager

    let id: GoveeAccessory.ID

    let isBusy: Bool

    let error: String?

    let refresh: () -> ()

    var body: some View {
        Section {
            HStack {
                Text(verbatim: id.rawValue)
                    .foregroundColor(.gray)
                Spacer()
                if isBusy {
                    ProgressView()
                } else {
                    Text(store.isConnected(id) ? "Connected" : "Not connected")
                        .foregroundColor(store.isConnected(id) ? .green : .gray)
                }
            }
            Button("Refresh", action: refresh)
                .disabled(isBusy)
            if let error {
                Text(verbatim: error)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
        }
    }
}

/// Runs a device action, tracking progress and errors.
@MainActor
struct DeviceAction {

    let isBusy: Binding<Bool>

    let error: Binding<String?>

    func callAsFunction(_ action: @escaping @MainActor () async throws -> ()) {
        Task { @MainActor in
            isBusy.wrappedValue = true
            defer { isBusy.wrappedValue = false }
            do {
                try await action()
                error.wrappedValue = nil
            }
            catch {
                self.error.wrappedValue = errorDescription(error)
            }
        }
    }
}
