//
//  HttpClientApi.swift
//
//  Created by Evan Snyder.
//

import UserNotifications
import CoreLocation
import MessageUI


private let fileName = "NudgeBase.swift"

@objc open class NudgeBase : NSObject {
    public static let bundleId = Bundle.main.bundleIdentifier
    
    public static let deviceModel = getDeviceModel()
    public static let osVersion = getOSInfo()
    public static let platform = "ios"
    
    @objc public init(options: Dictionary<String,Any> = [:]) {
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
            "location_permission": "Not Applicable"

        ])
        
        let apiKey = options["apiKey"] as! String
        let enabled = options["enabled"] != nil ? options["enabled"] as! Bool : false
        let federationId = options["federationId"] != nil ? (options["federationId"] as! String).trimmingCharacters(in: .whitespacesAndNewlines) : ""
        
        let nudgeVersion = options["nudgeVersion"] != nil ? options["nudgeVersion"] as! Nudge.NudgeVersion : Nudge.NudgeVersion.nudgeStandard
        
        KeyValueStore.putString(key: KeyValueStore.apiKey, value: apiKey)
        KeyValueStore.putBoolean(key: KeyValueStore.isNudgeEnabled, value: enabled)
        KeyValueStore.putString(key: KeyValueStore.nudgeVersion, value: nudgeVersion.rawValue)

