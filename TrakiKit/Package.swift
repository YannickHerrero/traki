// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TrakiKit",
    // Deployment target mirrors the app (see project.yml). Bump to .v26 for
    // Liquid Glass once Xcode 26 is installed.
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "TrakiKit", targets: ["TrakiKit"]),
    ],
    targets: [
        .target(name: "TrakiKit"),
    ]
)
