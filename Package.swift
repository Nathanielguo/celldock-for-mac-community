// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CellDock",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CellDock", targets: ["CellDock"]),
        .executable(name: "CellDockNetworkHelper", targets: ["CellDockNetworkHelper"]),
        .executable(name: "CellDockDialProbe", targets: ["CellDockDialProbe"]),
        .executable(name: "CellDockSMSDeleteProbe", targets: ["CellDockSMSDeleteProbe"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CModemBridge",
            dependencies: [],
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedFramework("CoreFoundation"),
                .linkedFramework("IOKit")
            ]
        ),
        .target(
            name: "CUACProbe",
            dependencies: [],
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedFramework("CoreAudio"),
                .linkedFramework("CoreFoundation"),
                .linkedFramework("IOKit")
            ]
        ),
        .target(
            name: "CEuiccCore",
            dependencies: [],
            path: "Sources/CEuiccCore",
            sources: [
                "CellDockEUICCBridge.c",
                "Vendor/lpac/cjson/cJSON.c",
                "Vendor/lpac/cjson/cJSON_ex.c",
                "Vendor/lpac/euicc/base64.c",
                "Vendor/lpac/euicc/derutil.c",
                "Vendor/lpac/euicc/es8p.c",
                "Vendor/lpac/euicc/es9p.c",
                "Vendor/lpac/euicc/es9p_errors.c",
                "Vendor/lpac/euicc/es10a.c",
                "Vendor/lpac/euicc/es10b.c",
                "Vendor/lpac/euicc/es10c.c",
                "Vendor/lpac/euicc/es10c_ex.c",
                "Vendor/lpac/euicc/euicc.c",
                "Vendor/lpac/euicc/hexutil.c",
                "Vendor/lpac/euicc/interface.c",
                "Vendor/lpac/euicc/sha256.c",
                "Vendor/lpac/euicc/tostr.c"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("Vendor/lpac")
            ]
        ),
        .target(
            name: "CellDockNetworkIPC",
            dependencies: [],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .executableTarget(
            name: "CellDock",
            dependencies: [
                "CModemBridge",
                "CUACProbe",
                "CEuiccCore",
                "CellDockNetworkIPC"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("Contacts"),
                .linkedFramework("Vision"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("Security"),
                .linkedFramework("UserNotifications"),
                .unsafeFlags([
                    "-Xlinker", "-rpath",
                    "-Xlinker", "@executable_path/../Frameworks"
                ])
            ]
        ),
        .executableTarget(
            name: "CellDockNetworkHelper",
            dependencies: ["CellDockNetworkIPC"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ],
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("Security"),
                .linkedFramework("SystemConfiguration")
            ]
        ),
        .executableTarget(
            name: "CellDockDialProbe",
            dependencies: ["CModemBridge", "CUACProbe"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .executableTarget(
            name: "CellDockSMSDeleteProbe",
            dependencies: ["CModemBridge"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
