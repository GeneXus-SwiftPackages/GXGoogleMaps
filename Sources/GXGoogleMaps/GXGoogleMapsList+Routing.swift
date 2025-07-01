//
//  GXGoogleMapsList+Routing.swift
//

import GXCoreModule_Common_Maps
internal import GoogleMaps
import GXObjectsModel

internal extension GXGoogleMapsList {

	override func drawPolyline(polylines: [GXPolyline], isRefreshable: Bool) {
		guard let mapView = self.googleMapView else { return }
		
		for polyline in polylines {
			var shouldApplyStyle = false
			let gmsPolyline: GMSPolyline
			if let gmsPolyline_ = polyline as? GMSPolyline {
				gmsPolyline = gmsPolyline_
				// heuritic: if the width and color are the defaults, apply the class. If they have other info, then don't
				shouldApplyStyle = gmsPolyline.strokeWidth == 1.0 && gmsPolyline.strokeColor == UIColor.blue
			}
			else {
				let path = polyline.gxMapCoordinates
					.reduce(GMSMutablePath()) { path, coordinate in
						path.add(coordinate)
						return path
					}
				
				gmsPolyline = GMSPolyline(path: path)
				shouldApplyStyle = true
			}
			
			if shouldApplyStyle {
				let styleClass = polyline.routeStyleClass ?? self.routeStyleClass
				let resolver = GXStyleClassHelper.propertyDefaultResolver(for: styleClass, fallback: nil)
				DispatchQueue.gxSyncOnMain {
					if let styleClass = styleClass {
						gmsPolyline.strokeWidth = SDMapRouteThemeClass.lineWidth(from: styleClass, resolvingToDefaultWith: resolver)
						let strokeColor: UIColor = SDMapRouteThemeClass.strokeColor(from: styleClass, resolvingToDefaultWith: resolver) ?? mapView.tintColor
						if let dashPattern = SDMapRouteThemeClass.lineDashPattern(from: styleClass, resolvingToDefaultWith: resolver) {
							var colors = [GMSStrokeStyle]()
							var lenghts = [NSNumber]()
							let strokeStyle = GMSStrokeStyle.solidColor(strokeColor)
							let clearStrokeStyle = GMSStrokeStyle.solidColor(UIColor.clear)
							
							for (index, patternLength) in dashPattern.enumerated() {
								lenghts.append(patternLength)
								colors.append((index % 2 == 0) ? clearStrokeStyle : strokeStyle)
							}
							if let path = gmsPolyline.path {
								gmsPolyline.spans = GMSStyleSpans(path, colors, lenghts, .rhumb)
							}
						} else {
							gmsPolyline.strokeColor = strokeColor
						}
					}
				}
			}
			mapView.gxAdd(gmsPolyline, isRefreshable: isRefreshable)
		}
	}
	
	override func drawPolygon(_ polygon: GXPolygon, isRefreshable: Bool) {
		guard let mapView = self.googleMapView else { return }
		
		var gmsPolygon: GMSPolygon!
		if let polygon = polygon as? GMSPolygon {
			gmsPolygon = polygon
		}
		else {
			let path = GMSPath.path(from: polygon.gxMapCoordinates)
			let styleClass = polygon.polygonStyleClass ?? self.polygonStyleClass
			let resolver = GXStyleClassHelper.propertyDefaultResolver(for: styleClass, fallback: nil)
			DispatchQueue.gxSyncOnMain {
				gmsPolygon = GXGMSPolygon.init(path: path)
				if let styleClass = styleClass {
					gmsPolygon.fillColor = SDMapPolygonThemeClass.fillColor(from: styleClass, resolvingToDefaultWith: resolver)
					gmsPolygon.strokeWidth = SDMapPolygonThemeClass.lineWidth(from: styleClass, resolvingToDefaultWith: resolver)
					let strokeColor: UIColor = SDMapPolygonThemeClass.strokeColor(from: styleClass, resolvingToDefaultWith: resolver) ?? mapView.tintColor
// MARK: TODO: GMSPolygon does not have the .spans property
//					if let dashPattern = themeClass.lineDashPattern {
//						var colors = [GMSStrokeStyle]()
//						var lenghts = [NSNumber]()
//						let strokeStyle = GMSStrokeStyle.solidColor(strokeColor)
//						let clearStrokeStyle = GMSStrokeStyle.solidColor(UIColor.clear)
//
//						for (index, patternLength) in dashPattern.enumerated() {
//							lenghts.append(patternLength)
//							colors.append((index % 2 == 0) ? clearStrokeStyle : strokeStyle)
//						}
//						if let path = gmsPolygon.path {
//							gmsPolygon.spans = GMSStyleSpans(path, colors, lenghts, .rhumb)
//						}
//					} else {
						gmsPolygon.strokeColor = strokeColor
//					}
				}
			}
		}
		
		mapView.gxAdd(gmsPolygon, isRefreshable: isRefreshable)
	}
}

internal extension GMSPath {
	
	static func path(from coordinates: [CLLocationCoordinate2D]) -> GMSPath {
		let path = GMSMutablePath.init()
		for coordinate in coordinates {
			path.add(coordinate)
		}
		return path
	}
}
