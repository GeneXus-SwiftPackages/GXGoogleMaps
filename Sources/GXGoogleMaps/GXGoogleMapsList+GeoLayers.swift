//
//  GXGoogleMapsList+GeoLayers.swift
//

internal import GoogleMaps
internal import GoogleMapsUtils
import GXUCMaps

extension GXGoogleMapsList {
	
	open override func executeMethod_LoadKMLLayer(_ layerId: String, layerData: String, allowSelection: Bool) -> Int {
		let layerData = Self.unescapeKMLString(layerData)
		guard let data = layerData.data(using: .utf8) else {
			return Int(GXMapsLoadLayerErrorCode.invalidKML.rawValue)
		}
		
		let kmlParser = GMUKMLParser(data: data)
		kmlParser.parse()
		
		guard let gmsMapView = self.googleMapView else {
			return -1 // TODO Geolayers
		}
		let renderer = GMUGeometryRenderer(map: gmsMapView, geometries: kmlParser.placemarks, styles: kmlParser.styles)
		
		renderer.render()
		for overlay in renderer.mapOverlays() {
			(overlay as? GXGoogleMapsMarker)?.isPersistent = true
			gmsMapView.overlays.insert(overlay)
		}
		
		return Int(GXMapsLoadLayerErrorCode.ok.rawValue)
	}
	
}
