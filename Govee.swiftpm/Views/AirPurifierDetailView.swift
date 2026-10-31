//
//  AirPurifierDetailView.swift
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

struct AirPurifierDetailView: View {

    typealias Command = GoveeAccessory.AirPurifier.Command

    @EnvironmentObject
    var store: AccessoryManager

    let id: GoveeAccessory.ID

    @State
    private var status: AccessoryManager.AirPurifierStatus?

    @State
    private var brightness: Double = 50

    @State
    private var color = Color.white

    @State
    private var isDisplayOn = true

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
                        set: { isOn in send(.power(isOn)) { $0.isOn = isOn } }
                    ))
                }
                Section("Fan") {
                    Picker("Mode", selection: Binding(
                        get: { ModeOption(status.mode) },
                        set: { option in
                            guard let mode = option?.mode else { return }
                            send(.mode(mode)) { $0.mode = mode }
                        }
                    )) {
                        ForEach(ModeOption.allCases) {
                            Text($0.title).tag(Optional($0))
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Night Light") {
                    Toggle("On", isOn: Binding(
                        get: { status.isNightLightOn },
                        set: { isOn in send(.nightLight(isOn)) { $0.isNightLightOn = isOn } }
                    ))
                    VStack(alignment: .leading) {
                        Text("Brightness \(Int(brightness))%")
                        Slider(value: $brightness, in: 0 ... 100, step: 10) { isEditing in
                            guard isEditing == false else { return }
                            let value = UInt8(brightness)
                            send(.nightLightBrightness(value)) { $0.nightLightBrightness = value }
                        }
                    }
                    // iOS 9 has no color picker.
                    #if canImport(UIKit)
                    ColorPicker("Color", selection: $color, supportsOpacity: false)
                    Button("Apply Color") {
                        let rgb = color.rgb
                        send(.nightLightColor(red: rgb.red, green: rgb.green, blue: rgb.blue)) {
                            $0.nightLightColor = rgb
                        }
                    }
                    #endif
                }
                Section("Display") {
                    Toggle("Always On", isOn: Binding(
                        get: { isDisplayOn },
                        set: { isOn in send(.display(isOn)) { _ in isDisplayOn = isOn } }
                    ))
                }
            }
        }
        .task { refresh() }
    }
}

private extension AirPurifierDetailView {

    var action: DeviceAction {
        DeviceAction(isBusy: $isBusy, error: $error)
    }

    func refresh() {
        action {
            let status = try await store.airPurifierStatus(id)
            self.status = status
            self.brightness = Double(status.nightLightBrightness)
            self.color = Color(rgb: status.nightLightColor)
        }
    }

    func send(_ command: Command, update: @escaping (inout AccessoryManager.AirPurifierStatus) -> ()) {
        action {
            try await store.send(command, to: id)
            if var status {
                update(&status)
                self.status = status
            }
        }
    }

    enum ModeOption: String, CaseIterable, Identifiable {

        case low
        case medium
        case high
        case sleep
        case turbo

        var id: String { rawValue }

        init?(_ mode: GoveeAccessory.AirPurifier.Mode) {
            switch mode {
            case .manual(speed: 1): self = .low
            case .manual(speed: 2): self = .medium
            case .manual(speed: 3): self = .high
            case .sleep: self = .sleep
            case .turbo: self = .turbo
            default: return nil
            }
        }

        var mode: GoveeAccessory.AirPurifier.Mode {
            switch self {
            case .low: return .manual(speed: 1)
            case .medium: return .manual(speed: 2)
            case .high: return .manual(speed: 3)
            case .sleep: return .sleep
            case .turbo: return .turbo
            }
        }

        var title: LocalizedStringKey {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .sleep: return "Sleep"
            case .turbo: return "Turbo"
            }
        }
    }
}

// MARK: - Color

extension Color {

    init(rgb: (red: UInt8, green: UInt8, blue: UInt8)) {
        self.init(red: Double(rgb.red) / 255, green: Double(rgb.green) / 255, blue: Double(rgb.blue) / 255)
    }

    #if canImport(UIKit)
    var rgb: (red: UInt8, green: UInt8, blue: UInt8) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        func byte(_ value: CGFloat) -> UInt8 { UInt8(max(0, min(255, (value * 255).rounded()))) }
        return (byte(red), byte(green), byte(blue))
    }
    #endif
}
