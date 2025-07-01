//
//  GMSPath+Helpers.swift
//

internal import GoogleMaps

extension GMSPath {
	func gxToCoordinates() -> [CLLocationCoordinate2D] {
		let range = 0..<self.count()
		return range.map(coordinate(at:))
	}
}
