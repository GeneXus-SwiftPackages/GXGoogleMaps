import UIKit
import CoreLocation
internal import GoogleMaps
import GXUCMaps

@objc(GXGoogleMapsList)
internal class GXGoogleMapsList: GXUC_MapList {
	
	// MARK: - Properties
	private var regionChangedSinceLastZoomToFitMapAnnotations = false
	private var openedInfoWindow: GXUC_MapListCalloutAnnotationView?
	private var mapViewEdgePadding = UIEdgeInsets.zero
	private var infoWindowAnimationTimer: Timer?
	//private var isCalloutVisible = false
	private var isHandlingCalloutTap = false
	private var cancelNextCameraMovement = false
	private var ignoreNextCameraMovement = false
	
	
	internal var googleMapView: GXGoogleMapsView? {
		gridView as? GXGoogleMapsView
	}
	
	// MARK: - Lifecycle
	
	/// Creates a new grid view with the specified frame.
	///
	/// - Parameter frame: The frame rectangle for the view, measured in points.
	/// - Returns: A new `UIView` instance configured as a Google Maps view.
	override func newGridView(withFrame frame: CGRect) -> UIView {
		regionChangedSinceLastZoomToFitMapAnnotations = false
		
		let mapOptions = GMSMapViewOptions()
		mapOptions.frame = frame
		
		let mapView = GXGoogleMapsView(options: mapOptions)
		configureMapView(mapView)
		
		return mapView
	}
	
	/// Configures the provided Google Maps view with the necessary settings.
	///
	/// - Parameter mapView: The `GXGoogleMapsView` instance to configure.
	private func configureMapView(_ mapView: GXGoogleMapsView) {
		mapView.insetsLayoutMarginsFromSafeArea = false
		mapView.layoutMargins = .zero
		mapViewEdgePadding = .zero
		mapView.preservesSuperviewLayoutMargins = false
		mapView.delegate = self
		mapView.gxGMSMapViewDelegate = self
		mapView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
		mapView.gxSetGXMapType(mapType)
		mapView.isTrafficEnabled = showTraffic
		mapView.clusterMarkers = isClusteringEnabled
		
		if showMyLocation && requestLocationAuthorizationIfNeeded() {
			mapView.gxSetShowsUserLocation(true)
		}
	}
	
	/// Updates the theme class for the grid view entity data cells grid item.
	///
	/// This method overrides the superclass implementation to specifically handle the theme class for the Google Maps view.
	/// It ensures that the `openedInfoWindow`'s style class is updated based on the list item style configuration.
	///
	/// - Parameter gridView: The `UIView` instance representing the grid view.
	override func updateGridViewEntityDataCellsGridItemThemeClass(_ gridView: UIView) {
		super.updateGridViewEntityDataCellsGridItemThemeClass(gridView)
		
		guard mapView == gridView, let openedInfoWindow else { return }
		
		if sameOddAndEvenListItemStyleClass {
			openedInfoWindow.gridItemStyleClass = listItemEvenItemClass
		} else if let pinMarker = self.openedInfoWindow?.annotation as? GXGoogleMapsPinMarker, let indexPath = pinMarker.indexPath {
			let evenCell = indexPath.gxEntityDataIndex % 2 != 0
			openedInfoWindow.gridItemStyleClass = evenCell ? listItemEvenItemClass : listItemOddItemClass
		}
	}
	
	/// Deinitializes the instance and performs necessary cleanup.
	///
	/// This method ensures that the Google Maps view is properly cleaned up by calling `cleanupMapView` before the instance is deallocated.
	deinit {
		cleanupMapView()
	}
	
	// MARK: - View Management
	
	/// Unloads the view and performs necessary cleanup.
	///
	/// This method overrides the superclass implementation to include additional cleanup specific to the Google Maps view.
	override func unloadView() {
		cleanupMapView()
		super.unloadView()
	}
	
	/// Cleans up the Google Maps view by removing its delegates.
	private func cleanupMapView() {
		googleMapView?.delegate = nil
		googleMapView?.gxGMSMapViewDelegate = nil
	}
	
