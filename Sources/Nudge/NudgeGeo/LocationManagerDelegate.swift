//
//  LocationDelegate.swift
//  FBSnapshotTestCase
//
//  Created by Evan Snyder on 9/20/18.
//

// Needs debugging

#if GEO_ENABLED

import Foundation
import CoreLocation
import UIKit

private let fileName = "LocationManagerDelegate.swift"


class LocationManagerDelegate: NSObject, @preconcurrency CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    private final var MAXIMUM_UNCERTAINTY_FOR_USE = 100.0
    public var locationCallback: (() -> Void)? = nil
    
    private final var desiredAccuracies = [
        kCLLocationAccuracyBestForNavigation,
        kCLLocationAccuracyBest,
        kCLLocationAccuracyKilometer,
        kCLLocationAccuracyThreeKilometers
    ]
    
    // changed to actor for Swift 6
    public actor LocationManagerAccess {
        @MainActor static let SharedManager = LocationManagerDelegate()
    }
    
    var logger = CustomLog()
    
    private override init () {
        super.init()
        self.locationManager.delegate = self

        self.locationManager.desiredAccuracy = desiredAccuracies[KeyValueStore.getInt(key: KeyValueStore.orgDesiredAccuracy)]

        self.locationManager.distanceFilter = KeyValueStore.getDouble(key: KeyValueStore.orgDistanceFilter)
//        logger.infoLocationTracking(message: "TEST: \(self.locationManager.distanceFilter) \(self.locationManager.desiredAccuracy)")
        self.locationManager.allowsBackgroundLocationUpdates = CLLocationManager.authorizationStatus() == .authorizedAlways
        self.locationManager.showsBackgroundLocationIndicator = false
        self.locationManager.pausesLocationUpdatesAutomatically = false
        logger.infoLocationTracking(message: "------- Location Manager Delegate initialized ------------")
    }
    
    @MainActor
    public func startMonitoringLocation() {
        logger.debugLocationTracking(message: "startMonitoringLocation() method called")

        let status = CLLocationManager.authorizationStatus()
        let timesPrompted = KeyValueStore.getInt(key: KeyValueStore.howManyTimesPrompted)

        // Already fully authorized
        if status == .authorizedAlways {
            startUpdating()
            return
        }

        // WhenInUse granted, if flagged from a previous session, request Always upgrade now
        // Otherwise flag it so we request on the next launch (avoids back-to-back prompts)
        if status == .authorizedWhenInUse {
            if KeyValueStore.getBoolean(key: KeyValueStore.needsAlwaysUpgrade) {
                KeyValueStore.putBoolean(key: KeyValueStore.needsAlwaysUpgrade, value: false)
                locationManager.requestAlwaysAuthorization()
            } else {
                KeyValueStore.putBoolean(key: KeyValueStore.needsAlwaysUpgrade, value: true)
            }
            startUpdating()
            return
        }

        // Restricted — nothing we can do
        if status == .restricted {
            logger.errorLocationTracking(message: "Location permissions restricted")
            return
        }

        // notDetermined or denied — show disclosure if conditions met:
        // - First time ever (timesPrompted == 0), OR
        // - Shown once before but not accepted, and 1+ month has passed
        let now = Date().timeIntervalSince1970
        let oneMonth = 2628000.0
        let lastPrompt = KeyValueStore.getDouble(key: KeyValueStore.lastPermissionsPromptTime)
        let timeElapsed = lastPrompt < (now - oneMonth)

        let canShowDisclosure = timesPrompted == 0 || (timesPrompted == 1 && timeElapsed)
        guard canShowDisclosure else { return }

        KeyValueStore.putDouble(key: KeyValueStore.lastPermissionsPromptTime, value: now)
        KeyValueStore.putInt(key: KeyValueStore.howManyTimesPrompted, value: timesPrompted + 1)

        if KeyValueStore.getBoolean(key: KeyValueStore.showLocationDialog) {
            showDisclosureDialog {
                self.locationManager.requestWhenInUseAuthorization()
            }
        } else {
            logger.debugLocationTracking(message: "Requesting Always Location Permission")
            locationManager.requestAlwaysAuthorization()
        }
    }
    
        
        // MARK: - Helpers
        
        private func startUpdating() {
            locationManager.startUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
            logger.infoLocationTracking(message: "------- Start Location Monitoring ------------")
        }
        
        @MainActor
        private func showDisclosureDialog(onOK: @escaping () -> Void) {
            let alert = UIAlertController(
                title: KeyValueStore.getString(key: KeyValueStore.orgLocationDialogTitle),
                message: KeyValueStore.getString(key: KeyValueStore.orgLocationDialogBody),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Next", style: .default) { _ in
                onOK()
            })
            
            
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = scene.windows.first?.rootViewController {
                rootVC.present(alert, animated: true)
            }
        }
    
    @MainActor
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        logger.debugLocationTracking(message: "------- Location Manager didChangeAuthorization ------------")
        switch status {
            case .restricted, .denied:
                self.locationManager.stopMonitoringSignificantLocationChanges()
                self.locationManager.stopUpdatingLocation()
                NudgeGeo.setLocationPermissions(result: "Restricted or Denied")
                NudgeGeo.setKeyValueStoreLocationPermissionDefault();
                if let callable = locationCallback {
                    callable()
                }
                break
                
            case .authorizedAlways:
                locationManager.allowsBackgroundLocationUpdates = true
                startMonitoringLocation()
                NudgeGeo.setLocationPermissions(result: "Always")
                NudgeGeo.setKeyValueStoreLocationPermissionDefault()
                if let callable = locationCallback {
                    callable()
                }
                break

            case .authorizedWhenInUse:
                locationManager.allowsBackgroundLocationUpdates = false
                startMonitoringLocation()
                NudgeGeo.setLocationPermissions(result: "Restricted or Denied")
                NudgeGeo.setKeyValueStoreLocationPermissionDefault()
                if let callable = locationCallback {
                    callable()
                }
                break
                
            case .notDetermined:
                break
            default:
                break
        }
    }
    
    
    public func stopMonitorinLocation(){
        self.locationManager.stopMonitoringSignificantLocationChanges()
        self.locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager,  didUpdateLocations locations: [CLLocation]) {
        logger.debugLocationTracking(message:"------- Location Update ------------")
        guard let lastLocation = locations.last else {
            NSLog("Error with Location Update: no last location found")
            return
        }
        let uncertainty = lastLocation.horizontalAccuracy
        var paramsDict = [String:Any]()
        if (uncertainty < MAXIMUM_UNCERTAINTY_FOR_USE) {
            let lat = lastLocation.coordinate.latitude
            let lng = lastLocation.coordinate.longitude
            KeyValueStore.putDouble(key: KeyValueStore.Location.latitude, value: lat)
            KeyValueStore.putDouble(key: KeyValueStore.Location.longitude, value: lng)
            paramsDict["latitude"] = lat
            paramsDict["longitude"] = lng
            paramsDict["speed"] = lastLocation.speed
            let formatter = DateFormatter()
            formatter.dateFormat = Constants.dateFormat
            paramsDict["date_time"] = formatter.string(from: Date())
            paramsDict["organization_id"] = KeyValueStore.getString(key: KeyValueStore.organizationId)
            paramsDict["device_id"] = KeyValueStore.getString(key: KeyValueStore.deviceId)
            paramsDict["user_id"] = KeyValueStore.getString(key: KeyValueStore.userId)
            paramsDict["device_platform"] = KeyValueStore.devicePlatform
            
            let url = EnvironmentUtils.getNudgeURL(service: EnvironmentUtils.Service.CORE.rawValue) + Constants.Core.Endpoints.actionsByLocationAndDatetime
            let text = "actionsByLocationAndDatetime postData is " + paramsDict.description
            logger.debugLocationTracking(message: text)
            
            let paramsData = Params(paramsData: paramsDict)
            
            HttpClientApi.instance().makeAPICall(url: url, params:paramsData, method: .POST, success: { (data, response, error) in
            }, failure: { (_, response, _) in
                NudgeGeo.logger.infoLocationTracking(message: "actionsByLocationAndDatetime failure \(response?.statusCode)")
            })
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NudgeGeo.logger.errorLocationTracking(message: "locationMananger did fail with error: \(error.localizedDescription)")
        if let error = error as? CLError, error.code == .denied {
            manager.stopUpdatingLocation()
            manager.stopMonitoringSignificantLocationChanges()
            return
        }
    }
    

}

func checkIfLocationServicesEnabled() -> Bool {
    
    if !CLLocationManager.locationServicesEnabled() {
        NudgeGeo.logger.debugLocationTracking(message: "Location Services Disabled")
        return false
    }
    NudgeGeo.logger.debugLocationTracking(message: "Location Services Enabled")
    return true
}

#endif

