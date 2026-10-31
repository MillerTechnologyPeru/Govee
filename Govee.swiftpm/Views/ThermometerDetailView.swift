//
//  ThermometerDetailView.swift
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
#if canImport(Charts)
import Charts
#endif
import Govee

struct ThermometerDetailView: View {

    @EnvironmentObject
    var store: AccessoryManager

    let id: GoveeAccessory.ID

    @State
    private var status: AccessoryManager.ThermometerStatus?

    @State
    private var range = HistoryRange.hour

    @State
    private var history: History?

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
            Section("History") {
                Picker("Range", selection: $range) {
                    ForEach(HistoryRange.allCases) {
                        Text($0.title).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                Button("Load History") { loadHistory() }
                    .disabled(isBusy)
                if let history {
                    HistoryView(history: history)
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

    func loadHistory() {
        let range = self.range
        action {
            let readings = try await store.thermometerHistory(id, minutes: range.minutes)
            history = History(date: Date(), readings: readings)
        }
    }
}

// MARK: - History

private extension ThermometerDetailView {

    enum HistoryRange: String, CaseIterable, Identifiable {

        case hour
        case day
        case week

        var id: String { rawValue }

        var minutes: UInt16 {
            switch self {
            case .hour: return 60
            case .day: return 24 * 60
            case .week: return 7 * 24 * 60
            }
        }

        var title: LocalizedStringKey {
            switch self {
            case .hour: return "1 Hour"
            case .day: return "1 Day"
            case .week: return "1 Week"
            }
        }
    }

    /// Readings downloaded at a point in time.
    struct History: Equatable {

        let date: Date

        let readings: [GoveeAccessory.Thermometer.HistoryReading]

        func date(for reading: GoveeAccessory.Thermometer.HistoryReading) -> Date {
            date.addingTimeInterval(-60 * Double(reading.minutesAgo))
        }
    }

    struct HistoryView: View {

        let history: History

        var body: some View {
            let readings = history.readings
            if let first = readings.first {
                let temperatures = readings.map { $0.temperature }
                let humidity = readings.map { $0.humidity }
                Text("\(readings.count) readings since \(history.date(for: first).formatted(date: .abbreviated, time: .shortened))")
                Text("Temperature: \(temperatures.min()!, specifier: "%.1f") – \(temperatures.max()!, specifier: "%.1f") °C")
                Text("Humidity: \(humidity.min()!, specifier: "%.1f") – \(humidity.max()!, specifier: "%.1f")%")
                #if canImport(Charts)
                if #available(iOS 16, *) {
                    HistoryChart(history: history)
                        .frame(height: 200)
                }
                #endif
            } else {
                Text("No readings stored")
                    .foregroundColor(.gray)
            }
        }
    }
}

#if canImport(Charts)
@available(iOS 16, *)
private struct HistoryChart: View {

    let history: ThermometerDetailView.History

    var body: some View {
        Chart(history.readings, id: \.minutesAgo) { reading in
            LineMark(
                x: .value("Time", history.date(for: reading)),
                y: .value("Temperature", reading.temperature)
            )
            .foregroundStyle(.orange)
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartYAxisLabel("°C")
    }
}
#endif
