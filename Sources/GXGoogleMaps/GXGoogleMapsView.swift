//
//  GXGoogleMapsView.swift
//

import GXCoreUI
internal import GoogleMaps
private import GoogleMapsUtils

internal class GXGoogleMapsView : GMSMapView, GXMapView {
	weak var gxMapViewDelegate: GXMapViewDelegate?
	
	override open var selectedMarker: GMSMarker? {
		didSet {
			if self.selectedMarker != oldValue {
				if let selectedMarker = self.selectedMarker {
					self.gxGMSMapViewDelegate?.mapView(self, didSelect: selectedMarker)
				} else if let oldValue = oldValue {
					self.gxGMSMapViewDelegate?.mapView(self, didDeselectMarker: oldValue)
				}
			}
		}
	}
	
	var gxMinZoomLevel: NSNumber? {
		return self.minZoom as NSNumber?
	}
	
	var gxMaxZoomLevel: NSNumber? {
		return self.maxZoom as NSNumber?
	}
	
	private var shownInfoWindw: MKAnnotationView?
	private var annotations: [GXGMSMarker] = []
	internal var overlays: Set<GMSOverlay> = []
	
	internal weak var gxGMSMapViewDelegate: GXGMSMapViewDelegate?
	
	func gxAnnotations() -> [MKAnnotation] {
		return annotations as [MKAnnotation]
	}
	
	func gxSelectedAnnotations() -> [MKAnnotation] {
		[selectedMarker].compactMap { $0  as? GXGMSMarker }
	}
	
	func gxRegionCenter() -> CLLocationCoordinate2D {
		return self.camera.target
	}
	
	func gxUserLocation() -> CLLocation? {
		return self.myLocation
	}
	
	func gxLongitudeDelta() -> CLLocationDegrees {
		return self.coordinateBounds.northEast.longitude - self.coordinateBounds.southWest.longitude
	}
	
	func gxLatitudeDelta() -> CLLocationDegrees {
		return self.coordinateBounds.northEast.latitude - self.coordinateBounds.southWest.latitude
	}
	
	func gxIsScrollEnabled() -> Bool {
		return self.settings.allowScrollGesturesDuringRotateOrZoom
	}
	
	private class GXGMUClusterRendererDelegateProxy : NSObject, GMUClusterRendererDelegate {
		fileprivate func renderer(_ renderer: GMUClusterRenderer, willRenderMarker marker: GMSMarker) {
			if let marker = marker as? GXGMSMarker, let gxMarker = marker.extractCustomMarkerIfNeeded() {
				marker.icon = gxMarker.icon
				marker.iconView = gxMarker.iconView
			}
		}
	}
	
	private let _GXGMUClusterRendererDelegateProxy = GXGMUClusterRendererDelegateProxy()
	
	internal var clusterMarkers: Bool = false {
		didSet {
			if clusterMarkers && clusterManager == nil {
				let renderer = GMUDefaultClusterRenderer(mapView: self,
														 clusterIconGenerator: GMUDefaultClusterIconGenerator())
				renderer.minimumClusterSize = 2 // Match MapKit default behavior
				renderer.delegate = self._GXGMUClusterRendererDelegateProxy
				
				clusterManager = GMUClusterManager(map: self,
												   algorithm: GMUNonHierarchicalDistanceBasedAlgorithm(),
												   renderer: renderer)
				clusterManager?.setMapDelegate(self.delegate)
			}
		}
	}
	
	private var clusterManager: GMUClusterManager?
	
	func gxAdd(_ annotation: MKAnnotation, isPersistent: Bool) {
		if let marker = annotation as? GXGMSMarker {
			annotations.append(marker)
			marker.appearAnimation = .pop
			if let iconView = self.gxGMSMapViewDelegate?.mapView(self, iconViewFor: marker) as? GXUC_MapCustomAnnotationView {
				if (iconView.image == nil || iconView.hasPlaceholderPinImage) {
					iconView.loadingDelegate = self
					marker.iconView = iconView
				} else {
					self.set(iconView.image!, for: marker)
				}
			}
			
			if clusterMarkers, let clusterManager {
				clusterManager.add(marker)
				clusterManager.requestCluster()
			} else {
				DispatchQueue.gxOnMain {
					marker.map = self
				}
			}
			
			if isPersistent {
#if DEBUG
				assert(marker is GXGoogleMapsMarker)
#endif
				(marker as? GXGoogleMapsMarker)?.isPersistent = isPersistent
			}
		}
	}
	
