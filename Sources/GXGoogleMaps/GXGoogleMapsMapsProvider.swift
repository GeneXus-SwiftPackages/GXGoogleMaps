//
//  GXGoogleMapsMapsProvider.swift
//

import GXCoreBL
internal import GoogleMaps

@objc(GXGoogleMapsMapsProvider)
open class GXGoogleMapsMapsProvider : NSObject, GXMapsProviderProtocol {
	
	private let GoogleMapsApiIdentifier = "MAPS_GOOGLE"
	private let controlClasses: [GXMapsProvidersManager.MapControlType: AnyClass] = [
		.sdMaps: GXGoogleMapsList.self,
		.geoLocationHelper: GXControlGeoLocationGoogleMapsHelper.self,
		.directionsProvider: GoogleMapsDirectionsProvider.self
	]
	
	private var isInitialized: Bool = false
    
    @objc public var mapsApiIdentifier: String {
        GoogleMapsApiIdentifier
    }
    
    @objc open var initializationIsRequiered: Bool {
		return !isInitialized && !GXMiniProgramsHelper.isSuperAppNonGXApp
    }
    
    @objc open func getClass(forControlType controlType: String) -> AnyClass? {
		guard let knownControlType = GXMapsProvidersManager.MapControlType(rawValue: controlType) else {
			return nil
		}
        return controlClasses[knownControlType]
    }
    
    @objc open func initializeProvider() {
		guard initializationIsRequiered else {
			return
		}
		guard let apiKey = getApiKey() else {
			let log = GXFoundationServices.loggerService()
			log?.logMessage("Google Maps API key was not found", for: .general, with: .warning, logToConsole: true)
            return
        }
        isInitialized = true
        GMSServices.provideAPIKey(apiKey)
    }
	
	/// Initialization API key is extracted from the returned models
	open var modelsForAPIKey: [GXModel] {
		GXModelManager.shared.activeModels.filter(\.appModel.isEmbeddedApplication)
	}
	
	/// Extracts initialization API key from `modelsForAPIKey`
	public func getApiKey() -> String? {
		modelsForAPIKey.compactMapFirst { gxModel in
			let appEntryPoint = gxModel.appModel.mainEntryPoint
			guard let apiKey = appEntryPoint.value(forAppEntryPointProperty: kAppEntryPointPropertyAppleMapsApiKey) as? String,
				  let mapsProviderId = appEntryPoint.value(forAppEntryPointProperty: kAppEntryPointPropertyAppleMapsApi) as? String,
				  mapsProviderId == GoogleMapsApiIdentifier else {
				return nil
			}
			return apiKey
		}
    }
}
