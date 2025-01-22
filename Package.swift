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
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXCoreModule_Common_Maps.git", exact: "3.0.0-beta.9"),
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXCoreUI.git", exact: "3.0.0-beta.9"),
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXUCMaps.git", exact: "3.0.0-beta.9"),
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
			url: "https://pkgs.genexus.dev/iOS/beta/GXGoogleMaps-3.0.0-beta.9.xcframework.zip",
			checksum: "2f360db4494af1a6ef29b92176e249afe6bf1eb4c9d22938ff3070b087f3f6bb"
		)
	]
)