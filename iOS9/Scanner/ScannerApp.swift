import SwiftUI
import Bluetooth
import GATT
import DarwinGATT
import Govee

// Scans for Govee devices with the iOS 9 central and connects to one with
// GoveeConnection, to test DarwinGATT on a device.

@main
struct ScannerApp: App {
    let store = Store()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                DeviceList()
            }
            .environmentObject(store)
        }
    }
}

final class Store: ObservableObject {

    let central = DarwinCentral(options: .init(showPowerAlert: true))

    @Published private(set) var state: DarwinBluetoothState = .unknown

    @Published private(set) var devices = [DarwinCentral.Peripheral: Device]()

    /// Scanning stops when the stream is deallocated, so it's kept here.
    private var scanStream: AsyncCentralScan<DarwinCentral>?

    struct Device: Identifiable {
        let peripheral: DarwinCentral.Peripheral
        var accessory: GoveeAccessory
        var rssi: Int

        var id: String { peripheral.id }
    }

    /// Waits for Bluetooth, then scans until cancelled.
    func scan() async {
        while await central.state != .poweredOn {
            state = await central.state
            do {
                try await Task.sleep(nanoseconds: 500_000_000)
            } catch {
                return
            }
        }
        state = .poweredOn
        do {
            let scanStream = central.scan(with: [], filterDuplicates: false)
            self.scanStream = scanStream
            for try await scanData in scanStream {
                guard let accessory = GoveeAccessory(scanData.advertisementData) else {
                    continue
                }
                devices[scanData.peripheral] = Device(
                    peripheral: scanData.peripheral,
                    accessory: accessory,
                    rssi: Int(scanData.rssi)
                )
            }
        } catch { }
        scanStream = nil
    }
}

struct DeviceList: View {
    @EnvironmentObject var store: Store

    var body: some View {
        List {
            ForEach(store.devices.values.sorted { $0.accessory.id.rawValue < $1.accessory.id.rawValue }) { device in
                NavigationLink(destination: DeviceDetail(device: device)) {
                    DeviceRow(device: device)
                }
            }
        }
        .navigationTitle(store.state == .poweredOn ? "Govee" : "Bluetooth \(store.state)")
        .task {
            await store.scan()
        }
    }
}

struct DeviceRow: View {
    let device: Store.Device

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: device.accessory.id.model.rawValue)
                .font(.title3)
            Text(verbatim: "\(device.accessory.id.rawValue)  \(device.rssi) dBm")
                .foregroundColor(.gray)
                .font(.subheadline)
            Text(verbatim: summary(device.accessory))
                .font(.subheadline)
        }
    }
}

struct DeviceDetail: View {
    @EnvironmentObject var store: Store

    let device: Store.Device

    @State private var status = "Not connected"

    @State private var isBusy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: device.accessory.id.rawValue)
                .font(.headline)
            Text(verbatim: summary(device.accessory))
            Text(verbatim: "Peripheral \(device.peripheral.id)")
                .font(.footnote)
                .foregroundColor(.gray)
            Text(verbatim: status)
            if !isBusy {
                Button("Connect") {
                    isBusy = true
                    status = "Connecting…"
                    Task {
                        status = await connect()
                        isBusy = false
                    }
                }
            }
            Spacer()
        }
        .padding()
        .navigationTitle(device.accessory.id.model.rawValue)
    }

    /// Connects, reads a thermometer's live reading, and disconnects.
    func connect() async -> String {
        let model = device.accessory.id.model
        do {
            let connection = try await store.central.connect(to: device.peripheral, model: model)
            var result = "Connected (\(connection.security == .encrypted ? "encrypted" : "plaintext"))"
            if case .thermometer = device.accessory {
                let reply = try await connection.send(GoveeQuery.thermometerReading)
                if let reading = reply.thermometerReading {
                    result += "\nLive: \(tenths(reading.temperature))°C, \(tenths(reading.humidity))%, battery \(reading.batteryLevel)%"
                }
            }
            await connection.disconnect()
            return result + "\nDisconnected"
        } catch let error as GoveeConnectionError {
            return "Failed: \(error)"
        } catch let error as CentralError {
            return "Failed: \(error)"
        } catch let error as DarwinCentralError {
            return "Failed: \(error)"
        } catch {
            return "Failed"
        }
    }
}

func summary(_ accessory: GoveeAccessory) -> String {
    switch accessory {
    case .thermometer(let thermometer):
        return "\(tenths(thermometer.temperature))°C, \(tenths(thermometer.humidity))%, battery \(thermometer.batteryLevel)%"
    case .heater(let heater):
        return heater.isActive ? "Heater on" : "Heater off"
    case .kettle(let kettle):
        switch kettle.state {
        case .idle: return "Kettle idle"
        case .heating: return "Kettle heating"
        case .keepingWarm: return "Kettle keeping warm"
        case .finishedBoiling: return "Kettle boiled"
        }
    case .riceCooker(let riceCooker):
        return riceCooker.isActive ? "Cooking" : "Idle"
    case .airPurifier(let airPurifier):
        return airPurifier.isActive ? "Purifier on" : "Purifier off"
    }
}

/// Formats a value with one decimal, such as 23.46 as "23.5".
func tenths(_ value: Float) -> String {
    let rounded = Int((value * 10).rounded())
    let sign = rounded < 0 ? "-" : ""
    return "\(sign)\(abs(rounded) / 10).\(abs(rounded) % 10)"
}
