//
//  GXControlGeoLocationMapKitHelper.swift
//

import GXCoreUI
internal import GoogleMaps

internal class GXControlGeoLocationGoogleMapsHelper : GXControlGeoLocationHelper, GMSMapViewDelegate {
	
	fileprivate var loadedAnnotationGMSMarker: GXGMSMarker? {
		guard let loadedAnnotation else {
			return nil
		}
#if DEBUG
		assert(loadedAnnotation is GXGMSMarker)
#endif
		return loadedAnnotation as? GXGMSMarker
	}
	
	fileprivate var isDragging = false
	
	override func newMapView(withFrame frame: CGRect) -> (UIView & GXMapView) {
		let mapOptions: GMSMapViewOptions = .init()
		mapOptions.frame = frame
		let mapView = GXControlGeoLocationGXMapView.init(options: mapOptions)
		//mapView.animate(toZoom: 15)
		mapView.delegate = self
		return mapView
	}
	
	deinit {
		if let mapView = loadedMapView as? GXGoogleMapsView {
			mapView.delegate = nil
		}
	}
	
	override func unloadMapView() {
		if let mapView = loadedMapView as? GXGoogleMapsView {
			mapView.delegate = nil
		}
		super.unloadMapView()
	}
}

// MARK: - GMSMapViewDelegate

extension GXControlGeoLocationGoogleMapsHelper {
	func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {
		guard mapView == loadedMapView, marker == loadedAnnotationGMSMarker, !readOnly else { return }
		
		self.isDragging = true
		
		if self.isTrackingLocation {
			self.stopUpdatingLocation()
		}
	}
	
	func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
		guard mapView == loadedMapView, let marker = marker as? GXGMSMarker, marker == loadedAnnotationGMSMarker, !readOnly else { return }
		
		self.isDragging = false
		
		self.internalUpdateAnnotationCoordinate(marker.coordinate,
												animateChange: true,
												animateDrop: false,
												showAnnotationOnChange: false)
	}
	
	func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
		guard let gxMapView = loadedMapView,  mapView == gxMapView, let marker = marker as? GXGMSMarker, marker == loadedAnnotationGMSMarker, !readOnly else { return }
		
		let view = gxMapView.gxView(for: marker)
		
		if self.isTrackingLocation {
			self.stopUpdatingLocation()
		}
		
		if (GXUtilities.currentDeviceIPAD()) {
			gxMapView.gxDeselect(marker, animated: false)
		}
		
		let modelObject = gxMapView.gxMapViewDelegate?.mapViewModelObject(gxMapView) ?? self.delegate?.geolocationHelperModelObject(self)
		let removePinTitle = GXResources.translation(for: kGXRemovePinString, modelObject: modelObject)
		let cancelPinTitle = GXResources.translation(for: kGXCancelString, modelObject: modelObject)
		let alertControler = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
		weak var unretainedSelf = self
		alertControler.addAction(UIAlertAction.init(title: removePinTitle,
													style: .destructive,
													handler: { (action) in
														let retainedSelf = unretainedSelf
														retainedSelf?.handleRemoveLoadedAnnotation()
		}))
		alertControler.addAction(UIAlertAction.init(title: cancelPinTitle,
													style: .cancel,
													handler: nil))
		self.delegate?.geolocationHelper(self, present: alertControler, fromSender: view ?? gxMapView, animated: true)
	}
	
	func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
		if mapView == self.loadedMapView,
		   let marker = marker as? GXGMSMarker,
		   marker.coordinate.latitude == self.loadedAnnotationGMSMarker?.coordinate.latitude,
		   marker.coordinate.longitude == self.loadedAnnotationGMSMarker?.coordinate.longitude {
			self.updateReadOnly(true, updateEnabled: true, annotation: nil, mapView: nil, annotationView: nil )
			self.reverseGeocodeLoadedAnnotation()
		}
		
		return false
	}
	
	func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
		guard !isDragging, !readOnly else { return }
		
		if isTrackingLocation {
			stopUpdatingLocation()
		}
		
		mapView.clear()
		internalUpdateAnnotationCoordinate(coordinate,
										   animateChange: true,
										   animateDrop: true,
										   showAnnotationOnChange: loadedAnnotation != nil)
		if let annotation = loadedAnnotation {
			(mapView as? GXMapView)?.gxSelect(annotation, animated: true)
		}
	}
	
	override static func createEmptyAnnotation() -> any GXMapAnnotationProtocol {
		let marker = GXGMSMarker.init()
		marker.isDraggable = true
		return marker
	}
}

internal class GXControlGeoLocationGXMapView : GXGoogleMapsView {
	private var tintColorIsCustom: Bool = false
	
	override func didMoveToSuperview() {
		super.didMoveToSuperview()
		self.adjustTintColorIfNeeded()
	}
	
	override func didMoveToWindow() {
		super.didMoveToWindow()
		self.adjustTintColorIfNeeded()
	}
	
	private func adjustTintColorIfNeeded() {
		if let superview = self.superview, let _ = self.window {
			let keyColor: UIColor = superview.tintColor
			if keyColor.gxHasLowContrastAgainstUserInterfaceStyle(from: self.traitCollection) {
				if (!self.tintColorIsCustom) {
					super.tintColor = GXUIKitConstants.UIColorDefaultKeyColor
				}
			} else if (!keyColor.isEqual(self.tintColor)) {
				tintColorIsCustom = false
				super.tintColor = nil
			}
		}
	}
	
	override var tintColor: UIColor! {
		get {
			return super.tintColor
		}
		set {
			if (newValue != nil) {
				tintColorIsCustom = true
				super.tintColor = nil
				self.adjustTintColorIfNeeded()
			}
		}
	}
}
