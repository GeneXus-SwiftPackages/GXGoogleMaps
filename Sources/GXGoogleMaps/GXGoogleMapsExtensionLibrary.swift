//
//  GXMapsProvider_GoogleMapsExtensionLibrary.swift
//

import GXCoreBL

@objc(GXGoogleMapsExtensionLibrary)
open class GXGoogleMapsExtensionLibrary: NSObject, GXExtensionLibraryProtocol {
    
    open func initializeExtensionLibrary(withContext context: GXExtensionLibraryContext) {
        let googleMapsProvider = GXGoogleMapsMapsProvider()
        GXMapsProvidersManager.register(googleMapsProvider, forIdentifier: googleMapsProvider.mapsApiIdentifier)
    }
}

