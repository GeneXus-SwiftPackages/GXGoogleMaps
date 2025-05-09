// swift-tools-version: 5.9
import PackageDescription

let package = Package(
	name: "GXGoogleMaps",
	platforms: [.iOS("15.0")],
	products: [
		.library(
			name: "GXGoogleMaps",
			targets: ["GXGoogleMapsWrapper"])
	],
	dependencies: [
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXCoreModule_Common_Maps.git", exact: "3.2.0-rc.0"),
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXCoreUI.git", exact: "3.2.0-rc.0"),
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXUCMaps.git", exact: "3.2.0-rc.0")
	],
	targets: [
		.target(name: "GXGoogleMapsWrapper",
				dependencies: [
					"GXGoogleMaps",
					.product(name: "GXCoreModule_Common_Maps", package: "GXCoreModule_Common_Maps", condition: .when(platforms: [.iOS])),
					.product(name: "GXCoreUI", package: "GXCoreUI", condition: .when(platforms: [.iOS])),
					.product(name: "GXUCMaps", package: "GXUCMaps", condition: .when(platforms: [.iOS]))
				],
				path: "Sources"),
		.binaryTarget(
			name: "GXGoogleMaps",
			url: "https://pkgs.genexus.dev/iOS/preview/GXGoogleMaps-3.2.0-rc.0.xcframework.zip",
			checksum: "c71b6e6c82f71da61517503302c9daf887a29e2814043a13da7e8ee78ec0d3c4"
		)
	]
)