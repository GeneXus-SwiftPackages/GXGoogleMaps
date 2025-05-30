//
//  GMSPolygon+GXPolygon.swift
//

import GXCoreModule_Common_Maps
internal import GoogleMaps
import GXObjectsModel

private var GMSSDMapPolygonThemeClassKey: UInt8 = 0
private var GMSSDMapPolygonMapAnnotationKey: UInt8 = 0

internal class GXGMSPolygon: GMSPolygon, GXPolygon, GXWktRepresentable {
	
	var gxMapCoordinates: [CLLocationCoordinate2D] {
		return self.path?.gxToCoordinates() ?? []
	}
	
	var wktRepresentation: String {
		return getWKTRepresentation(for: self)
	}
	
	var polygonStyleClass: GXStyleClass? {
		get {
			return objc_getAssociatedObject(self, &GMSSDMapPolygonThemeClassKey) as? GXStyleClass
		}
		set {
			objc_setAssociatedObject(self, &GMSSDMapPolygonThemeClassKey, newValue, .OBJC_ASSOCIATION_RETAIN)
		}
	}
	
	var mapAnnotation: MKAnnotation? {
		get {
			objc_getAssociatedObject(self, &GMSSDMapPolygonMapAnnotationKey) as? MKAnnotation
		}
		set {
			objc_setAssociatedObject(self, &GMSSDMapPolygonMapAnnotationKey, newValue, .OBJC_ASSOCIATION_RETAIN)
		}
	}
}
