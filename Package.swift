// swift-tools-version: 5.9
import PackageDescription

let package = Package(
	name: "GXGoogleMaps",
	platforms: [.iOS("12.0")],
	products: [
		.library(
			name: "GXGoogleMaps",
			targets: ["GXGoogleMapsWrapper"])
	],
	dependencies: [
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXCoreModule_Common_Maps.git", exact: "2.2.0-beta.8"),
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXCoreUI.git", exact: "2.2.0-beta.8"),
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXUCMaps.git", exact: "2.2.0-beta.8")
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
			url: "https://pkgs.genexus.dev/iOS/beta/GXGoogleMaps-2.2.0-beta.8.xcframework.zip",
			checksum: "440eaaec8d6b8ae32760558c42ad3791121415c22e28d93f28f4cecec5aeecc3"
		)
	]
)