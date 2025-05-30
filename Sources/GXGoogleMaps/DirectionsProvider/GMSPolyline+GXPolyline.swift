//
//  GMSPolyline+GXPolyline.swift
//

import GXCoreModule_Common_Maps
import GXObjectsModel
internal import GoogleMaps

private var GMSPolylineRouteThemeClassKey: UInt8 = 0
private var GMSPolylineMapAnnotationKey: UInt8 = 0

internal class GXGMSPolyline: GMSPolyline, GXPolyline, GXWktRepresentable {
	var gxMapCoordinates: [CLLocationCoordinate2D] {
		return self.path?.gxToCoordinates() ?? []
	}
	
	var wktRepresentation: String {
		return getWKTRepresentation(for: self)
	}
	
	var routeStyleClass: GXStyleClass? {
		get {
			objc_getAssociatedObject(self, &GMSPolylineRouteThemeClassKey) as? GXStyleClass
		}
		set {
			objc_setAssociatedObject(self, &GMSPolylineRouteThemeClassKey, newValue, .OBJC_ASSOCIATION_RETAIN)
		}
	}
	
	var mapAnnotation: MKAnnotation? {
		get {
			objc_getAssociatedObject(self, &GMSPolylineMapAnnotationKey) as? MKAnnotation
		}
		set {
			objc_setAssociatedObject(self, &GMSPolylineMapAnnotationKey, newValue, .OBJC_ASSOCIATION_RETAIN)
		}
	}
}