	func gxAdd(_ annotations: [MKAnnotation], arePersistent: Bool) {
		for annotation in annotations {
			self.gxAdd(annotation, isPersistent: arePersistent)
		}
	}
	
	func gxAdd(_ overlay: GMSOverlay, isRefreshable: Bool) {
		if isRefreshable {
			overlay.isRefreshable = isRefreshable
		}
		
		self.overlays.insert(overlay)
		
		DispatchQueue.gxOnMain {
			overlay.map = self
		}
	}
	
	func gxRemove(_ annotation: MKAnnotation) {
		if let annotation = annotation as? GMSMarker {
			if let clusterManager {
				clusterManager.remove(annotation)
				clusterManager.requestCluster()
			} else {
				if (annotation.map != nil) {
					weak var wAnnotation = annotation
					DispatchQueue.gxOnMain {
						wAnnotation?.map = nil
					}
				}
			}
			
			annotations = annotations.filter { $0 != annotation }
		}
	}
	
	func gxRemove(_ annotations: [MKAnnotation]) {
		if let annotations = annotations as? [GXGMSMarker] {
			for annotation in annotations {
				self.gxRemove(annotation)
			}
		}
	}
	
	func gxShow(_ annotations: [MKAnnotation], animated: Bool) {
		if let annotations = annotations as? [GXGMSMarker] {
			let bounds = annotations.reduce(GMSCoordinateBounds()) {
				$0.includingCoordinate($1.position)
			}
			DispatchQueue.gxOnMain {
				self.updateCamera(newCoordinateBounds: bounds, animated: animated)
			}
		}
	}
	
	func gxSelect(_ annotation: MKAnnotation, animated: Bool) {
		if let annotation = annotation as? GXGMSMarker {
			if (annotations.contains(annotation)) {
				DispatchQueue.gxOnMain {
					self.selectedMarker = annotation
				}
			}
		}
	}
	
	func gxSelectAnnotation(at indexPath: IndexPath, animated: Bool) {
		if let marker = self.annotations.filter({ (marker) -> Bool in
			guard let marker = marker as? GXGoogleMapsPinMarker else {
				return false
			}
			return marker.indexPath == indexPath
		}).first {
			self.gxSetCenter(marker.coordinate, animated: animated)
			self.selectedMarker = marker
		}
	}
	
	func gxDeselect(_ annotation: MKAnnotation?, animated: Bool) {
		DispatchQueue.gxOnMain {
			self.selectedMarker = nil
		}
	}
	
	func gxDeselectAnnotation(at indexPath: IndexPath, animated: Bool) {
		DispatchQueue.gxOnMain {
			if let selectedMarker = self.selectedMarker as? GXGoogleMapsPinMarker {
				if selectedMarker.indexPath == indexPath {
					self.selectedMarker = nil
				}
			}
		}
	}
	
	func gxSetShowsUserLocation(_ showLocation: Bool) {
		DispatchQueue.gxOnMain {
			self.isMyLocationEnabled = showLocation
			self.settings.myLocationButton = showLocation;
		}
	}
	
	func gxSetGXMapType(_ gxMapType: GXMapType) {
		var newMapType: GMSMapViewType!;
		switch gxMapType {
		case .hybrid:
			newMapType = .hybrid
			
		case .satellite:
			newMapType = .satellite
			
		default:
			newMapType = .normal
		}
		DispatchQueue.gxOnMain {
			self.mapType = newMapType
		}
	}
	
	func gxView(for annotation: MKAnnotation) -> MKAnnotationView? {
		if let selectedMarker = selectedMarker, let annotation = annotation as? GMSMarker {
			if annotation == selectedMarker {
				return shownInfoWindw
			}
		}
		return nil
	}
	
