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
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXCoreModule_Common_Maps.git", exact: "3.1.0-beta.3"),
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXCoreUI.git", exact: "3.1.0-beta.3"),
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXUCMaps.git", exact: "3.1.0-beta.3")
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
			url: "https://pkgs.genexus.dev/iOS/beta/GXGoogleMaps-3.1.0-beta.3.xcframework.zip",
			checksum: "341a7b1bbd56e9d05fea4f060e1c31f66a1cdeee9b172b1f938fd08cbeba3e6a"
		)
	]
)