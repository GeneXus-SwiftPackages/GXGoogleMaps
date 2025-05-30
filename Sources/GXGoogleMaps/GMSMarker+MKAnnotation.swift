//
//  GMSMarker+MKAnnotation.swift
//

internal import GoogleMaps
import MapKit
import GXCoreUI

internal class GXGMSMarker: GMSMarker, GXMapAnnotationProtocol, MKAnnotation {
	public var coordinate: CLLocationCoordinate2D {
		get { position }
		set { position = newValue }
	}
	
	public var subtitle: String? {
		get { snippet }
		set { snippet = newValue }
	}
}

internal extension GXGMSMarker {
	/// Extract an instance of GXGoogleMapsMarker from the current marker's userData
	/// The clustering algorithm wraps the original GMSMarker instnace inside here
	/// - Returns: The extracted instance of ``GXGoogleMapsMarker`` (if any) or nil
	@objc func extractCustomMarkerIfNeeded() -> GXGoogleMapsMarker? {
		if let customMarker = self as? GXGoogleMapsMarker {
			return customMarker
		}
		
		if let userData = self.userData as? GXGoogleMapsMarker {
			let extractedMarker = userData
			extractedMarker.clusteringMarker = self
			
			return extractedMarker
		}
		
		return nil
	}
}
