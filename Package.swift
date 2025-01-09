// swift-tools-version: 5.9
import PackageDescription

let package = Package(
	name: "GXGoogleMaps",
	platforms: [.iOS("13.0")],
	products: [
		.library(
			name: "GXGoogleMaps",
			targets: ["GXGoogleMapsWrapper"])
	],
	dependencies: [
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXCoreModule_Common_Maps.git", exact: "3.0.0-beta.2"),
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXCoreUI.git", exact: "3.0.0-beta.2"),
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXUCMaps.git", exact: "3.0.0-beta.2"),
		.package(url: "https://github.com/googlemaps/ios-maps-sdk", .upToNextMajor(from: "9.0.0")),
		.package(url: "https://github.com/googlemaps/google-maps-ios-utils", .upToNextMajor(from: "6.0.0"))
	],
	targets: [
		.target(name: "GXGoogleMapsWrapper",
				dependencies: [
					"GXGoogleMaps",
					.product(name: "GXCoreModule_Common_Maps", package: "GXCoreModule_Common_Maps", condition: .when(platforms: [.iOS])),
					.product(name: "GXCoreUI", package: "GXCoreUI", condition: .when(platforms: [.iOS])),
					.product(name: "GXUCMaps", package: "GXUCMaps", condition: .when(platforms: [.iOS])),
					.product(name: "GoogleMaps", package: "ios-maps-sdk", condition: .when(platforms: [.iOS])),
					.product(name: "GoogleMapsUtils", package: "google-maps-ios-utils", condition: .when(platforms: [.iOS]))
				],
				path: "Sources"),
		.binaryTarget(
			name: "GXGoogleMaps",
			url: "https://pkgs.genexus.dev/iOS/beta/GXGoogleMaps-3.0.0-beta.2.xcframework.zip",
			checksum: "1e5b40115ee3c523e7632fa15f45b822c738b22e8287cda81b524184fea838e8"
		)
	]
)