//        self.checkIfEnabled(enabled: enabled)
        NudgeBase.checkIfEnabledUpdated(isEnabled: enabled)
        
        let userId = KeyValueStore.getString(key: KeyValueStore.userId)
        let deviceId = KeyValueStore.getString(key: KeyValueStore.deviceId)
        
        self.initializeNudge(apiKey: apiKey,
                             federationId: federationId,
                             userId: userId,
                             deviceId: deviceId,
                             success: {(newUserId, newDeviceId) in
                                self.initializeNudgeSuccess(newDeviceId: newDeviceId)},
                             failure: {(message) in
            NSLog("initializeNudge error:" + message)
        })
    }
    
    
    func initializeNudgeSuccess(newDeviceId: String, callback: (()->Void)? = nil) -> Void {
        print("=======================NUDGESTANDARD=======================")
        _ = KeyValueStore.getString(key: KeyValueStore.deviceId)
//        NudgeAnalytics.setupAnalytics()
//        NudgeAnalytics.track(eventName: NudgeAnalytics.INTIALIZE_NUDGE, data: [:])
               
        KeyValueStore.putBoolean(key: KeyValueStore.isNudgeEnabled, value: true)
                            
        let APNtoken = KeyValueStore.getString(key: KeyValueStore.APNtoken)
        if (APNtoken != nil) {
            print("APNtoken is \(String(describing: APNtoken))")
            NudgeBase.registerToken(deviceId: newDeviceId, token: APNtoken, bundleId: NudgeBase.bundleId, success: {() in
                KeyValueStore.putString(key: KeyValueStore.APNtoken, value: APNtoken)
            DispatchQueue.main.async {
    //                        let locMgr = LocationManagerDelegate.SharedManager
    //                        if (callback != nil){
    //                            locMgr.locationCallback = callback
    //                        }
    //                        locMgr.startMonitoringLocation()
                NSLog("You've been nudged!")
            }
            }, failure: {(message) in
                NSLog("registerToken error:" + message)
            })
        }
    }
    
    public static func toggleEnabled(enabled: Bool, success: @escaping (Bool) -> Void,
                             failure: @escaping (String) -> Void) {
        let userId = KeyValueStore.getString(key: KeyValueStore.userId)

        if (userId == nil) {
            NSLog("toggleEnabled: no userId")
            return
        }
        
        NSLog("toggleEnabled:" + userId! + " => " + String(enabled))
        
        let url = Constants.Core.url + Constants.Core.Endpoints.toggleNotifications + "/" + userId!

        var paramsDict = [String:Any]()
        paramsDict[Constants.Core.PostData.toggle] = enabled ? Constants.Core.PostData.enable : Constants.Core.PostData.disable
        
        HttpClientApi.instance().makeAPICall(url: url, params: paramsDict, method: .POST,
                                             success: { (data, response, error) in
            do {
                let responseJson = try JSONSerialization.jsonObject(with: data!) as? NSDictionary
                let res = responseJson![Constants.Core.GetData.notifications] as! String
                print(res)
                success(res == Constants.Core.PostData.enable)
            } catch {
//                NudgeAnalytics.trackError(error: response.debugDescription, file: fileName, function: "setIsEnabled")
                failure("Cannot update user notificationsEnabled")
            }
        }, failure: { (data, response, error) in
//            NudgeAnalytics.trackError(error: response.debugDescription, file: fileName, function: "setIsEnabled")
            failure("Cannot update user notificationsEnabled")
        })
    }
    
    public func isEnabled() -> Bool {
        return KeyValueStore.getBoolean(key: KeyValueStore.isNudgeEnabled)
    }
    
    public class func checkIfEnabledUpdated(isEnabled: Bool) {
        let currentEnabled = KeyValueStore.getBoolean(key: KeyValueStore.isNudgeEnabled)
        print("checkIfEnabledUpdated")
        if (currentEnabled != isEnabled){
            print("checkIfEnabledUpdated setting enabled to " + String(isEnabled))
            NudgeBase.setNudgeEnabled(isNudgeEnabled: isEnabled, success: { res in }, failure: { (message) in NSLog(message)})
        }
    }
    
        public static func getDeviceModel() -> String {
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
            return identifier
    
        }
    
        private static func getOSInfo()->String {
            let os = ProcessInfo().operatingSystemVersion
            return String(os.majorVersion) + "." + String(os.minorVersion) + "." + String(os.patchVersion)
        }
    
    
    public func initializeNudge(apiKey: String, federationId: String, userId: String?,
                                 deviceId: String?, success: @escaping (String, String) -> Void,
                                 failure: @escaping (String) -> Void) {
        NudgeBase.checkNotificationPermissions()
        
        var paramsDict = [String:Any]()
        paramsDict[Constants.Core.PostData.apiKey] = apiKey
        paramsDict[Constants.Core.PostData.federationId] = federationId
        paramsDict[Constants.Core.PostData.userId] = userId
        paramsDict[Constants.Core.PostData.deviceId] = deviceId
        paramsDict[KeyValueStore.notificationPermission] = KeyValueStore.getString(key: KeyValueStore.notificationPermission)
        paramsDict[KeyValueStore.locationPermission] = KeyValueStore.getString(key: KeyValueStore.locationPermission)
        paramsDict[Constants.Core.PostData.timezone] = KeyValueStore.timezoneValue
        paramsDict[Constants.Core.PostData.manufacturer] = KeyValueStore.deviceManufacturer
        paramsDict[Constants.Core.PostData.model] = NudgeBase.deviceModel
        paramsDict[Constants.Core.PostData.devicePlatform] = Constants.Core.PostData.iosPlatform
        paramsDict[Constants.Core.PostData.platformVersion] = KeyValueStore.deviceVersion
        
        print("initializeNudge called!")
        
    //    let url = Constants.Core.url + Constants.Core.Endpoints.initializeNudge
        let url = EnvironmentUtils.getNudgeURL(service: EnvironmentUtils.Service.CORE.rawValue) + Constants.Core.Endpoints.initializeNudge
        print("initialization url is " + url)
        print("initialization postData is " + paramsDict.description)
        
        HttpClientApi.instance().makeAPICall(url: url, params:paramsDict, method: .POST,
                                             success: { (data, response, error) in
            do {
                let responseJson = try JSONSerialization.jsonObject(with: data!) as? NSDictionary
                let userId = responseJson![Constants.Core.GetData.userId] as! String
                let deviceId = responseJson![Constants.Core.GetData.deviceId] as! String
                let organizationId = responseJson![Constants.Core.GetData.organizationId] as! String
                let libraryConfig = responseJson![Constants.Core.GetData.libraryConfig] as! NSArray

                for config in libraryConfig {
                    let elem = config as! NSDictionary
                    if elem["variable"] as! String == Constants.Core.LibraryConfigVariables.desiredAccuracy {
                        KeyValueStore.putString(key: KeyValueStore.orgDesiredAccuracy, value: elem["value"] as? String)
                    }
                    if elem["variable"] as! String == Constants.Core.LibraryConfigVariables.distanceFilter {
                        KeyValueStore.putString(key: KeyValueStore.orgDistanceFilter, value: elem["value"] as? String)
                    }
                    if elem["variable"] as! String == Constants.Core.LibraryConfigVariables.analyticsApiKey {
                        KeyValueStore.putString(key: KeyValueStore.orgAnalyticsApiKey, value: elem["value"] as? String)
                    }
//                    if elem["variable"] as! String == Constants.Core.LibraryConfigVariables.tokenDealerSecret {
//                        KeyValueStore.putString(key: KeyValueStore.orgTokenDealerSecret, value: elem["value"] as? String)
//                    }
                    if elem["variable"] as! String == Constants.Core.LibraryConfigVariables.locationDialogTitle {
                        KeyValueStore.putString(key: KeyValueStore.orgLocationDialogTitle , value: elem["value"] as? String)
                    }
                    if elem["variable"] as! String == Constants.Core.LibraryConfigVariables.locationDialogBody {
                        KeyValueStore.putString(key: KeyValueStore.orgLocationDialogBody, value: elem["value"] as? String)
                    }
                }
                
                KeyValueStore.putString(key: KeyValueStore.userId, value: userId)
                KeyValueStore.putString(key: KeyValueStore.deviceId, value: deviceId)
                KeyValueStore.putString(key: KeyValueStore.organizationId, value: organizationId)
                
                let currentEnabled = KeyValueStore.getBoolean(key: KeyValueStore.isNudgeEnabled)
                
//                NudgeBase.toggleEnabled(enabled: currentEnabled, success: { res in
//                    success(userId, deviceId)
//                }, failure: { (message) in failure(message) })
                NudgeBase.setNudgeEnabled(isNudgeEnabled: currentEnabled,  success: { res in
                    success(userId, deviceId)
                }, failure: { (message) in failure(message) })
                
            } catch {
//                NudgeAnalytics.trackError(error: response.debugDescription, file: fileName, function: "initializeNudge")
                failure("Cannot parse initializeNudge response to JSON")
            }
        }, failure: { (data, response, error) in
//            NudgeAnalytics.trackError(error: response.debugDescription, file: fileName, function: "initializeNudge")
  //          print("makeApiCall error is " + response.debugDescription)
            KeyValueStore.removeObject(key: KeyValueStore.coreServerToken)
            
                failure(String(data: data ?? Data(), encoding: String.Encoding.utf8) ?? "Data Error")
            
        })
    }
    
    public static func registerToken(deviceId: String?, token: String?, bundleId: String?,
                               success: @escaping () -> Void,
                               failure: @escaping (String) -> Void) {
//        NudgeAnalytics.track(eventName: NudgeAnalytics.REGISTER_TOKEN, data: [:])

        var paramsDict = [String:Any]()
        paramsDict[Constants.Core.PostData.deviceId] = deviceId
        paramsDict[Constants.Core.PostData.token] = token
        paramsDict[Constants.Core.PostData.bundleId] = bundleId
        paramsDict[Constants.Core.PostData.platform] = Constants.Core.PostData.iosPlatform
        
        let url = EnvironmentUtils.getNudgeURL(service: EnvironmentUtils.Service.CORE.rawValue) + Constants.Core.Endpoints.registerToken
        print("registerToken url is " + url)
        print("registerToken postData is " + paramsDict.description)
        
        HttpClientApi.instance().makeAPICall(url: url, params:paramsDict, method: .POST,
                                             success: { (data, response, error) in
            success()
        }, failure: { (data, response, error) in
//            NudgeAnalytics.trackError(error: response.debugDescription, file: fileName, function: "registerToken")
            failure(data == nil ? response.debugDescription : String(data: data!, encoding: String.Encoding.utf8)!)
        })
    }


    
    // decomposed init functions
    public class func checkNotificationPermissions(){
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .authorized {
                    KeyValueStore.putString(key: KeyValueStore.notificationPermission, value: "Accept")
                } else {
                    KeyValueStore.putString(key: KeyValueStore.notificationPermission, value: "Decline")
                }
            }
        }
    }
    
    public func setFederationId(federationId: String){
        KeyValueStore.putString(key: KeyValueStore.federationId, value: federationId)
        
        let userId = KeyValueStore.getString(key: KeyValueStore.userId)
        let deviceId = KeyValueStore.getString(key: KeyValueStore.deviceId)
        let organizationId = KeyValueStore.getString(key: KeyValueStore.organizationId)
        

        
        var paramsDict = [String:Any]()
        paramsDict[Constants.Core.PostData.federationId] = federationId
        paramsDict[Constants.Core.PostData.userId] = userId
        paramsDict[Constants.Core.PostData.deviceId] = deviceId
        paramsDict[Constants.Core.PostData.organizationId] = organizationId
        
        let url = EnvironmentUtils.getNudgeURL(service: EnvironmentUtils.Service.CORE.rawValue) + Constants.Core.Endpoints.setFederationId
        print("setFederationId url is " + url)
        print("setFederationId postData is " + paramsDict.description)
        
        HttpClientApi.instance().makeAPICall(url: url, params:paramsDict, method: .POST,
                                             success: { (data, response, error) in
            
            print("setFederationId call successful")
        }, failure: { (data, response, error) in
//            NudgeAnalytics.trackError(error: response.debugDescription, file: fileName, function: "setFederationId")
            
        })
        
        // call to new federationId endpoint goes here
        
        
    }
    
    public class func setNudgeEnabled(isNudgeEnabled: Bool, success: @escaping (Bool) -> Void,
                                 failure: @escaping (String) -> Void){
        KeyValueStore.putBoolean(key: KeyValueStore.isNudgeEnabled, value: isNudgeEnabled)
        
        let userId = KeyValueStore.getString(key: KeyValueStore.userId)
        let deviceId = KeyValueStore.getString(key: KeyValueStore.deviceId)
        let orgId = KeyValueStore.getString(key: KeyValueStore.organizationId)
        
        var paramsDict = [String:Any]()

        paramsDict[Constants.Core.PostData.isEnabled] = isNudgeEnabled
        paramsDict[Constants.Core.PostData.userId] = userId
        paramsDict[Constants.Core.PostData.deviceId] = deviceId
        paramsDict[Constants.Core.PostData.organizationId] = orgId
        
        let url = EnvironmentUtils.getNudgeURL(service: EnvironmentUtils.Service.CORE.rawValue) + Constants.Core.Endpoints.setNudgeEnabled
        print("setNudgeEnabled is " + String(KeyValueStore.getBoolean(key: KeyValueStore.isNudgeEnabled)))
        print("setNudgeEnabled url is " + url)
        print("setNudgeEnabled postData is " + paramsDict.description)
        
        HttpClientApi.instance().makeAPICall(url: url, params:paramsDict, method: .POST,
                                             success: { (data, response, error) in
            
            do {
                let responseJson = try JSONSerialization.jsonObject(with: data!) as? NSDictionary
                let res = responseJson![Constants.Core.GetData.notifications] as! String
                print("setNudgeEnabled call successful: " + res)
                success(res == Constants.Core.PostData.enable)
            } catch {
//                NudgeAnalytics.trackError(error: response.debugDescription, file: fileName, function: "setNudgeEnabled")
                failure("Cannot update user nudgeEnabled")
            }
            
            
        }, failure: { (data, response, error) in
//            NudgeAnalytics.trackError(error: response.debugDescription, file: fileName, function: "setNudgeEnabled")
            
        })
    }
    
    public static func setNotificationPermissions(result: String){
        let userId = KeyValueStore.getString(key: KeyValueStore.userId)
        let deviceId = KeyValueStore.getString(key: KeyValueStore.deviceId)
        let orgId = KeyValueStore.getString(key: KeyValueStore.organizationId)
        
        var paramsDict = [String:Any]()
        
        paramsDict[Constants.Core.PostData.userId] = userId
        paramsDict[Constants.Core.PostData.deviceId] = deviceId
        paramsDict[Constants.Core.PostData.organizationId] = orgId
        paramsDict[Constants.Core.PostData.notificationPermission] = result
        
        let url = EnvironmentUtils.getNudgeURL(service: EnvironmentUtils.Service.CORE.rawValue) + Constants.Core.Endpoints.setPermissionsParams

        print("setNudgePermissions postData is " + paramsDict.description)
        
        HttpClientApi.instance().makeAPICall(url: url, params:paramsDict, method: .POST,
                                             success: { (data, response, error) in
            
            print("setNudgePermissions call successful")
            
        }, failure: { (data, response, error) in
//            NudgeAnalytics.trackError(error: response.debugDescription, file: fileName, function: "setNotificationPermissions")
            
        })
    }
    
    public static func trackMessageEvent(endpointName: String, notificationPayload: [AnyHashable:Any]){
        let userId = KeyValueStore.getString(key: KeyValueStore.userId)
        let deviceId = KeyValueStore.getString(key: KeyValueStore.deviceId)
        let orgId = KeyValueStore.getString(key: KeyValueStore.organizationId)
        
        let messageConstants = KeyValueStore.MessageData.self
        let messageId = notificationPayload[messageConstants.messageId] as Any;
        let messageBreadcrumbs = notificationPayload[messageConstants.messageBreadcrumbs] as Any;
        NSLog("MessageBreadcrumbs are: \(messageConstants.messageBreadcrumbs)")
        
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.dateFormat
        let timestamp = formatter.string(from: Date())
        
        var paramsDict = [String:Any]()
        
        paramsDict[Constants.Core.PostData.userId] = userId
        paramsDict[Constants.Core.PostData.deviceId] = deviceId
        paramsDict[Constants.Core.PostData.organizationId] = orgId
        paramsDict[Constants.Core.PostData.messageId] = messageId
        paramsDict[Constants.Core.PostData.breadcrumbs] = messageBreadcrumbs
        paramsDict[Constants.Core.PostData.timestamp] = timestamp
        
        let url = EnvironmentUtils.getNudgeURL(service: EnvironmentUtils.Service.CORE.rawValue) + endpointName

        print("trackMessageData postData is " + paramsDict.description)
        
        HttpClientApi.instance().makeAPICall(url: url, params:paramsDict, method: .POST,
                                             success: { (data, response, error) in
            
            print("trackMessageData call successful")
            
        }, failure: { (data, response, error) in
//            NudgeAnalytics.trackError(error: response.debugDescription, file: fileName, function: "trackMessageData")
            
        })
    }
    
    
}
