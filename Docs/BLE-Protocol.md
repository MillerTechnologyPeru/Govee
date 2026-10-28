# Govee BLE Protocol

Reverse-engineered notes on how Govee devices communicate over Bluetooth Low Energy, as implemented by this library. Govee publishes no specification; everything here comes from captures of real devices and from community sources, and each claim notes where it comes from.

Status labels used below:

- **Verified**: decoded from captures of real devices and covered by tests in `Tests/GoveeTests`.
- **Observed**: seen on real devices but not yet implemented or fully understood.
- **Community**: taken from third-party reverse engineering, not yet confirmed on our devices.

## Contents

1. [Device identification](#1-device-identification)
2. [Advertisements](#2-advertisements)
3. [GATT services](#3-gatt-services)
4. [Packet format](#4-packet-format)
5. [Status queries](#5-status-queries)
6. [Commands](#6-commands)
7. [Capturing data](#7-capturing-data)
8. [Open questions](#8-open-questions)
9. [References](#9-references)

## 1. Device identification

Devices are identified by their advertised local name, which encodes the model and the last two bytes of an address. **Verified.**

| Format | Example | Model | Suffix |
|---|---|---|---|
| `GV` + model + `_` + suffix | `GVH5072_CF9C` | H5072 | `CF9C` |
| `GV` + model + suffix | `GVH71732ADB` | H7173 | `2ADB` |
| `ihoment_` + model + `_` + suffix | `ihoment_H7135_9F73` | H7135 | `9F73` |

The suffix is 4 hexadecimal digits: the last two bytes of the Bluetooth address. The Govee app shows the Wi-Fi MAC address instead, which can differ. The H712C advertises suffix `E78A` (Bluetooth `E8:06:90:0C:E7:8A`) while the app reports `E8:06:90:0C:E7:88`. Both addresses can be read with status query `AA 07`, see [section 5](#5-status-queries).

Parsing lives in `GoveeAdvertisementName` (`Sources/Govee/AdvertisementName.swift`). A model must be listed in `GoveeModel` for its name to parse; unknown models are dropped.

## 2. Advertisements

State is broadcast in the manufacturer specific data of advertisements or scan responses. On Apple platforms CoreBluetooth merges the two, so the name and the manufacturer data arrive together.

Devices stop advertising while a phone is connected to them, for example while the Govee app is open. Close the app before scanning.

### 2.1 Company identifiers

The 16-bit company identifier at the start of the manufacturer data varies by device family and firmware.

| Identifier | Bytes on air | Used by | Status |
|---|---|---|---|
| `0xEC88` | `88 EC` | Thermometers | Verified |
| `0x8802` | `02 88` | Heaters, rice cooker, H7175 kettle | Verified |
| `0x8803` | `03 88` | H7173 kettle (older firmware), H712C purifier | Verified |
| `0x8843` | `43 88` | H7173 kettle and H7135 heater (newer firmware, 2026) | Verified |

`0x8843` is `0x8803` with bit `0x40` set. The same kettle advertised `0x8803` in earlier captures and `0x8843` on 2026-10-28, so the identifier can change with a firmware update. The meaning of the bit is unknown. The accepted set is `GoveeCompanyIdentifier` in `Sources/Govee/Extensions/CompanyIdentifier.swift`.

### 2.2 Thermometers (H5072, H5075 family)

Company `0xEC88`, at least 6 bytes of data after the identifier. Thermometers also advertise the 16-bit service UUID `0xEC88`. **Verified** for H5072.

| Byte | Meaning |
|---|---|
| 0 | Reserved (`00`) |
| 1–3 | Packed temperature and humidity, 24-bit big endian |
| 4 | Battery level, 0–100 |
| 5 | Reserved (`00`) |

Decoding the packed value `v`:

- temperature (°C) = `v / 10000`
- humidity (%) = `(v % 1000) / 10`

Example, `GVH5072_CF9C` on 2026-10-28: `88 EC | 00 03 AF E8 25 00`. `0x03AFE8` = 241640, so 24.164 °C, 64.0 % humidity, battery `0x25` = 37 %.

Some thermometer advertisements append an Apple iBeacon after these 6 bytes (`4C 00 02 15` followed by UUID `494E5445-4C4C-495F-524F-434B535F4857`, major, minor and TX power). The decoder ignores bytes past the first 6.

Other sensor models such as H5074 and H5179 are believed to use different layouts (separate little endian temperature and humidity fields) and are not decoded yet. Negative temperatures have not been captured. **Community.**

### 2.3 Appliances (heater, purifier)

Company `0x8802`, `0x8803` or `0x8843`, exactly 6 bytes starting with `0xEC`. **Verified.**

| Byte | Meaning |
|---|---|
| 0 | `EC` marker |
| 1 | Reserved (`00`) |
| 2 | Unknown (`01` on older firmware, `02` on newer) |
| 3 | Unknown (`01`) |
| 4 | Power: `00` off, otherwise on |
| 5 | Reserved (`00`) |

| Device | State | Data |
|---|---|---|
| H712C purifier | off | `03 88 EC 00 01 01 00 00` |
| H712C purifier | on | `03 88 EC 00 01 01 01 00` |
| H7131 heater | on | `02 88 EC 00 01 01 01 00` |
| H7135 heater | fan only | `43 88 EC 00 02 01 01 00` |
| H7135 heater | heat level 1 | `43 88 EC 00 02 01 01 00` |

Fan and heat modes advertise identical data, so the advertisement only tells you whether the device is on. Modes, fan speed and heat level need a GATT connection.

### 2.4 Kettles (H7170, H7171, H7173, H7175)

Company `0x8802`, `0x8803` or `0x8843`, exactly 11 bytes starting with `0xEC`. **Verified.**

| Byte | Meaning |
|---|---|
| 0 | `EC` marker |
| 1 | Reserved (`00`) |
| 2 | Unknown (`01` on older firmware, `02` on newer) |
| 3 | Unknown (`01`) |
| 4 | Power: `00` off, otherwise on |
| 5 | Reserved (`00`) |
| 6 | Heating state, see below |
| 7–10 | Reserved (`00`) |

| Value | State |
|---|---|
| `00` | Idle |
| `01` | Heating |
| `02` | Keeping warm |
| `04` | Finished boiling |

Unknown state values make the decoder reject the advertisement.

Example, `GVH71732ADB` heating on 2026-10-28: `43 88 EC 00 02 01 01 00 01 00 00 00 00`.

### 2.5 Rice cooker (H7180)

Company `0x8802`, same 6-byte layout as appliances; byte 4 is cooking on or off. **Verified.**

## 3. GATT services

Read-only survey of the H712C purifier, H7173 kettle and H7135 heater on 2026-10-28. **Observed.**

| Service | Characteristic | Properties | Purifier | Kettle | Heater |
|---|---|---|---|---|---|
| `00010203-0405-0607-0809-0a0b0c0d1910` (control) | `…2b10` | read, notify | ✓ | ✓ | ✓ |
| | `…2b11` | write without response (purifier also write) | ✓ | ✓ | ✓ |
| `494E5445-4C4C-495F-524F-434B535F4857` | `…2014` | read, write, notify | ✓ | — | ✓ |
| | `…2015` | read, notify | ✓ | — | ✓ |
| `FFF6` (Matter commissioning) | `18EE2EF5-263D-4559-959F-4F9C429F9D11` | write | ✓ | — | — |
| | `18EE2EF5-263D-4559-959F-4F9C429F9D12` | read, indicate | ✓ | — | — |

Notes:

- **Control service.** The same service and characteristics are documented for Govee lights. Commands are written to `…2b11` and replies arrive as notifications on `…2b10`. Some lights (H615B) are reported to write to `…2b10` instead. **Community.**
- **`494E5445-…4857`** is ASCII for `INTELLI_ROCKS_HW` (Shenzhen Intellirocks is Govee's parent company). The same UUID is the iBeacon UUID in thermometer advertisements and is exposed in this library as `UUID.goveeThermostat`. On the heater both characteristics carry the user description `for gatt Read`. Purpose unknown.
- **`FFF6`** is the standard Matter BLE commissioning service. CoreBluetooth refuses to read or subscribe to it from ordinary apps.
- No device information (`180A`) or battery (`180F`) service is exposed.
- Devices mostly answer requests. The purifier also sends an `AA 01` status notification on its own when its power state changes.
- On the kettle and heater, reading `…2b10` and `…2b11` directly is not permitted; use notifications.

## 4. Packet format

Every packet on the control service is exactly 20 bytes. **Verified** (H712C replies; light vectors from community sources).

```
byte  0       1 … 18             19
      [id]    [payload, zero padded]  [checksum]
```

- The checksum is the XOR of bytes 0–18. Some community scripts describe a sum; captured packets only validate with XOR.
- Replies echo the request's id and sub-command in bytes 0–1.

| Id | Meaning | Status |
|---|---|---|
| `0x33` | Command: power, session setup; light commands | Verified (purifier capture) |
| `0x3A` | Appliance command: mode, night light | Verified (purifier capture) |
| `0xAA` | Status query, and the reply to it | Verified (purifier) |
| `0xAB` | Multi-packet query for long values | Observed (purifier capture) |
| `0xA1` | DIY scene data (lights) | Community |
| `0xA3` | Multi-packet data (lights) | Community |

Devices answer every command and query with a notification that echoes bytes 0–1 (and for `0x3A` usually the whole request), so a client can match replies to requests.

### Multi-packet replies (`0xAB`)

Values longer than 17 bytes are requested with `AB 01 <item>` and returned as a sequence of notifications:

```
-> AB 01 05 …                       request item 05
<- AB 00 02 00 04 01 05 <11 bytes>  header: packet count 02, then the item id, then the first bytes
<- AB FF <bytes>                    last packet (FF); middle packets are numbered 01, 02, …
```

Item `05` on the purifier is a 16-character ASCII device identifier. Item `04` is a long ASCII string beginning with the current Unix time, sent over nine packets; it looks like a signed token and should be treated as a secret. Item `02` returned `01 00 04 01 02 01 01 01` (unknown).

Implemented as `GoveePacket` in `Sources/Govee/Protocol/GoveePacket.swift`.

## 5. Status queries

A status query is `AA <sub-command> [<item>]`, zero padded, with checksum. The reply echoes the request bytes and fills in the value.

### H712C purifier

From our own queries on 2026-10-28 and the Govee app's queries in a PacketLogger trace the same day (purifier in Turbo, night light orange at 50 %, filter at 65 %). **Verified** unless marked.

| Request | Reply (bytes 1…) | Meaning |
|---|---|---|
| `AA 01` | `01 <power> 00 00 FF FF 06` | Power: `00` off, `01` on. `FF FF 06` unknown. |
| `AA 05 00` | `05 00 <mode>` | Current mode, see [fan modes](#h712c-purifier-1). |
| `AA 05 01` | `05 01 <speed>` | Manual fan speed 1–3. |
| `AA 05 03` | `05 03 00 00 14` | Unknown, possibly auto mode settings. **Observed.** |
| `AA 06` | `06` + ASCII | Firmware version, `1.00.16`. |
| `AA 07 06` | `07 06` + 6 bytes | Bluetooth address, big endian: `E8 06 90 0C E7 8A`. |
| `AA 07 11` | `07 11` + 6 bytes + `01 00 10 04 01` | Wi-Fi MAC address, big endian, then unknown bytes. |
| `AA 07 10` | `07 10` + 6 bytes + `B7 1A 01 00 10 04 01` | Wi-Fi MAC address, little endian, then unknown bytes. |
| `AA 16` | `16 01 00 00 17 3B 01` | Unknown; `17 3B` may be 23:59. **Observed.** |
| `AA 19` | `19 00 FF FF 06 00 41` | Byte 7 likely filter life, `0x41` = 65 %. **Observed.** |
| `AA 1B 01` | `1B 01 <on> <brightness>` | Night light: on/off and brightness (`0x32` = 50 %). |
| `AA 1B 05` | `1B 05 0D <R> <G> <B>` | Night light color, `FF 8D 0B` (orange). `0D` unknown. |
| `AA 04`, `08`, `0E`, `10`, `11`, `12`, `13`, `17`, `1F`, `23`, `26`, `07 20` | all `00` | Unsupported or empty. |

The app polls `AA 01`, `AA 05 00/01/03`, `AA 1B 01/05`, `AA 1E 01 02`, `AA 10`, `AA 08`, `AA 26`, `AA 16`, `AA 17`, `AA 19`, `AA 07 …` and `AA 1F` right after connecting.

Full exchange for `AA 01` while off:

```
-> AA 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 AB
<- AA 01 00 00 00 FF FF 06 00 00 00 00 00 00 00 00 00 00 00 AD
```

The device also sends `AA 01` replies unprompted when the power state changes.

### H7135 heater

Accepted all twelve queries above on `…2b11` and sent no replies. We sent them without the session setup below, which the Govee app always sends first; that is the most likely reason.

### H7173 kettle

Not queried; it stopped advertising while idle.

## 6. Commands

### Session setup

Right after connecting and subscribing to `…2b10`, the Govee app sends two `0x33` packets before anything else. **Verified** (purifier capture).

| Packet | Meaning |
|---|---|
| `33 B2 <8 bytes>` | Unknown 8-byte value, likely a per-device key from the user's Govee account. The device replies `33 B2` with zeros. **Treat as a secret; do not publish captured values.** |
| `33 B5 <unix time, 4 bytes big endian> 01 <UTC offset hours, signed>` | Set clock. `33 B5 6A E2 6B 0C 01 FC` = 2026-10-28 21:37:16 UTC, offset −4 h. Resent roughly every 15 seconds while connected. Byte 6 (`01`) unknown. |

Whether the purifier requires `33 B2` is unknown: it answered our status queries without it. The heater did not.

### Power

`33 01 <00/01>`, the same as Govee lights. **Verified** for off on the purifier:

```
-> 33 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 32
<- 33 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 32
```

### H712C purifier

Appliance commands use packet id `0x3A`. The device echoes the full request. **Verified** (purifier capture, 2026-10-28).

| Action | Packet (bytes 0…) | Notes |
|---|---|---|
| Low | `3A 05 01 01` | Mode `01` (manual), speed 1 |
| Medium | `3A 05 01 02` | Speed 2 |
| High | `3A 05 01 03` | Speed 3 |
| Sleeping | `3A 05 05 00` | Mode `05` |
| Turbo | `3A 05 07 00` | Mode `07` |
| Night light on | `3A 1B 01 01 01` | Reply `3A 1B 01 01 32`: on, brightness 50 % |

Mode values: `01` manual, `05` sleep, `07` turbo. Values `02`, `03`, `04` and `06` were not seen; `AA 05 03` suggests `03` may be auto.

Full exchange for Low:

```
-> 3A 05 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3F
<- 3A 05 01 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 3F
```

### Lights

The layouts below come from Govee lights and are implemented in `GoveeCommand` (`Sources/Govee/Protocol/GoveeCommand.swift`). They have not been sent to any device by this project. **Community.**

| Command | Bytes 1… | Notes |
|---|---|---|
| Power | `01 <00/01>` | On = `33 01 01 … 33` |
| Brightness | `04 <value>` | |
| Color | `05 02 <R> <G> <B>` | Manual mode |
| White | `05 02 FF FF FF 01 <R> <G> <B>` | White with tint |

### Other appliances

Heater mode and heat level, and kettle target temperature, are still unknown. Capture them from the Govee app before sending anything.

## 7. Capturing data

- **Advertisements.** On macOS, a CoreBluetooth command-line tool needs an embedded `Info.plist` with `NSBluetoothAlwaysUsageDescription`, and it must run from an app that has Bluetooth permission, such as Terminal. Scan with duplicates allowed to see state changes.
- **Diffing state.** Capture the same device in each state (off, on, each mode) and compare byte by byte.
- **App traffic.** To learn commands, record the Govee app's traffic.
  - iOS: install Apple's Bluetooth logging profile (developer.apple.com/bug-reporting/profiles-and-logs), restart the phone, connect it to a Mac and choose **File → New iOS Trace** in PacketLogger (Additional Tools for Xcode). Save as `.pklg`.
  - Android: enable "Bluetooth HCI snoop log" in developer options and open the log in Wireshark.
  - Perform one action at a time, about 10 seconds apart, and note the clock time of each.
  - Traces contain all of the phone's Bluetooth traffic and the session secrets above. Do not commit raw traces.
- **Reading `.pklg` files.** Records are a 4-byte little endian length, 4-byte seconds, 4-byte microseconds, a 1-byte type (`00` HCI command, `01` HCI event, `02` ACL sent, `03` ACL received, `FC` note), then the payload. ATT data is ACL on L2CAP channel `0x0004`; writes to `…2b11` are opcode `0x52` and notifications from `…2b10` are opcode `0x1B`.
- Record the date, device, firmware version and state with every capture, and add it as a test vector with that information in a comment.

## 8. Open questions

- What is the `0x40` bit in company identifier `0x8843`, and what are advertisement bytes 2 and 3?
- What are the purifier's `AA 01` bytes 5–7 (`FF FF 06`), `AA 05 03`, `AA 16` and `AA 19`? Is `AA 19` byte 7 really filter life?
- Purifier mode values `02`, `03`, `04`, `06` (auto?), power on, night light off, brightness and color commands.
- What is the `33 B2` value, where does the app get it, and is it required? Does the heater answer once it is sent?
- Heater and kettle commands; capture them with PacketLogger.
- What is the `494E5445-…` service for?
- Advertisement layouts for H5074, H5179 and other sensors, and negative temperatures.

## 9. References

- Homebridge Govee, `lib/utils/ble-protocol.js`
- `lasswellt/govee-homeassistant`, `docs/govee-protocol-reference.md`
- `chvolkmann/govee_btled`
- `ConsciousCode/govee_h7015`
- Home Assistant forum, "Govee H617A BLE LED Strip Lights Reverse Engineering"
- PyPI `govee-ble`
- Bluetooth SIG Assigned Numbers; Matter specification (BLE commissioning service `FFF6`)
