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

### Encrypted sessions (H7135 heater)

Some devices only accept encrypted frames. The H7135 heater (firmware 1.00.30) and H7173 kettle (firmware 1.00.24) are two; the H712C purifier (1.00.16) is not. Under the encryption the frames are the ordinary 20-byte packets described above. **Verified**: every frame in PacketLogger captures of the Govee app talking to the H7135 and the H7173 on 2026-10-28 decrypts to a packet with a valid checksum using this scheme.

This scheme ("v1") was first published by community projects; see `SoloUnity/govee-ble-purifiers` (`crypto.py`) and `Fredde87/ha-govee-led-ble` in the [references](#9-references).

**Frame transform.** A plaintext packet `P` (20 bytes, with its normal XOR checksum) is sent as:

- bytes 0–15: `AES-128-ECB(key, P[0…15])`
- bytes 16–19: `P[16…19]` XOR the first 4 bytes of an RC4 keystream from the same `key`, with the RC4 state rebuilt for every frame.

Because bytes 16–18 of most packets are zero padding, the encrypted bytes 16–18 are the same for the whole session (`87 53 32` in our capture).

**Handshake.** Before the first frame, the client negotiates a session key. Handshake frames are encrypted with a fixed 16-byte communication key that is built into the Govee app and published in the projects above.

1. On connect, the heater sends an encrypted `AA 01` status notification on `…2b10` (with the communication key).
2. Client → `…2b11`: `E7 01` + 17 random bytes.
3. Device → `…2b10`: `E7 01` + 16-byte **session key** + 1 byte.
4. Client → `…2b11`: `E7 02` + 17 random bytes. Device echoes an `E7 02` frame.
5. All later frames in both directions use the session key. The app then sends the usual `33 B2` and `33 B5` session setup and starts polling.

The session key is new for every connection and is never needed again after disconnecting. Never log it. No Govee account data is involved; anyone who can connect to the device can complete the handshake.

A newer "v2" scheme (AES-GCM, selected by a version characteristic `…2b12`) is reported for some newer lights. None of our devices expose `…2b12`.

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
| `AA 16` | `16 01 00 00 17 3B 01` | Display on, likely with a schedule of 00:00–23:59 ("Always On" in the app). Matches the heater's `33 16` display command. **Observed.** |
| `AA 19` | `19 00 FF FF 06 00 41` | Byte 7 likely filter life, `0x41` = 65 %. **Observed.** |
| `AA 1B 01` | `1B 01 <on> <brightness>` | Night light: on/off and brightness (`0x32` = 50 %). |
| `AA 1B 05` | `1B 05 0D <R> <G> <B>` | Night light color, `FF 8D 0B` (orange). `0D` unknown. |
| `AA 1F` | all `00` | Probably lock off (the heater uses `33 1F 02 <on>` for lock). **Observed.** |
| `AA 04`, `08`, `0E`, `10`, `11`, `12`, `13`, `17`, `23`, `26`, `07 20` | all `00` | Unsupported or empty. |

The app polls `AA 01`, `AA 05 00/01/03`, `AA 1B 01/05`, `AA 1E 01 02`, `AA 10`, `AA 08`, `AA 26`, `AA 16`, `AA 17`, `AA 19`, `AA 07 …` and `AA 1F` right after connecting.

Full exchange for `AA 01` while off:

```
-> AA 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 AB
<- AA 01 00 00 00 FF FF 06 00 00 00 00 00 00 00 00 00 00 00 AD
```

The device also sends `AA 01` replies unprompted when the power state changes.

### H7135 heater

Ignores plaintext; queries must be encrypted after the [handshake](#encrypted-sessions-h7135-heater). Decrypted from the Govee app capture on 2026-10-28:

| Request | Reply (bytes 1…) | Meaning |
|---|---|---|
| `AA 01` | `01 <power> 00 00 00 01 <t2> <t1> <t0> …` | Power, then the linked Bluetooth thermometer's reading in the [thermometer encoding](#22-thermometers-h5072-h5075-family): `03 B3 CF` = 24.26 °C, 63.9 %. Byte 12 was `01` while locked. |
| `AA 06` | `06` + ASCII | Firmware version, `1.00.30`. |

The heater also sends events with id `0xEE`: `EE AA 01` and `EE 19 05 <value>` (meaning unknown).

### H7173 kettle

[Encrypted](#encrypted-sessions-h7135-heater). Decrypted from a Govee app capture on 2026-10-28, matched to a screen recording of the app. Temperatures are degrees Fahrenheit × 100, big endian (`36 4C` = 13900 = 139 °F). **Verified** unless marked.

| Request | Reply (bytes 1…) | Meaning |
|---|---|---|
| `AA 00` | `00 <heating> 00 01 <temp, 2 bytes> 01 <keep warm>` | Heating `00`/`01`; current water temperature; byte 8 `01` when keep warm is enabled (**Observed**). |
| `AA 05 00` | `05 00 <mode> <value…>` | Current mode, in the same form as the [mode command](#h7173-kettle-1): `01 01` DIY slot 1, `02 00` boiling, `05 43 F8` manual 174 °F. |
| `AA 05 01 <page>` | `05 01 <page>` + 2 presets + `01` | DIY presets. |
| `AA 05 03 <page>` | `05 03 <page>` + 2 presets + `01` | Tea presets. |
| `AA 05 04 <page>` | `05 04 <page>` + 2 presets + `01` | Coffee presets. |
| `AA 22` | `22 <on> 00 <minutes> <minutes>` | Keep warm: `22 01 00 3C 3C` = on, 60 minutes. The second minutes byte may be remaining time. |
| `AA 06` | `06` + ASCII | Firmware version, `1.00.24`. |
| `AA 07 03`, `AA 20` | ASCII | `1.02.00`, probably hardware version. **Observed.** |
| `AA 07 0A`, `AA 07 0B`, `AA 21` | ASCII | `1.00.10`, `1.00.01`, `1.00.24`. Unknown component versions. **Observed.** |
| `AA 14` | `14` + 6 bytes | `60 74 F4 57 2A DA`, an address one below the Bluetooth address `…2A:DB`. **Observed.** |
| `AA 23` | `23 00 01 A4 66 68 27 5C` | Unknown. **Observed.** |
| `AA 17` | all `00` | Unknown or empty. |

Each preset entry is 4 bytes: `<temp, 2 bytes> <index> 00`, or `FF FF FF FF` for an empty slot. Bit 15 of the temperature is set on built-in presets that the app does not let you edit. In our capture:

| Category | Page | Entries | App |
|---|---|---|---|
| DIY (`01`) | 0 | `42 68 01 00`, empty | Custom1 170 °F |
| Tea (`03`) | 0 | `C6 50 01 00`, `D2 D0 02 00` | Green Tea 180 °F (built in), Black Tea 212 °F (built in) |
| Tea (`03`) | 1 | `4C 2C 03 00`, empty | Oolong Tea 195 °F |
| Coffee (`04`) | 0 | `50 14 01 00`, empty | Coffee1 205 °F |

Events: `EE 22 <keep warm reply>` when keep warm changes, and `EE AA 00` after other changes.

## 6. Commands

### Session setup

Right after connecting and subscribing to `…2b10`, the Govee app sends two `0x33` packets before anything else. **Verified** (purifier capture).

| Packet | Meaning |
|---|---|
| `33 B2 <8 bytes>` | Unknown 8-byte value, likely a per-device key from the user's Govee account. The device replies `33 B2` with zeros. **Treat as a secret; do not publish captured values.** |
| `33 B5 <unix time, 4 bytes big endian> 01 <UTC offset hours, signed>` | Set clock. `33 B5 6A E2 6B 0C 01 FC` = 2026-10-28 21:37:16 UTC, offset −4 h. Resent roughly every 15 seconds while connected. Byte 6 (`01`) unknown. |

Whether the purifier requires `33 B2` is unknown: it answered our status queries without it. The heater uses a different, encrypted handshake instead.

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
| Night light on / off | `3A 1B 01 01 <01/00>` | Reply `3A 1B 01 <on> <brightness>` |
| Night light brightness | `3A 1B 01 02 <percent>` | `64` = 100 %, `0A` = 10 %. Reply `3A 1B 01 01 <percent>` |
| Night light color | `3A 1B 05 0D <R> <G> <B>` | Red `FF 00 00`, green `00 FF 00`, blue `00 00 FF`. `0D` unknown, constant. Device echoes the request. |
| Display | `33 16 <on> <start h> <start m> <end h> <end m> <always>` | Off: `33 16 00 00 00 17 3B 01`. Always on: `33 16 01 00 00 17 3B 01`. Scheduled: last byte `00`, with the window 00:00–23:59 (`00 00 17 3B`) in our capture. Reply `33 16` with zeros. |
| Timer | `33 26 01 <minutes, 2 bytes BE> <seconds, 3 bytes BE>` | 1 hour: `33 26 01 00 3C 00 0E 10` (60 min, 3600 s). Cancel not captured. **Observed.** |
| Power off | `33 01 00` | |
| Power on | `33 01 01` (expected) | Not seen over BLE: the app turned the purifier on while the trace showed no write, so it most likely used Wi-Fi. Same as the heater's verified command. |

Mode values: `01` manual, `05` sleep, `07` turbo. Values `02`, `03`, `04` and `06` were not seen. The app did not send an Auto command; the H712C has no PM2.5 sensor and is reported to need a paired H5106 sensor for Auto.

Status notifications `EE AA 00` arrive after each change, with no other content. **Observed.**

The Govee app sends some commands over Wi-Fi instead of BLE when the device is online, so a BLE capture may be missing actions. Note the time of each action and check that each appears.

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

### H7135 heater

Sent [encrypted](#encrypted-sessions-h7135-heater). Decrypted from the Govee app capture on 2026-10-28; the device echoes each command. **Verified** against the user's recorded actions.

| Action | Packet (bytes 0…) | Notes |
|---|---|---|
| Power on / off | `33 01 01` / `33 01 00` | |
| Low / Medium / High | `3A 05 01 01` / `02` / `03` | Mode `01` (manual heat), level 1–3 |
| Fan only | `3A 05 09 00` | Mode `09` |
| Auto | `3A 05 03 00 80 19 C8` | Mode `03`. `19 C8` = 6600, possibly a target of 66.00 °F; `80` unknown. Reply: `3A 05 03 00 86 19 C8 1E DC 1C E8` (unknown). **Observed.** |
| Display on / off | `33 16 01 FF FF FF FF` / `33 16 00 FF FF FF FF` | `FF FF FF FF` likely means no schedule. The purifier's `AA 16` reply `16 01 00 00 17 3B` suggests a schedule of 00:00–23:59. |
| Lock on / off | `33 1F 02 01` / `33 1F 02 00` | |

### H7173 kettle

Sent [encrypted](#encrypted-sessions-h7135-heater). Decrypted from the Govee app capture on 2026-10-28 and matched to a screen recording; the device echoes each command. **Verified.**

| Action | Packet (bytes 0…) | Notes |
|---|---|---|
| Start heating / cancel | `33 01 01` / `33 01 00` | |
| Set target temperature | `3A 05 00 05 <temp, 2 bytes>` | °F × 100: `2B 5C` = 111 °F, `43 F8` = 174 °F. Mode `05` (manual). |
| Boiling preset | `3A 05 00 02 00` | Mode `02`, 212 °F |
| DIY preset | `3A 05 00 01 <index>` | Mode `01`. Index from `AA 05 01`. |
| Tea preset | `3A 05 00 03 <index>` | Mode `03`. `01` Green, `02` Black, `03` Oolong in our capture. |
| Coffee preset | `3A 05 00 04 <index>` | Mode `04`. |
| Keep warm on / off | `3A 22 <01/00> 00 <minutes>` | `3A 22 01 00 3C` = on for 60 minutes. Reply adds a second minutes byte. Can be set while idle ("Keep Warm will be ON next time"). |

Choosing a preset or a target does not start heating; the app sends `33 01 01` separately. Commands to edit preset temperatures and the app's "Scheduled Start" were not captured.

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
- Purifier mode values `02`, `03`, `04`, `06` and Auto (needs a paired sensor); power on over BLE; timer cancel; display schedule with other times; the night light color byte `0D`.
- What is the `33 B2` value, where does the app get it, and is it required?
- Which models and firmware versions require encryption? (H7135 firmware 1.00.30 does; H712C firmware 1.00.16 does not.)
- Heater Auto mode parameters, and the `EE` event ids.
- Kettle: editing presets, Scheduled Start, Celsius, keep-warm durations other than 60 minutes, and `AA 23`.
- What is the `494E5445-…` service for?
- Advertisement layouts for H5074, H5179 and other sensors, and negative temperatures.

## 9. References

- Homebridge Govee, `lib/utils/ble-protocol.js`
- `lasswellt/govee-homeassistant`, `docs/govee-protocol-reference.md`
- `chvolkmann/govee_btled`
- `ConsciousCode/govee_h7015`
- Home Assistant forum, "Govee H617A BLE LED Strip Lights Reverse Engineering"
- PyPI `govee-ble`
- `SoloUnity/govee-ble-purifiers`, Home Assistant integration for Govee purifiers; v1 encryption in `custom_components/govee_ble_air_purifier/crypto.py`
- `Fredde87/ha-govee-led-ble`, v1 and v2 encryption for lights
- `jnstockley/ha-govee-ble-devices` and `jnstockley/govee_ble_client`, purifiers and fans
- Bluetooth SIG Assigned Numbers; Matter specification (BLE commissioning service `FFF6`)
