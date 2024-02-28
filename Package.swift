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
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXCoreModule_Common_Maps.git", exact: "1.5.0-beta.9"),
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXCoreUI.git", exact: "1.5.0-beta.9"),
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXUCMaps.git", exact: "1.5.0-beta.9")
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
			url: "https://pkgs.genexus.dev/iOS/beta/GXGoogleMaps-1.5.0-beta.9.xcframework.zip",
			checksum: "7e51396f37de73b1235ab8efe0bd994488ed99e3491ba7215d72db754492e63c"
		)
	]
)