	/// The frame rectangle for the view, measured in points.
	///
	/// This property overrides the superclass implementation to handle specific behavior when the frame size changes.
	/// If the frame is empty or its size changes, it cancels the next camera movement.
	override var frame: CGRect {
		get {
			super.frame
		}
		set {
			if self.frame.isEmpty || self.frame.size != newValue.size {
				cancelNextCameraMovement = true
			}
			super.frame = newValue
		}
	}
	
	/// Zooms the map to fit all annotations.
	///
	/// This method overrides the superclass implementation to ensure that the map view properly adjusts before zooming.
	/// It prepares the map view for the zoom operation.
	///
	/// - Parameter animated: A Boolean value indicating whether the zoom should be animated.
	override func zoom(toFitMapAnnotations animated: Bool) {
		cancelNextCameraMovement = false
		super.zoom(toFitMapAnnotations: animated)
	}
	
	// MARK: - Info Window Management
	
	/// Disables the refresh of the pin info window.
	///
	/// This method stops the info window from updating its content while an animation is in progress.
	/// It also invalidates and clears the info window animation timer.
	@objc private func disablePinInfoWindowRefresh() {
		guard ((openedInfoWindow?.layer.animationKeys()?.isEmpty) != nil) else { return }
		
		self.googleMapView?.selectedMarker?.tracksInfoWindowChanges = false
		infoWindowAnimationTimer?.invalidate()
		infoWindowAnimationTimer = nil
	}
	
	// MARK: - Annotation Management
	
	/// Adds an annotation to the map at the specified location.
	///
	/// This method creates a new pin annotation with the provided location, entity data, and other parameters.
	/// The annotation is then added to the map view.
	///
	/// - Parameters:
	///   - location: The coordinate where the annotation should be placed.
	///   - entityData: The data associated with the annotation.
	///   - indexPath: The index path of the annotation in the data source.
	///   - animationKey: An optional key for identifying the animation.
	///   - pinImageFieldValue: An optional value for the pin image.
	///   - pinImageStyleClass: An optional style class for the pin image.
	///   - geometryLayerId: An optional identifier for the geometry layer.
	/// - Returns: The created pin annotation.
	override func addAnnotation(
		withLocation location: CLLocationCoordinate2D,
		entitiyData entityData: GXEntityData,
		indexPath: IndexPath?,
		animationKey: String?,
		pinImageFieldValue: Any?,
		pinImageStyleClass: GXStyleClass?,
		geometryLayerId: String?
	) -> GXUC_MapPinAnnotation {
		let pin = GXGoogleMapsPinMarker(
			location: location,
			entityData: entityData,
			indexPath: indexPath,
			animationKey: animationKey,
			geometryLayerId: geometryLayerId
		)
		
		pin.pinImageFieldValue = pinImageFieldValue
		pin.pinImageStyleClass = pinImageStyleClass
		
		mapView?.gxAdd(pin, isPersistent: false)
		
		return pin
	}
	
	/// Updates the position of an existing annotation with an animation.
	///
	/// This method moves the specified annotation to a new position over a given duration.
	/// The animation can be repeated or the annotation can be removed based on the repeat behavior.
	///
	/// - Parameters:
	///   - annotation: The annotation to be moved.
	///   - position: The new coordinate for the annotation.
	///   - duration: The duration of the animation.
	///   - repeatBehavior: The behavior to apply when the animation completes.
	func update(
		annotation: GXUC_MapPinAnnotation,
		toPosition position: CLLocationCoordinate2D,
		withDuration duration: TimeInterval,
		repeatBehavior: GXUCMapListAnimationEndBehavior
	) {
		let initialPosition = annotation.coordinate
		
		guard initialPosition.latitude != position.latitude ||
				initialPosition.longitude != position.longitude else { return }
		
		guard let marker = annotation as? GXGoogleMapsPinMarker else { return }
		
		let animationIndex = marker.animationIndex + 1
		marker.animationIndex = animationIndex
		
		animate(
			marker: marker,
			toPosition: position,
			duration: duration,
			repeatBehavior: repeatBehavior,
			animationIndex: animationIndex
		)
	}
	
