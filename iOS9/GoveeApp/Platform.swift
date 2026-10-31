import CSwiftUIBackend
import FoundationEmbedded

/// The timer Govee uses for request timeouts in Embedded Swift; see Govee's `Sleep.swift`.
@_cdecl("govee_sleep")
func goveeSleep(
    _ milliseconds: UInt,
    _ context: UnsafeMutableRawPointer?,
    _ resume: @convention(c) (UnsafeMutableRawPointer?) -> Void
) {
    sui_dispatch_main_after(milliseconds, resume, context)
}

// MARK: - Date

// swift-embedded-foundation has no clock or local time zone, by design, so
// the current time and local formatting come from iOS's C library. On armv7,
// `time_t`, `long` and `int` are all 32 bits.

@_extern(c, "gettimeofday")
private func gettimeofday(_ time: UnsafeMutableRawPointer, _ zone: UnsafeMutableRawPointer?) -> Int32

@_extern(c, "localtime_r")
private func localtime_r(_ time: UnsafePointer<Int>, _ result: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer?

extension Date {

    /// The current time.
    init() {
        // struct timeval { time_t tv_sec; suseconds_t tv_usec; }
        var time: (Int, Int32) = (0, 0)
        _ = withUnsafeMutableBytes(of: &time) { gettimeofday($0.baseAddress!, nil) }
        self.init(timeIntervalSince1970: Double(time.0) + Double(time.1) / 1_000_000)
    }

    static var now: Date {
        Date()
    }

    enum DateStyle {
        case omitted, numeric, abbreviated, long, complete
    }

    enum TimeStyle {
        case omitted, shortened, standard, complete
    }

    /// Formats the date in the device's time zone, in US English like
    /// Foundation's `formatted(date:time:)`, such as "Oct 31, 2026 at 10:59 AM".
    func formatted(date dateStyle: DateStyle, time timeStyle: TimeStyle) -> String {
        // struct tm: 9 ints, then long tm_gmtoff and char *tm_zone.
        var fields = (Int32(0), Int32(0), Int32(0), Int32(0), Int32(0), Int32(0), Int32(0), Int32(0), Int32(0), 0, 0)
        var seconds = Int(timeIntervalSince1970.rounded(.down))
        _ = withUnsafeMutableBytes(of: &fields) { localtime_r(&seconds, $0.baseAddress!) }
        let (second, minute, hour, day, month, year, weekday) =
            (Int(fields.0), Int(fields.1), Int(fields.2), Int(fields.3), Int(fields.4), Int(fields.5) + 1900, Int(fields.6))

        let months = ["January", "February", "March", "April", "May", "June", "July",
                      "August", "September", "October", "November", "December"]
        let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        func twoDigits(_ value: Int) -> String {
            value < 10 ? "0\(value)" : "\(value)"
        }

        let datePart: String
        switch dateStyle {
        case .omitted:
            datePart = ""
        case .numeric:
            datePart = "\(month + 1)/\(day)/\(year)"
        case .abbreviated:
            datePart = "\(String(months[month].prefix(3))) \(day), \(year)"
        case .long:
            datePart = "\(months[month]) \(day), \(year)"
        case .complete:
            datePart = "\(weekdays[weekday]), \(months[month]) \(day), \(year)"
        }
        let hour12 = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "AM" : "PM"
        let timePart: String
        switch timeStyle {
        case .omitted:
            timePart = ""
        case .shortened:
            timePart = "\(hour12):\(twoDigits(minute)) \(period)"
        case .standard, .complete:
            timePart = "\(hour12):\(twoDigits(minute)):\(twoDigits(second)) \(period)"
        }
        if datePart.isEmpty || timePart.isEmpty {
            return datePart + timePart
        }
        return datePart + (dateStyle == .numeric ? ", " : " at ") + timePart
    }
}
