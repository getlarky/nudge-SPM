//
//  LocationDelegate.swift
//  FBSnapshotTestCase
//
//  Created by Evan Snyder on 9/20/18.
//

// Needs debugging

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
        if #available(iOS 9.0, *) {
            self.locationManager.allowsBackgroundLocationUpdates = true
        } else {
//            NudgeAnalytics.trackError(error: "iOS version less than 9.0, not supporting location monitoring.", file: fileName, function: "init")
        }
        self.locationManager.pausesLocationUpdatesAutomatically = false
        logger.infoLocationTracking(message: "------- Location Manager Delegate initialized ------------")
    }
    
    @MainActor
    public func startMonitoringLocation() {
            logger.debugLocationTracking(message: "startMonitoringLocation() method called")
            
            let status = CLLocationManager.authorizationStatus()
            
            // Handle denied/restricted
            if status == .restricted || status == .denied {
                logger.errorLocationTracking(message: "! Location permissions restricted, not monitoring location")
                if KeyValueStore.getInt(key: KeyValueStore.howManyTimesPrompted) >= 3 {
                    return
                }
            }
            
            let timesPrompted = KeyValueStore.getInt(key: KeyValueStore.howManyTimesPrompted)
            
            // First prompt logic (or not yet fully authorized)
            if (status != .authorizedWhenInUse && status != .authorizedAlways) || timesPrompted == 0 {
                let now = Date().timeIntervalSince1970
                let interval = 2628000.0  // ~1 month
                let lastPrompt = KeyValueStore.getDouble(key: KeyValueStore.lastPermissionsPromptTime)
                
                if (lastPrompt < (now - interval)) && timesPrompted < 3 {
                    KeyValueStore.putDouble(key: KeyValueStore.lastPermissionsPromptTime, value: now)
                    
                    if KeyValueStore.getBoolean(key: KeyValueStore.showLocationDialog) {
                        
                        // show your disclosure UI
                        showDisclosureDialog {
                            KeyValueStore.putInt(key: KeyValueStore.howManyTimesPrompted, value: timesPrompted + 1)
                            
                            switch status {
                            case .notDetermined:
                                self.locationManager.requestWhenInUseAuthorization()
                            case .authorizedWhenInUse:
                                self.locationManager.requestAlwaysAuthorization()
                            default:
                                break
                            }
                        }
                        return
                    } else {
                        // direct request without disclosure
                        logger.debugLocationTracking(message: "Requesting Allow Always Location Permission")
                        locationManager.requestAlwaysAuthorization()
                        return
                    }
                }
            }
            
//            guard CLLocationManager.locationServicesEnabled() else {
//                return
//            }
        
        switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse:
                startUpdating()
                break
            case .restricted, .denied, .notDetermined:
                break
            @unknown default:
                break
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
                
            case .authorizedAlways, .authorizedWhenInUse:
                startMonitoringLocation()
                NudgeGeo.setLocationPermissions(result: "Always")
                NudgeGeo.setKeyValueStoreLocationPermissionDefault();
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

