//
//  Sleep.swift
//
//
//  Created by Alsey Coleman Miller on 10/30/26.
//

#if hasFeature(Embedded)
// Embedded Swift does not import the concurrency module implicitly.
import _Concurrency
#endif

/// Suspends the current task for at least the given number of seconds.
internal func sleep(seconds: Double) async {
    #if hasFeature(Embedded)
    await withUnsafeContinuation { (continuation: UnsafeContinuation<Void, Never>) in
        let context = Unmanaged.passRetained(SleepContinuation(continuation)).toOpaque()
        govee_sleep(UInt(seconds * 1000), context) { context in
            Unmanaged<SleepContinuation>.fromOpaque(context!).takeRetainedValue().continuation.resume()
        }
    }
    #else
    try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    #endif
}

#if hasFeature(Embedded)
/// Platform timer used for timeouts.
///
/// Embedded Swift has no clock (`Task.sleep` is unavailable), so the platform implements
/// `void govee_sleep(unsigned long milliseconds, void *context, void (*resume)(void *context))`,
/// calling `resume` once, on the thread that runs the concurrency executor, after the time has passed.
/// On Darwin this is `dispatch_after_f` on the main queue.
///
/// Only pointer-sized arguments: a bare-metal target's C calling convention may differ from the
/// platform's for 64-bit integers.
@_extern(c, "govee_sleep")
internal func govee_sleep(
    _ milliseconds: UInt,
    _ context: UnsafeMutableRawPointer?,
    _ resume: @convention(c) (UnsafeMutableRawPointer?) -> ()
)

private final class SleepContinuation {

    let continuation: UnsafeContinuation<Void, Never>

    init(_ continuation: UnsafeContinuation<Void, Never>) {
        self.continuation = continuation
    }
}
#endif
