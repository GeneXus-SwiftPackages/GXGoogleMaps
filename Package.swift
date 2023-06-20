// swift-tools-version: 5.7
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
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXCoreModule_Common_Maps.git", exact: "1.0.0-beta.20230620165651"),
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXCoreUI.git", exact: "1.0.0-beta.20230620165651"),
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXUCMaps.git", exact: "1.0.0-beta.20230620165651")
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
			url: "https://pkgs.genexus.dev/iOS/beta/GXGoogleMaps-1.0.0-beta.20230620165651.xcframework.zip",
			checksum: "cd5787a77b7398c28d696b3b4f3b9c649457395568ad5e6da25208e566ca4ebb"
		)
	]
)