	/// Animates the movement of a marker to a new position.
	///
	/// This private method handles the core animation logic for moving a specified marker to a new position over a given duration.
	/// It supports different behaviors upon animation completion, such as repeating the animation, removing the marker, or simply stopping.
	///
	/// - Parameters:
	///   - marker: The marker to be animated.
	///   - position: The new coordinate for the marker.
	///   - duration: The duration of the animation.
	///   - repeatBehavior: The behavior to apply when the animation completes.
	///     - `.repeat`: The animation will repeat, moving the marker back to its initial position.
	///     - `.disappear`: The marker will be removed from the map upon animation completion.
	///     - `.stop`: The animation will stop, leaving the marker at the new position.
	///   - animationIndex: The index of the current animation, used to ensure the correct animation is being processed.
	private func animate(
		marker: GXGoogleMapsPinMarker,
		toPosition position: CLLocationCoordinate2D,
		duration: TimeInterval,
		repeatBehavior: GXUCMapListAnimationEndBehavior,
		animationIndex: UInt
	) {
		let initialPosition = marker.position
		
		CATransaction.begin()
		CATransaction.setAnimationDuration(duration)
		
		CATransaction.setCompletionBlock { [weak self] in
			guard let self = self,
				  animationIndex == marker.animationIndex else { return }
			
			switch repeatBehavior {
			case .repeat:
				self.animate(
					marker: marker,
					toPosition: initialPosition,
					duration: duration,
					repeatBehavior: repeatBehavior,
					animationIndex: animationIndex
				)
			case .disappear:
				self.mapView?.gxRemove(marker)
				if let animationKey = marker.animationKey {
					self.removeAnimatedAnnotation(withKey: animationKey)
				} else {
#if DEBUG
					assertionFailure("Tried to remove market without an animationKey")
#endif
				}
			default:
				break
			}
		}
		
		marker.position = position
		CATransaction.commit()
	}
}

extension GXGoogleMapsList : GXGMSMapViewDelegate {
	/// Returns a custom or default annotation view for the specified marker.
	/// - Parameters:
	///   - mapView: The GMSMapView that requested the annotation view.
	///   - marker: A custom GXGoogleMapsPinMarker associated with the requested view.
	/// - Returns: A UIView (MKAnnotationView subclass) representing the marker, or nil to use a default view.
	func mapView(_ mapView: GMSMapView, iconViewFor marker: GMSMarker) -> UIView? {
		guard let marker = marker as? GXGoogleMapsPinMarker else {
#if DEBUG
			preconditionFailure("Unexpected marker type")
#else
			return nil
#endif
		}
		
		/// Check if there's a valid pin image; if not, use the default pin view.
		let useDefaultPinView = GXUtilities.nonEmptyString(from: marker.pinImageFieldValue) == nil
		var markerIconView: MKAnnotationView?
		
		if useDefaultPinView {
			// No custom icon needed
			markerIconView = nil
		} else {
			// Try casting our current view; if nil, create a new custom view
			let customView = GXUC_MapCustomAnnotationView(annotation: marker, reuseIdentifier: nil)
			
			// Apply the pin image from entity data
			customView.gxSetImage(fromEntityDataFieldValue: marker.pinImageFieldValue, modelObject: self.layoutElement)
			
			// Adjust marker offset so the pin tip aligns with its coordinate
			let height = markerIconView?.bounds.size.height ?? 0
			markerIconView?.centerOffset = CGPoint(x: 0, y: -height / 2)
			
			// Disable default callout and set callout offset
			markerIconView?.canShowCallout = false
			markerIconView?.calloutOffset = CGPoint(x: -5, y: 5) // Match MapKit's offset
			
			markerIconView = customView
		}
		
		return markerIconView
	}
	
