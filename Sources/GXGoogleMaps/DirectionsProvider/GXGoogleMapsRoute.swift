//
//  GXGoogleMapsRoute.swift
//

private import GoogleMaps
import GXCoreModule_Common_Maps
import GXFoundation

private func convertoToGMSPath(fromWKTLine line: WKTLine) -> GMSPath {
	let path = GMSMutablePath()
	for coordinate in line.getListPoints() as? [WKTPoint] ?? [] {
		if let validCoordinate = coordinate.toLocation()?.coordinate, CLLocationCoordinate2DIsValid(validCoordinate) {
			path.add(validCoordinate)
		}
	}
	return path
}

private func convertoToGMSPath(fromMKCoordinates coordinates: [CLLocationCoordinate2D]) -> GMSPath {
	let path = GMSMutablePath()
	for coordinate in coordinates {
		if CLLocationCoordinate2DIsValid(coordinate) {
			path.add(coordinate)
		}
	}
	return path
}

public class GXGoogleMapsRoute : NSObject, GXMapRouteWithInitialization {
	private var path: [GMSPath] = []
	public private(set) var name: String
	public private(set) var advisoryNotices: [String]
	public private(set) var distance: Double
	public private(set) var expectedTravelTime: Double
	public private(set) var gxTransportType: GXTransportType
	
	public required init?(mapRoute json: [String : Any]) {
		if let linestringWKT = json[kRouteGeolineKey] as? String,
			let geoline = WKTGeometry.fromWKT(linestringWKT) {
			if let geoline = geoline as? WKTLine {
				self.path.append(convertoToGMSPath(fromWKTLine: geoline))
			} else if let wktLinesM = geoline as? WKTLineM, let geolines = wktLinesM.toMapMultiLine()  {
				for geoline in geolines {
					if let geoline = geoline as? MKPolyline {
						self.path.append(convertoToGMSPath(fromMKCoordinates: geoline.gxMapCoordinates))
					}
				}
			} else {
				return nil
			}
		}
		self.name = json[kRouteNameKey] as? String ?? ""
		self.advisoryNotices = json[kRouteAdvisoryNoticesKey] as? [String] ?? []
		self.distance = GXUtilities.doubleNumber(fromValue: json[kRouteDistanceKey])?.doubleValue ?? 0
		self.expectedTravelTime = GXUtilities.doubleNumber(fromValue: json[kRouteExpectedTimeKey])?.doubleValue ?? 0
		self.gxTransportType = GXMapUtilities.convertGXTransportType(fromRawValue: json[kRouteTransportTypeKey] as? String,
																	 defaultValue: .any)
	}
	
	public private(set) lazy var gxPolyline: [GXPolyline] = path.map(GXGMSPolyline.init(path:))
	
	public var dictionaryRepresentation: Dictionary<String, Any> {
		return [ kRouteNameKey: self.name,
	  kRouteAdvisoryNoticesKey: self.advisoryNotices,
			 kRouteDistanceKey: self.distance,
		 kRouteExpectedTimeKey: self.expectedTravelTime,
		kRouteTransportTypeKey: GXMapUtilities.convertToString(from: self.gxTransportType),
			  kRouteGeolineKey: self.gxPolyline.map(getWKTRepresentation(for:))
		]
	}
}
