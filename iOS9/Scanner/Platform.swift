import CSwiftUIBackend

/// The timer Govee uses for request timeouts in Embedded Swift; see Govee's `Sleep.swift`.
@_cdecl("govee_sleep")
func goveeSleep(
    _ milliseconds: UInt,
    _ context: UnsafeMutableRawPointer?,
    _ resume: @convention(c) (UnsafeMutableRawPointer?) -> Void
) {
    sui_dispatch_main_after(milliseconds, resume, context)
}
