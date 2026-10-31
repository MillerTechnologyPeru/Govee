# Govee for iOS 9

Govee apps for iOS 9 on 32-bit devices (iPhone 4S, armv7), built with
Embedded Swift.

- `Scanner`: lists nearby Govee devices with their advertised readings, and
  connects to one with `GoveeConnection` (including the encrypted handshake),
  reading a thermometer's live values.

They use [SwiftUI-iOS9](https://github.com/colemancda/SwiftUI-iOS9) for the
UI, its Bluetooth central (`DarwinGATT`) and its concurrency runtime fixes,
and this package's `Govee` library with the Bluetooth and GATT versions
SwiftPM resolves for it.

## Building

Requirements:

- A [SwiftUI-iOS9](https://github.com/colemancda/SwiftUI-iOS9) checkout, by
  default next to this repository (`SWIFTUI_IOS9`), with its iOS 9.3 SDK
  (`make sdk` there). Its README lists the toolchain and other requirements.
- An Apple Development signing identity (`SIGN_IDENTITY`) and its team
  (`TEAM_ID`). iOS 9 only gives an app Bluetooth scan results without a
  service filter while it's in the foreground, and only treats an app as
  foreground if its signature has a team identifier, which ad-hoc signatures
  don't. AppSync on the device accepts the signature without a provisioning
  profile.

```bash
make                     # build Scanner
make install             # copy it to the device
make APP=Other install   # build the app in Other/
```

The first build checks out Bluetooth and GATT with `swift package resolve`
and rebuilds the concurrency runtime, so it needs network access. `make
install` works like SwiftUI-iOS9's: a jailbroken device with OpenSSH, a USB
tunnel and an SSH config (`SSH_CONF`, `SSH_HOST`).

Govee devices stop advertising while another phone's Govee app is connected
to them.

## Porting notes

- The `Govee` library calls `govee_sleep` for timeouts, since Embedded Swift
  has no clocks; apps implement it on the main queue (`Scanner/Platform.swift`).
- Keep the scan stream (`AsyncCentralScan`) in a property: scanning stops when
  it is deallocated.