	var gxMapViewCenter: CGPoint {
		get {
			var centerPoint = self.projection.point(for: self.camera.target)
			let insets = self.safeAreaInsets
			centerPoint.x = centerPoint.x + insets.left / 2 - insets.right / 2
			centerPoint.y = centerPoint.y + insets.top / 2 - insets.bottom / 2
			return centerPoint
		}
	}
	
	func gxSetCenter(_ newCenterCoordinate: CLLocationCoordinate2D, withZoomLevel zoomLevel: Float, animated: Bool) {
		DispatchQueue.gxOnMain {
			let newCameraPosition = GMSCameraPosition.camera(withTarget: newCenterCoordinate, zoom: zoomLevel)
			if (animated) {
				self.animate(to: newCameraPosition)
			} else {
				self.camera = newCameraPosition
			}
		}
	}
	
	func gxSetCenter(_ newCenterCoordinate: CLLocationCoordinate2D, animated: Bool) {
		self.gxSetCenter(newCenterCoordinate, withZoomLevel: self.camera.zoom, animated: animated)
	}
	
	func gxSetZoomLevel(_ zoomLevel: Float, animated: Bool) {
		self.gxSetCenter(self.gxRegionCenter(), withZoomLevel: zoomLevel, animated: animated)
	}
	
	func gxSetMinZoomLevel(_ minZoomLevel: Float) {
		self.setMinZoom(minZoomLevel, maxZoom: self.maxZoom)
	}
	
	func gxSetMaxZoomLevel(_ maxZoomLevel: Float) {
		self.setMinZoom(self.minZoom, maxZoom: maxZoomLevel)
	}
	
	func gxZoomLevel() -> Float {
		return self.camera.zoom
	}
	
	func gxConvert(_ point: CGPoint, toCoordinateFrom mapView: UIView) -> CLLocationCoordinate2D {
		let mapPoint = mapView.convert(point, to: mapView)
		return self.projection.coordinate(for: mapPoint)
	}
	
	func gxVisibleMapRect() -> MKMapRect {
		let region = self.projection.visibleRegion()

		let x = min(region.nearLeft.latitude, region.farRight.latitude)
		let y = min(region.nearLeft.longitude, region.farRight.longitude)
		let width  = abs(region.nearLeft.latitude - region.farRight.latitude)
		let height = abs(region.nearLeft.longitude - region.farRight.longitude)
		
		return MKMapRect.init(x: x, y: y, width: width, height: height)
	}
	
	func gxSetVisibleMapRect(_ mapRect: MKMapRect, edgePadding adjustedMapViewEdgePadding: UIEdgeInsets, animated: Bool) {
		let northEastPoint = MKMapPoint.init(x: mapRect.maxX, y: mapRect.origin.y)
		let southWestPoint = MKMapPoint.init(x: mapRect.origin.x, y: mapRect.maxY)
		
		let coordinateBounds = GMSCoordinateBounds.init(coordinate: northEastPoint.coordinate,
														coordinate: southWestPoint.coordinate)
		
		self.updateCamera(newCoordinateBounds: coordinateBounds, with: adjustedMapViewEdgePadding, animated: animated)
	}
	
	func gxClearPolylines() {
		let isUserOverlay: (GMSOverlay) -> Bool = { (overlay) -> Bool in
			return overlay.isRefreshable
		}
		
		self.overlays
			.filter { isUserOverlay($0) }
			.forEach { (overlay) in overlay.map = nil }
		self.overlays = self.overlays
			.filter { !isUserOverlay($0) }
	}
	
	func gxClear() { self.gxClear(removeAll: true) }
	
	func gxClear(removeAll: Bool) {
		self.gxRemove(self.annotations)
		
		var iterator = self.overlays.makeIterator()
		while let overlay = iterator.next() {
			if removeAll || !((overlay as? GXGoogleMapsMarker)?.isPersistent ?? false) {
				DispatchQueue.gxOnMain {
					overlay.map = nil
				}
				self.overlays.remove(overlay)
			}
		}
	}
	
	override var frame: CGRect {
		didSet { self.gxMapViewDelegate?.didResizeMapView(self) }
	}

	
	//MARK: - Internal Helpers
	
