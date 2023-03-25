// swift-tools-version: 5.7

// WARNING:
// This file is automatically generated.
// Do not edit it by hand because the contents will be replaced.

import PackageDescription
import AppleProductTypes

var package = Package(
    name: "GoveeApp",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "GoveeApp",
            targets: ["AppModule"],
            bundleIdentifier: "com.colemancda.Govee",
            teamIdentifier: "4W79SG34MW",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .cloud),
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            capabilities: [
                .bluetoothAlways(purposeString: "Bluetooth is needed to scan for nearby accessories."),
                .outgoingNetworkConnections()
            ],
            appCategory: .utilities,
            additionalInfoPlistContentFilePath: "Info.plist"
        )
    ],
    dependencies: [
        .package(url: "https://github.com/MillerTechnologyPeru/Govee.git", "0.1.0"..<"1.0.0"),
        .package(url: "https://github.com/PureSwift/GATT.git", "3.0.0"..<"4.0.0")
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            dependencies: [
                .product(name: "Govee", package: "govee"),
                .product(name: "DarwinGATT", package: "gatt"),
                .product(name: "GATT", package: "gatt")
            ],
            path: "."
        )
    ]
)

// Xcode only settings
#if os(macOS)
package.dependencies[0] = .package(path: "../")
package.platforms = [.iOS("15.0")]
#endif