	/// Returns a custom callout view for the specified marker.
	/// - Parameters:
	///   - mapView: The GMSMapView that requested the callout view.
	///   - marker: A custom GXGoogleMapsPinMarker for which the callout view is provided.
	/// - Returns: A UIView representing the custom callout, or nil for no custom callout.
	func mapView(_ mapView: GMSMapView, calloutViewFor marker: GMSMarker) -> UIView? {
		guard let marker = marker as? GXGoogleMapsPinMarker else {
#if DEBUG
			preconditionFailure("Unexpected marker type")
#else
			return nil
#endif
		}
		
		guard let indexPath = marker.indexPath else { return nil }
		let pIndexPathRow = indexPath.gxEntityDataIndex
		let pIndexPathSection = indexPath.gxEntityDataSection
		
		/// This is zero-based, but in GX it is one-based; hence, we check for != 0 to determine evenness (what would be odd in GX is even here).
		let evenCell = pIndexPathRow % 2 != 0
		
		// Select the appropriate style class based on row parity
		let listItemStyleClass = evenCell ? self.listItemEvenItemClass : self.listItemOddItemClass
		
		// Inner table that represents the content displayed in the callout
		let innerTable = self.gxControlTableForEntity(at: UInt(pIndexPathRow), section: UInt(pIndexPathSection))
		let calloutMapAnnotationView = GXUC_MapListCalloutAnnotationView(
			innerTable: innerTable,
			annotation: marker.clusteringMarkerOrSelf,
			reuseIdentifier: nil
		)
		
		calloutMapAnnotationView.gridItemDelegate = self
		calloutMapAnnotationView.gridItemHighlightStyleModifiers = .highlightAllowed
		calloutMapAnnotationView.gridItemStyleClass = listItemStyleClass
		
		self.openedInfoWindow = calloutMapAnnotationView
		
		return calloutMapAnnotationView
	}
	
	/// Called when a marker is selected on the map.
	/// - Parameters:
	///   - mapView: The GMSMapView reporting the event.
	///   - marker: The selected GMSMarker.
	func mapView(_ mapView: GMSMapView, didSelect marker: GMSMarker) {
		fireSelectionChangedEvent()
	}
	
	/// Called when a marker is deselected on the map.
	/// - Parameters:
	///   - mapView: The GMSMapView reporting the event.
	///   - didDeselectMarker: The GMSMarker that was deselected.
	func mapView(_ mapView: GMSMapView, didDeselectMarker: GMSMarker) {
		fireSelectionChangedEvent()
	}
}

// MARK: - GMSMapViewDelegate

extension GXGoogleMapsList: GMSMapViewDelegate {
	
