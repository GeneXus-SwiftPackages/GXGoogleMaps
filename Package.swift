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
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXCoreModule_Common_Maps.git", exact: "2.2.0-beta.12"),
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXCoreUI.git", exact: "2.2.0-beta.12"),
		.package(url: "https://github.com/GeneXus-SwiftPackages/GXUCMaps.git", exact: "2.2.0-beta.12")
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
			url: "https://pkgs.genexus.dev/iOS/beta/GXGoogleMaps-2.2.0-beta.12.xcframework.zip",
			checksum: "510adce975486a340865199e94b6003c518c65c8e332f3ec527e019f6fe72304"
		)
	]
)