	private var coordinateBounds: GMSCoordinateBounds {
		return GMSCoordinateBounds(region: self.projection.visibleRegion())
	}
	
	private func updateCamera(newCoordinateBounds: GMSCoordinateBounds, animated:Bool) {
		DispatchQueue.gxOnMain {
			self.updateCamera(newCoordinateBounds: newCoordinateBounds, with: .zero, animated: animated)
		}
	}
	
	private func updateCamera(newCoordinateBounds: GMSCoordinateBounds, with insets: UIEdgeInsets, animated:Bool) {
		if let newCameraPosition = self.camera(for: newCoordinateBounds, insets: insets) {
			let cameraUpdate = GMSCameraUpdate.setCamera(newCameraPosition)
			
			DispatchQueue.gxOnMain {
				if animated {
					self.animate(with: cameraUpdate)
				} else {
					self.moveCamera(cameraUpdate)
				}
			}
		}
	}
	
	fileprivate func set(_ image: UIImage, for marker: GMSMarker) {
		marker.icon = image
	}
}

extension GXGoogleMapsView : GXMapCustomAnnotationViewLoadingDelegate {
	func didSet(_ image: UIImage, for annotation: MKAnnotation) {
		if let marker = annotation as? GMSMarker {
			marker.iconView = nil
			marker.tracksViewChanges = false
			self.set(image, for: marker) 
		}
	}
}

private extension GMUClusterManager {
	private struct Constants {
		static let CLUSTER_REQUEST_COUNT_IVAR_NAME = "_clusterRequestCount"
		static let GMU_CLUSTER_WAIT_INTERVAL_SECONDS = 0.2
	}
	
	
	func requestCluster() {
		guard var clusterRequestCount = self.value(forKey: Constants.CLUSTER_REQUEST_COUNT_IVAR_NAME) as? UInt else {
			self.cluster()
			return
		}
		
		clusterRequestCount += 1
		self.setValue(clusterRequestCount, forKey: Constants.CLUSTER_REQUEST_COUNT_IVAR_NAME)
		
		DispatchQueue.main.asyncAfter(deadline: .now() + Constants.GMU_CLUSTER_WAIT_INTERVAL_SECONDS) { [weak self] in
			guard let strongSelf = self else { return }
			guard clusterRequestCount == strongSelf.clusterRequestCount() else { return }
			
			strongSelf.cluster()
		}
	}
}

internal class GXGoogleMapsMarker : GXGMSMarker {
	var isPersistent: Bool {
		get { gxUserData["isPersistent"] as? Bool ?? false }
		set { gxUserData["isPersistent"] = newValue }
	}
	
	var clusteringMarker: GXGMSMarker? {
		get { gxUserData["clusteringMarker"] as? GXGoogleMapsMarker }
		set { gxUserData["clusteringMarker"] = newValue }
	}
	
	var clusteringMarkerOrSelf: GXGMSMarker {
		get { clusteringMarker ?? self }
	}
	
	// MARK: - Private
	
	private var _gxUserData: [String : Any]!
	private var gxUserData: [String : Any] {
		get {
			if _gxUserData == nil {
				_gxUserData = [:] as [String : Any]
			}
			
			return _gxUserData
		}
		set { _gxUserData = newValue }
	}
}

internal extension GMSOverlay {
	var isRefreshable : Bool {
		get { gxUserData["isRefreshable"] as? Bool ?? false }
		set { gxUserData["isRefreshable"] = newValue }
	}
	
	private var gxUserData: [String : Any]! {
		get {
			if self.userData == nil {
				self.userData = [:] as [String : Any]
			}
			
			return self.userData as? [String : Any]
		}
		set { self.userData = newValue }
	}
}

internal protocol GXGMSMapViewDelegate: NSObjectProtocol {
	func mapView(_ mapView: GMSMapView, iconViewFor marker: GMSMarker) -> UIView?
	
	func mapView(_ mapView: GMSMapView, calloutViewFor marker: GMSMarker) -> UIView?
	
	func mapView(_ mapView: GMSMapView, didSelect marker: GMSMarker)
	
	func mapView(_ mapView: GMSMapView, didDeselectMarker: GMSMarker)
}
