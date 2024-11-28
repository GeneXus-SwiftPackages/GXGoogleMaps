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
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXCoreModule_Common_Maps.git", exact: "2.2.0-beta.18"),
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXCoreUI.git", exact: "2.2.0-beta.18"),
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXUCMaps.git", exact: "2.2.0-beta.18")
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
			url: "https://pkgs.genexus.dev/iOS/beta/GXGoogleMaps-2.2.0-beta.18.xcframework.zip",
			checksum: "e1c49394b1f9b0824b040f58fc8ec759875a78b7c4ef5c2b6748c17d7ac2e9ff"
		)
	]
)