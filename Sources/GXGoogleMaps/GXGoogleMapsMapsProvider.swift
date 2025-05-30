//
//  GXGoogleMapsMapsProvider.swift
//

import GXCoreBL
internal import GoogleMaps

@objc(GXGoogleMapsMapsProvider)
class GXGoogleMapsMapsProvider : NSObject, GXMapsProviderProtocol {
	
	private let GoogleMapsApiIdentifier = "MAPS_GOOGLE"
	private let controlClasses: [GXMapsProvidersManager.MapControlType: AnyClass] = [
		.sdMaps: GXGoogleMapsList.self,
		.geoLocationHelper: GXControlGeoLocationGoogleMapsHelper.self,
		.directionsProvider: GoogleMapsDirectionsProvider.self
	]
	
	private var isInitialized: Bool = false
    
    @objc var mapsApiIdentifier: String {
        GoogleMapsApiIdentifier
    }
    
    @objc var initializationIsRequiered: Bool {
		return !isInitialized && !GXMiniProgramsHelper.isSuperAppNonGXApp
    }
    
    @objc func getClass(forControlType controlType: String) -> AnyClass? {
		guard let knownControlType = GXMapsProvidersManager.MapControlType(rawValue: controlType) else {
			return nil
		}
        return controlClasses[knownControlType]
    }
    
    @objc func initializeProvider() {
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
    
    // MARK: - Private Helpers
	
	private func getApiKey() -> String? {
		GXModelManager.shared.activeModels.compactMapFirst { gxModel in
			guard gxModel.appModel.isEmbeddedApplication else {	return nil }
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
