import UserNotifications
import CoreLocation
import MessageUI
import os.log

private let fileName = "NudgeGeo.swift"

@objc public class NudgeGeo : NudgeBase {
    var logger = CustomLog()
    
    @objc public init(options: Dictionary<String,Any> = [:], callback: (()->Void)? = nil) {
        super.init()
        
        
        if (options["apiKey"] == nil) {
            return
        }

        // fetch server data for dynamic config
        KeyValueStore.registerObjects(defaults: [
            KeyValueStore.isNudgeEnabled: false,
            KeyValueStore.showLocationDialog: false,
            KeyValueStore.orgDesiredAccuracy: 2,
            KeyValueStore.orgDistanceFilter: 25.0,
            KeyValueStore.lastPermissionsPromptTime: 0.0,
            KeyValueStore.howManyTimesPrompted: 0,
            KeyValueStore.orgLocationDialogTitle: "Allow Location Access",
            KeyValueStore.orgLocationDialogBody: "Please allow location sharing to take full advantage of the following capabilities: \n\n   An important feature of this app is its ability to notify you with announcements whether you are at home or on the go, including important updates on lobby hours (or closings), near-by community events and possible fraud activity near you. \n\n   Your location information won't ever be shared with a third party, or be used for anything other than providing you with timely information, when and where you need it! \n\n   For now grant 'While Using' access, but when prompted later, please switch to 'Always Allow' for full functionality!",
            "location_permission": "Restricted or Denied"
        ])
        
        let apiKey = options["apiKey"] as! String
        let enabled = options["enabled"] != nil ? options["enabled"] as! Bool : false
        let federationId = options["federationId"] != nil ? (options["federationId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines) : ""
        let showLocationDialog = options["showLocationDialog"] != nil ? options["showLocationDialog"] as! Bool : true
        let nudgeVersion = options["nudgeVersion"] != nil ? options["nudgeVersion"] as! Nudge.NudgeVersion : Nudge.NudgeVersion.nudgeGeo
        
        KeyValueStore.putString(key: KeyValueStore.apiKey, value: apiKey)
        KeyValueStore.putBoolean(key: KeyValueStore.isNudgeEnabled, value: enabled)
        KeyValueStore.putString(key: KeyValueStore.nudgeVersion, value: nudgeVersion.rawValue)
        KeyValueStore.putBoolean(key: KeyValueStore.showLocationDialog, value: showLocationDialog)
        
//        self.checkIfEnabled(showLocationDialog: showLocationDialog, enabled: enabled, callback: callback)
        NudgeGeo.checkIfEnabledUpdated(isEnabled: enabled)
        
        let userId = KeyValueStore.getString(key: KeyValueStore.userId)
        let deviceId = KeyValueStore.getString(key: KeyValueStore.deviceId)

        initializeNudge(apiKey: apiKey,
                             federationId: federationId,
                             userId: userId,
                             deviceId: deviceId,
                             success: {(newUserId, newDeviceId) in
                                self.initializeNudgeSuccess(newDeviceId: newDeviceId)},
                             failure: {(message) in
            NSLog("initializeNudge error:" + message)
        })
    }

//    func checkIfEnabled(showLocationDialog: Bool, enabled: Bool, callback: (()->Void)? = nil) -> Void {
//        // start NudgeGeo spcific
//
//        KeyValueStore.putBoolean(key: KeyValueStore.showLocationDialog, value: showLocationDialog)
//        // end NudgeGeo spcific
//        if (!enabled){
//            NudgeGeo.toggleEnabled(enabled: enabled, success: { res in }, failure: { (message) in NSLog(message)})
//            KeyValueStore.putBoolean(key: KeyValueStore.isNudgeEnabled, value: enabled)
//            // start NudgeGeo spcific
//                let locMgr = LocationManagerDelegate.SharedManager
//                if (callback != nil){
//                    locMgr.locationCallback = callback
//                }
//                locMgr.stopMonitorinLocation()
//            // end NudgeGeo spcific
//            NSLog("nudge is disabled")
//            return
//        }
//    }
    
    override func initializeNudgeSuccess(newDeviceId: String, callback: (()->Void)? = nil) -> Void {
        logger.infoNudgeInit(message:"=======================NUDGEGEO=======================")
        //print("=======================NUDGEGEO=======================")
     //   let deviceId = KeyValueStore.getString(key: KeyValueStore.deviceId)
//        NudgeAnalytics.setupAnalytics()
//        NudgeAnalytics.track(eventName: NudgeAnalytics.INTIALIZE_NUDGE, data: [:])
                            
//        KeyValueStore.putBoolean(key: KeyValueStore.isNudgeEnabled, value: true)
                            
    //    let APNtoken = KeyValueStore.getString(key: KeyValueStore.APNtoken)
        let APNtoken = KeyValueStore.getString(key: KeyValueStore.APNtoken)
//        if #available(iOS 12.0, *) {
//            os_log(.debug, "=======================UserDefaults=======================")
//            os_log(.debug,  "%@", UserDefaults.standard.dictionaryRepresentation())
//        }
        if (APNtoken != nil) {
            print("APNtoken is \(String(describing: APNtoken))")
            NudgeGeo.registerToken(deviceId: newDeviceId, token: APNtoken, bundleId: NudgeBase.bundleId, success: {() in
                KeyValueStore.putString(key: KeyValueStore.APNtoken, value: APNtoken)
                let nudgeVersionValue = KeyValueStore.getString(key: KeyValueStore.nudgeVersion)
                let nudgeVersion = Nudge.NudgeVersion(rawValue: nudgeVersionValue ?? "nudgeGeo")
                
                let locationPermissionStatus = KeyValueStore.getString(key: KeyValueStore.locationPermission)
                
                if ((nudgeVersion == NudgeVersionBridge.nudgeLegacy) || locationPermissionStatus == "Always"){
                    self.registerForLocationServices(callback: callback)
                }
//                DispatchQueue.main.async {
//                    // start NudgeGeo spcific
//                        let locMgr = LocationManagerDelegate.SharedManager
//                        if (callback != nil){
//                            locMgr.locationCallback = callback
//                        }
//                        locMgr.startMonitoringLocation()
//                    // end NudgeGeo spcific
//                    NSLog("You've been nudged!")
//                
//                }
            }, failure: {(message) in
                NSLog("registerToken error:" + message)
            })
        }
    }
    
    @objc public class func getLocationPermissionStatus() -> String {
        // Location Manager authoization status locked behind this switch mechanism and
        // has to be collected in this method
        switch CLLocationManager.authorizationStatus() {
                        case .authorizedAlways:
                            return "Always"
                        case .restricted, .denied, .authorizedWhenInUse:
                            return "Restricted or Denied"
                        case .notDetermined:
                            fallthrough
                        default:
                            return "Restricted or Denied"
                    }
    }
    
    @objc public class func setKeyValueStoreLocationPermissionDefault(){
        KeyValueStore.putString(key: KeyValueStore.locationPermission, value: getLocationPermissionStatus())
    }
    
    // decomposed init functions
//    override public func setFederationId(federationId: String){
//        KeyValueStore.putString(key: KeyValueStore.federationId, value: federationId)
//        
//        let apiKey = KeyValueStore.getString(key: KeyValueStore.apiKey) ?? ""
//        let userId = KeyValueStore.getString(key: KeyValueStore.userId)
//        let deviceId = KeyValueStore.getString(key: KeyValueStore.deviceId)
//        
//        if apiKey == "" {
//            return
//        }
//        
//        self.initializeNudge(apiKey: apiKey,
//                             federationId: federationId,
//                             userId: userId,
//                             deviceId: deviceId,
//                             success: {(newUserId, newDeviceId) in
//                                self.initializeNudgeSuccess(newDeviceId: newDeviceId)},
//                             failure: {(message) in
//            NSLog("initializeNudge error:" + message)
//        })
//        
//        // call to new federationId endpoint goes here
//    }
    
    public func registerForLocationServices(callback: (()->Void)? = nil) {
        DispatchQueue.main.async {
            // start NudgeGeo spcific
                let locMgr = LocationManagerDelegate.SharedManager
                if (callback != nil){
                    locMgr.locationCallback = callback
                }
                locMgr.startMonitoringLocation()
            // end NudgeGeo spcific
            NSLog("You've been nudged!")
        
        }
    }
    
    public static func setLocationPermissions(result: String){
        let userId = KeyValueStore.getString(key: KeyValueStore.userId)
        let deviceId = KeyValueStore.getString(key: KeyValueStore.deviceId)
        let orgId = KeyValueStore.getString(key: KeyValueStore.organizationId)
        let notificaitonPermission = KeyValueStore.getString(key: KeyValueStore.notificationPermission)
        
        var paramsDict = [String:Any]()
        
        paramsDict[Constants.Core.PostData.userId] = userId
        paramsDict[Constants.Core.PostData.deviceId] = deviceId
        paramsDict[Constants.Core.PostData.organizationId] = orgId
        paramsDict[Constants.Core.PostData.notificationPermission] = notificaitonPermission
        paramsDict[Constants.Core.PostData.locationPermission] = result
        
        let url = EnvironmentUtils.getNudgeURL(service: EnvironmentUtils.Service.CORE.rawValue) + Constants.Core.Endpoints.setPermissionsParams

        print("setNudgeLocationPermissions postData is " + paramsDict.description)
        
        HttpClientApi.instance().makeAPICall(url: url, params:paramsDict, method: .POST,
                                             success: { (data, response, error) in
            
            print("setNudgeLocationPermissions call successful")
            
        }, failure: { (data, response, error) in
//            NudgeAnalytics.trackError(error: response.debugDescription, file: fileName, function: "setLocationNotificationPermissions")
            
        })
    }
    
}

