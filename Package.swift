// swift-tools-version: 5.9
import PackageDescription
import Foundation

let GX_FC_LAST_VERSION = Version("3.2.0-beta")

let package = Package(
	name: "GXGoogleMaps",
	platforms: [.iOS(.v15), .tvOS("18.0"), .watchOS(.v10), .visionOS("2.0")],
	products: [
		.library(name: "GXGoogleMaps", targets: ["GXGoogleMaps"]),
	],
	dependencies: [
		.package(url: "https://github.com/googlemaps/ios-maps-sdk.git", .upToNextMajor(from: "9.0.0")),
		.package(url: "https://github.com/googlemaps/google-maps-ios-utils.git", .upToNextMajor(from: "6.0.0")),
		.gxFramework("GXCoreUI"),
		.gxFramework("GXCoreModule_Common_Maps"),
		.gxFramework("GXUCMaps"),
	],
	targets: [
		.target(name: "GXGoogleMaps",
				dependencies: [
					.product(name: "GoogleMaps", package: "ios-maps-sdk"),
					.product(name: "GoogleMapsUtils", package: "google-maps-ios-utils"),
					.product(name: "GXCoreUI", package: "GXCoreUI"),
					.product(name: "GXCoreModule_Common_Maps", package: "GXCoreModule_Common_Maps"),
					.product(name: "GXUCMaps", package: "GXUCMaps"),
				]),
	]
)

extension Package.Dependency {
	static func gxFramework(_ name: String) -> Package.Dependency {
		guard let localPath = gxFrameworksLocalPath() else {
			return .package(url: "https://github.com/GeneXus-SwiftPackages/\(name).git", .upToNextMajor(from: GX_FC_LAST_VERSION))
		}
		return .package(name: name, path: localPath.appending(component: name).path)
	}
}

func gxFrameworksLocalPath() -> URL? {
	guard let pathCString = getenv("GX_FRAMEWORKS_LOCAL_PATH") else {
		return nil
	}
	let path = String(cString: pathCString)
	return URL(filePath: path)
}
