//
//  GXUC_MapsPinMarker.swift
//

import GXCoreUI
internal import GoogleMaps

internal class GXGoogleMapsPinMarker : GXGoogleMapsMarker, GXUC_MapPinAnnotation {
	
	public var entityData: GXEntityData
    
    public var indexPath: IndexPath?
	
	public var animationKey: String?
	
	public var geometryLayerId: String?
	
	public var geometryId: String
    
    public var pinImageFieldValue: Any?
    
    public var pinImageStyleClass: GXStyleClass?
	
	public var annotationView: UIView?
	
	public var animationIndex: UInt;
    
	public required init(location: CLLocationCoordinate2D, entityData: GXEntityData, indexPath: IndexPath?, animationKey: String?, geometryLayerId: String?) {
        self.entityData = entityData
        self.indexPath  = indexPath
		self.animationKey = animationKey
		self.animationIndex = UInt.min
		self.geometryLayerId = geometryLayerId
		self.geometryId = GXUUID.create().uuidString
		
        super.init()
		
		self.position = location
    }
    
	override open func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
}

extension GXGoogleMapsPinMarker {
	public var forwardAnimator: UIViewPropertyAnimator? {
		get {
			return nil
		}
		set {
			return
		}
	}
	
	public var backwardAnimator: UIViewPropertyAnimator? {
		get {
			return nil
		}
		set {
			return
		}
	}
}
