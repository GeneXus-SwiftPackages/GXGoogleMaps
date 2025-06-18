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
		.package(url: "https://github.com/googlemaps/google-maps-ios-utils.git", .upToNextMajor(from: "6.0.0"))
	] + Package.Dependency.gxFrameworks(remotePackageUrls: [
		"https://github.com/GeneXus-SwiftPackages/GXCoreUI.git",
		"https://github.com/GeneXus-SwiftPackages/GXCoreModule_Common_Maps.git",
		"https://github.com/GeneXus-SwiftPackages/GXUCMaps.git",
	]),
	targets: [
		.target(name: "GXGoogleMaps",
				dependencies: [
					.product(name: "GoogleMaps", package: "ios-maps-sdk"),
					.product(name: "GoogleMapsUtils", package: "google-maps-ios-utils"),
					.gxFrameworkProduct(name: "GXCoreUI", remotePackage: "GXCoreUI"),
					.gxFrameworkProduct(name: "GXCoreModule_Common_Maps", remotePackage: "GXCoreModule_Common_Maps"),
					.gxFrameworkProduct(name: "GXUCMaps", remotePackage: "GXUCMaps"),
				]),
	]
)

extension Package.Dependency {
	static func gxFrameworks(remotePackageUrls: [String]) -> [Package.Dependency] {
		if let localPath = gxFrameworksLocalPath() {
			return [ .package(name: "GXFrameworksLocal", path: localPath) ]
		}
		return remotePackageUrls.map {
			.package(url: $0, .upToNextMajor(from: GX_FC_LAST_VERSION))
		}
	}
}

extension Target.Dependency {
	static func gxFrameworkProduct(name: String, remotePackage: String) -> Self {
		.product(name: name, package: gxFrameworksLocalPath() != nil ? "GXFrameworksLocal" : remotePackage)
	}
}

func gxFrameworksLocalPath() -> String? {
	guard let pathCString = getenv("GX_FRAMEWORKS_LOCAL_PATH") else {
		return nil
	}
	return String(cString: pathCString)
}
