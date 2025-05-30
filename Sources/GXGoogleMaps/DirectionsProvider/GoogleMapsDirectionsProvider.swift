//
//  GoogleMapsDirectionsProvider.swift
//

import CoreLocation
import GXCoreModule_Common_Maps
import GXObjectsModel
import MapKit

@objc(GoogleMapsDirectionsProvider)
open class GoogleMapsDirectionsProvider: NSObject, MapDirectionsHelperWithWaypoints {
	public func calculateDirections(fromSourceLocation source: CLLocationCoordinate2D,
									toDestinationLocation destination: CLLocationCoordinate2D,
									withTransportType transportType: GXTransportType, requestAlternateRoutes: Bool,
									completionHandler completionBlock: @escaping ([GXMapRoute]?, Error?) -> Void) {		
		let requestParameters = GXDirectionServiceRequestParamters.init(sourceLocation: source,
																		destinationLocation: destination,
																		transportType: transportType,
																		requestAlternateRoutes: requestAlternateRoutes,
																		waypoints: nil,
																		optimizeWaypoints: nil)
		
		GXGoogleDirectionsRequestHandlerWrapper.executeDirectionsRequest(withParameters: requestParameters,
																		 completionBlock: completionBlock)
	}

	public func calculateDirections(withWaypoints waypoints: [CLLocationCoordinate2D],
									withTransportType transportType: GXTransportType, requestAlternateRoutes: Bool,
									completionHandler completionBlock: @escaping ([GXMapRoute]?, Error?) -> Void) {
		var waypoints = waypoints
		if waypoints.count >= 2 {
			let source = waypoints.removeFirst()
			let destination = waypoints.removeLast()
			let requestParameters = GXDirectionServiceRequestParamters.init(sourceLocation: source,
																			destinationLocation: destination,
																			transportType: transportType,
																			requestAlternateRoutes: requestAlternateRoutes,
																			waypoints: waypoints,
																			optimizeWaypoints: false)
			
			GXGoogleDirectionsRequestHandlerWrapper.executeDirectionsRequest(withParameters: requestParameters,
																			 completionBlock: completionBlock)
		}
	}
}

private class GXGoogleDirectionsRequestHandlerWrapper: GXDirectionsServiceRequestHandlerWrapper {
	open override class func providerName() throws -> GXDirectionServiceProvider {
		return GXDirectionServiceProvider.Google
	}
	
	open override class func providerRouteClass() throws -> GXMapRouteWithInitialization.Type {
		return GXGoogleMapsRoute.self
	}
}
