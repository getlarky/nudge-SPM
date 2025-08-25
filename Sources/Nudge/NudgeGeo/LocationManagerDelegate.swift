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
            
            guard CLLocationManager.locationServicesEnabled() else {
                return
            }
            startUpdating()
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
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
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
//                NudgeAnalytics.track(eventName: NudgeAnalytics.LOCATION_PERMISSION, data: ["location_permission" : "Restricted or Denied"])
                NudgeGeo.setLocationPermissions(result: "Restricted or Denied")
                NudgeGeo.setKeyValueStoreLocationPermissionDefault();
                if let callable = locationCallback {
                    callable()
                }
                break
                
            case .authorizedAlways, .authorizedWhenInUse:
                startMonitoringLocation()
//                NudgeAnalytics.track(eventName: NudgeAnalytics.LOCATION_PERMISSION, data: ["location_permission" : "Always"])
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
    
//    public func startMonitoringLocation() async {
//        logger.debugLocationTracking(message: "startMonitoringLocation() method called")
////        let delegate = self
//        let authorizationStatus = CLLocationManager.authorizationStatus()
//        if (authorizationStatus == .restricted || authorizationStatus == .denied) {
////            NudgeAnalytics.trackError(error: "Location permissions restricted, not monitoring location", file: fileName, function: "startMonitoringLocation")
//            logger.errorLocationTracking(message: "! Location permissions restricted, not monitoring location")
//            if (KeyValueStore.getInt(key: KeyValueStore.howManyTimesPrompted) == 3){
//                return
//            }
//        }
//        let timesPrompted = KeyValueStore.getInt(key: KeyValueStore.howManyTimesPrompted)
//        if ((authorizationStatus != .authorizedWhenInUse && authorizationStatus != .authorizedAlways) || (timesPrompted == 0)) {
//            let time = NSDate().timeIntervalSince1970
//            let secondsSinceLastPrompted = 2628000.0
//            
//            
//            let lastPromptTime = KeyValueStore.getDouble(key: KeyValueStore.lastPermissionsPromptTime)
//            if ((lastPromptTime < (time + secondsSinceLastPrompted)) && (timesPrompted < 3)){
//                KeyValueStore.putDouble(key: KeyValueStore.lastPermissionsPromptTime, value: time)
//                if (KeyValueStore.getBoolean(key: KeyValueStore.showLocationDialog) == true){
//                    
//                    if (authorizationStatus != .denied || (authorizationStatus == .authorizedAlways) && (timesPrompted == 0)){
//                        
//                        KeyValueStore.putInt(key: KeyValueStore.howManyTimesPrompted, value: (timesPrompted + 1))
//                        await MainActor.run {
//                            let alertController = UIAlertController(
//                                title: KeyValueStore.getString(key: KeyValueStore.orgLocationDialogTitle),
//                                message: KeyValueStore.getString(key: KeyValueStore.orgLocationDialogBody),
//                                preferredStyle: .alert
//                            )
//                            
//                            let actionOK = UIAlertAction(title: "OK", style: .default) { _ in
//                                Task {
////                                        await MainActor.run {
////                                    @MainActor in
////                                            (UIApplication.shared.delegate as? LocationManagerDelegate)?
////                                                .locationManager
////                                                .requestWhenInUseAuthorization()
////                                        }
////                                    await LocationManagerAccess.requestAuthorization()
////                                    await self.requestAuthorization()
//                                    
//                                    }
//                            }
//                            
//                            
//                            alertController.addAction(actionOK)
////                            logger.debugLocationTracking(message: "Present Prominent Disclosure Dialog")
//                            alertController.present(animated: true, completion: nil)
//                            return
//                            
//                        }
//                        
//                    }
//                } else {
//                    logger.debugLocationTracking(message: "Requesting Allow Always Location Permission")
//                    self.locationManager.requestAlwaysAuthorization()
//                    return
//                }
//            }
//        }
//        if (!checkIfLocationServicesEnabled()){
//            return
//        }
//        locationManager.startUpdatingLocation()
//        locationManager.startMonitoringSignificantLocationChanges()
//        logger.infoLocationTracking(message:"------- Start Location Monitoring ------------")
//    }
    
    public func stopMonitorinLocation(){
        self.locationManager.stopMonitoringSignificantLocationChanges()
        self.locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager,  didUpdateLocations locations: [CLLocation]) {
        logger.debugLocationTracking(message:"------- Location Update ------------")
        let lastLocation = locations.last!
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
            
          //  let url = Constants.Core.url + Constants.Core.Endpoints.actionsByLocationAndDatetime
            let url = EnvironmentUtils.getNudgeURL(service: EnvironmentUtils.Service.CORE.rawValue) + Constants.Core.Endpoints.actionsByLocationAndDatetime
           // print("actionsByLocationAndDatetime url is " + url)
            let text = "actionsByLocationAndDatetime postData is " + paramsDict.description
            logger.debugLocationTracking(message: text)
            //print("actionsByLocationAndDatetime postData is " + paramsDict.description)
            
            let paramsData = Params(paramsData: paramsDict)
            
            HttpClientApi.instance().makeAPICall(url: url, params:paramsData, method: .POST, success: { (data, response, error) in
            }, failure: { (data, response, error) in
//                NudgeAnalytics.trackError(error: response.debugDescription, file: fileName, function: "locationManager.didUpdateLocations")
            })
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        NudgeAnalytics.trackError(error: error.localizedDescription, file: fileName, function: "locationManager.didFailWithError")
        if let error = error as? CLError, error.code == .denied {
            manager.stopUpdatingLocation()
            manager.stopMonitoringSignificantLocationChanges()
            return
        }
    }
    

}

func checkIfLocationServicesEnabled() -> Bool {
    if !CLLocationManager.locationServicesEnabled() {
//        NudgeAnalytics.trackError(error: "Location services not enabled/available, not monitoring location", file: fileName, function: "startMonitoringLocation")
        return false
    }
    return true
}