	/// Called when the map view is about to move.
	///
	/// This delegate method handles the behavior when the map view is about to move, either due to a gesture or programmatically.
	/// If a camera movement cancellation is flagged, it prevents the camera from moving and resets it to the current position.
	/// Otherwise, it marks that the region has changed since the last zoom to fit map annotations.
	///
	/// - Parameter mapView: The `GMSMapView` instance that is about to move.
	/// - Parameter gesture: A Boolean value indicating whether the movement is caused by a user gesture.
	func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
		if cancelNextCameraMovement {
			cancelNextCameraMovement = false
			ignoreNextCameraMovement = true
			mapView.camera = mapView.camera // Reset the camera to the current position
		} else {
			regionChangedSinceLastZoomToFitMapAnnotations = true
		}
	}
	
	/// Called when the map view's camera position changes.
	///
	/// This delegate method handles the behavior when the map view's camera position changes.
	/// If the selection layer is enabled and the camera movement is not being ignored, it fires a `GXControlEventNameControlValueChanging` event.
	/// This indicates that the control value is in the process of changing due to the camera movement.
	///
	/// - Parameter mapView: The `GMSMapView` instance whose camera position changed.
	/// - Parameter position: The new camera position.
	func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
		if !ignoreNextCameraMovement, isSelectionLayerEnabled {
			fireLocationSelectionEventIfNeeded(withName: GXControlEventNameControlValueChanging)
		}
	}
	
	/// Called when the map view becomes idle after a camera movement.
	///
	/// This delegate method handles the behavior when the map view becomes idle after a camera movement.
	/// If the selection layer is enabled and the camera movement is not being ignored, it fires a `GXControlEventNameControlValueChanged` event.
	/// This indicates that the control value has finished changing as the camera movement has come to a stop.
	///
	/// - Parameter mapView: The `GMSMapView` instance that became idle.
	/// - Parameter position: The camera position at the time the map view became idle.
	func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
		if !ignoreNextCameraMovement, isSelectionLayerEnabled {
			fireLocationSelectionEventIfNeeded(withName: GXControlEventNameControlValueChanged)
		}
		ignoreNextCameraMovement = false
	}
	
	/// Provides a custom info window for the specified marker.
	///
	/// This delegate method returns a custom view to be used as the info window for the specified marker.
	/// If the marker is of the correct type and has a non-empty callout layout, it makes the callout visible and prepares the info window for display.
	///
	/// - Parameter mapView: The `GMSMapView` instance requesting the info window.
	/// - Parameter marker: The `GMSMarker` instance for which the info window is requested.
	/// - Returns: A `UIView` instance to be used as the info window, or `nil` if no custom info window is provided.
	func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
		guard let marker = marker as? GXGMSMarker else {
#if DEBUG
			assertionFailure("Invalid marker type")
#endif
			return nil
		}
		
		let actualMarker = marker.extractCustomMarkerIfNeeded()
		
		guard let pinMarker = actualMarker as? GXGoogleMapsPinMarker, !isCalloutLayoutEmpty(for: pinMarker) else { return nil }
		
		//isCalloutVisible = true
		pinMarker.clusteringMarkerOrSelf.tracksInfoWindowChanges = true
		
		let view = self.mapView(mapView, calloutViewFor: pinMarker)
		
		infoWindowAnimationTimer = Timer.scheduledTimer(
			timeInterval: 1,
			target: self,
			selector: #selector(disablePinInfoWindowRefresh),
			userInfo: nil,
			repeats: false)
		
		return view
	}
	
	/// Handles the event when the info window of a marker on the map is closed.
	///
	/// - Parameters:
	/// - mapView: The GMSMapView instance that triggered the event.
	/// - marker: The marker whose info window was closed.
	func mapView(_ mapView: GMSMapView, didCloseInfoWindowOf marker: GMSMarker) {
		// Check if the marker is of a custom type to update callout visibility
		if marker is GXGoogleMapsPinMarker {
			//_isCalloutVisible = false
		}
		
		// Invalidate and clear the info window animation timer
		infoWindowAnimationTimer?.invalidate()
		infoWindowAnimationTimer = nil
		
		// Clear the opened info window reference
		self.openedInfoWindow = nil
	}
	
	/// Handles the event when the info window of a marker on the map is tapped.
	///
	/// - Parameters:
	/// - mapView: The GMSMapView instance that triggered the event.
	/// - marker: The marker whose info window was tapped.
	func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
		guard let marker = marker as? GXGoogleMapsPinMarker else {
			return
		}
		
		self.isHandlingCalloutTap = true
		
		guard let indexPath = marker.indexPath else {
			return
		}
		
		// Extract entity data indices from the marker
		let pIndexPathRow = UInt(indexPath.gxEntityDataIndex)
		let pIndexPathSection = UInt(indexPath.gxEntityDataSection)
		
		let infoWindow = self.openedInfoWindow
		
		// Delay the default action so the selection event fires first
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
			guard let self else { return }
			
			if self.canExecuteDefaultActionForEntity(at: pIndexPathRow, section: pIndexPathSection) {
				self.executeDefaultActionForEntity(
					at: pIndexPathRow,
					section: pIndexPathSection,
					from: infoWindow?.gridItemTable
				)
			}
		}
		
		// Deselect the marker to visually dismiss it
		googleMapView?.gxDeselect(marker, animated: true)
		
		// After a delay, reset the handling state so it doesn't affect other markers
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
			guard let self else { return }
			
			self.isHandlingCalloutTap = false
		}
	}
}
