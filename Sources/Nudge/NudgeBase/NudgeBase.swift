//
//  HttpClientApi.swift
//
//  Created by Evan Snyder.
//

import UserNotifications
import CoreLocation
import MessageUI


private let fileName = "NudgeBase.swift"

@objc(NudgeBase)
open class NudgeBase : NSObject, @unchecked Sendable {
    public static let bundleId = Bundle.main.bundleIdentifier
    
    public static let deviceModel = getDeviceModel()
    public static let osVersion = getOSInfo()
    public static let platform = "ios"
    public static let logger = CustomLog()
    
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
        
        getDeviceLanguage()

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
    
    
    func initializeNudgeSuccess(newDeviceId: String, callback: (@Sendable ()->Void)? = nil) -> Void {
        NudgeBase.logger.infoNudgeInit(message: "=======================NUDGESTANDARD=======================")
        _ = KeyValueStore.getString(key: KeyValueStore.deviceId)
               
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

        guard let userId = userId else {
            NSLog("toggleEnabled: no userId")
            return
        }
        
        NSLog("toggleEnabled:" + userId + " => " + String(enabled))
        
        let url = Constants.Core.url + Constants.Core.Endpoints.toggleNotifications + "/" + userId

        var paramsDict = [String:Any]()
        paramsDict[Constants.Core.PostData.toggle] = enabled ? Constants.Core.PostData.enable : Constants.Core.PostData.disable
        
        let postDataParams = Params(paramsData: paramsDict)
        
        HttpClientApi.instance().makeAPICall(url: url, params: postDataParams, method: .POST,
                                             success: { (data, response, error) in
            do {
                guard
                    let data = data,
                    let responseJson = try JSONSerialization.jsonObject(with: data) as? NSDictionary,
                    let res = responseJson[Constants.Core.GetData.notifications] as? String
                else {
                    NudgeBase.logger.errorNudgePermissions(message: "Nudge setEnabled parse error")
                    return
                }
                print(res)
                NudgeBase.logger.infoNudgePermissions(message: "Nudge setEnabled successful: \(res)")
            } catch {
                NudgeBase.logger.errorNudgePermissions(message: "Nudge setEnabled failed: \(response?.statusCode)")
            }
        }, failure: { (data, response, error) in
            NudgeBase.logger.errorNudgePermissions(message: "Nudge setEnabled failed: \(response?.statusCode)")
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
        let identifier = machineMirror.children.reduce(into: "") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            return identifier.append(Character(UnicodeScalar(UInt8(value))))
        }
        return identifier

    }
    
    private static func getOSInfo()->String {
        let os = ProcessInfo().operatingSystemVersion
        return String(os.majorVersion) + "." + String(os.minorVersion) + "." + String(os.patchVersion)
    }
    
    func getDeviceLanguage(){
        
        if let languageCode = Locale.preferredLanguages.first {
            let codeOnly = Locale(identifier: languageCode).languageCode
            print("LanguageCode: \(codeOnly ?? "Unknown")")
            
            if (codeOnly != nil) {
                KeyValueStore.putString(key: KeyValueStore.preferredLanguage, value: codeOnly)
            }
        }
        
        
    }
    
    
    public func initializeNudge(apiKey: String, federationId: String, userId: String?,
                                 deviceId: String?, success: @escaping @Sendable (String, String) -> Void,
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
        paramsDict[Constants.Core.PostData.preferredLanguage] = KeyValueStore.getString(key: KeyValueStore.preferredLanguage)
        
        print("initializeNudge called!")
        
        let url = EnvironmentUtils.getNudgeURL(service: EnvironmentUtils.Service.CORE.rawValue) + Constants.Core.Endpoints.initializeNudge
        print("initialization url is " + url)
        print("initialization postData is " + paramsDict.description)
        
        let postDataParams = Params(paramsData: paramsDict)
        
        HttpClientApi.instance().makeAPICall(url: url, params:postDataParams, method: .POST,
                                             success: { (data, response, error) in
            do {
                guard
                    let data = data,
                    let responseJson = try JSONSerialization.jsonObject(with: data) as? NSDictionary
                else {
                    NudgeBase.logger.errorNudgeInit(message: "Nudge initializeNudge parse failed: \(response?.statusCode)")
                    return
                }
                guard
                    let userId = responseJson[Constants.Core.GetData.userId] as? String,
                    let deviceId = responseJson[Constants.Core.GetData.deviceId] as? String,
                    let organizationId = responseJson[Constants.Core.GetData.organizationId] as? String,
                    let libraryConfig = responseJson[Constants.Core.GetData.libraryConfig] as? [[String: Any]]
                else {
                    NudgeBase.logger.errorNudgeInit(message: "Nudge initializeNudge missing fields: \(response?.statusCode)")
                    return
                }
                
                for elem in libraryConfig {
                    guard let variable = elem["variable"] as? String else { continue }

                    switch variable {
                    case Constants.Core.LibraryConfigVariables.desiredAccuracy:
                        KeyValueStore.putString(key: KeyValueStore.orgDesiredAccuracy,
                                                value: elem["value"] as? String)

                    case Constants.Core.LibraryConfigVariables.distanceFilter:
                        KeyValueStore.putString(key: KeyValueStore.orgDistanceFilter,
                                                value: elem["value"] as? String)

                    case Constants.Core.LibraryConfigVariables.analyticsApiKey:
                        KeyValueStore.putString(key: KeyValueStore.orgAnalyticsApiKey,
                                                value: elem["value"] as? String)

                    case Constants.Core.LibraryConfigVariables.locationDialogTitle:
                        KeyValueStore.putString(key: KeyValueStore.orgLocationDialogTitle,
                                                value: elem["value"] as? String)

                    case Constants.Core.LibraryConfigVariables.locationDialogBody:
                        KeyValueStore.putString(key: KeyValueStore.orgLocationDialogBody,
                                                value: elem["value"] as? String)

                    default:
                        break
                    }
                }
                        
                
                KeyValueStore.putString(key: KeyValueStore.userId, value: userId)
                KeyValueStore.putString(key: KeyValueStore.deviceId, value: deviceId)
                KeyValueStore.putString(key: KeyValueStore.organizationId, value: organizationId)
                
                let currentEnabled = KeyValueStore.getBoolean(key: KeyValueStore.isNudgeEnabled)
                
                print("=================")
                NudgeBase.setNudgeEnabled(isNudgeEnabled: currentEnabled,  success: { res in
                    print("calling success")
                    success(userId, deviceId)
                    NudgeBase.logger.infoNudgeInit(message: "Nudge init setEnabled successful: \(res)")
                }, failure: { (message) in
                        NudgeBase.logger.errorNudgePermissions(message: "Nudge init setEnabled failed: \(message)")
                    })
                
//                success(deviceId, userId)
                
            } catch {

                NudgeBase.logger.errorNudgePermissions(message: "Cannot parse initializeNudge response to JSON")
            }
        }, failure: { (_, response, _) in

            KeyValueStore.removeObject(key: KeyValueStore.coreServerToken)
            NudgeBase.logger.errorNudgePermissions(message: "Cannot parse initializeNudge response to JSON")
            
        })
    }
    
    public static func registerToken(deviceId: String?, token: String?, bundleId: String?,
                               success: @Sendable @escaping () -> Void,
                               failure: @escaping (String) -> Void) {

        var paramsDict = [String:Any]()
        paramsDict[Constants.Core.PostData.deviceId] = deviceId
        paramsDict[Constants.Core.PostData.token] = token
        paramsDict[Constants.Core.PostData.bundleId] = bundleId
        paramsDict[Constants.Core.PostData.platform] = Constants.Core.PostData.iosPlatform
        
        let url = EnvironmentUtils.getNudgeURL(service: EnvironmentUtils.Service.CORE.rawValue) + Constants.Core.Endpoints.registerToken
        print("registerToken url is " + url)
        print("registerToken postData is " + paramsDict.description)
        
        let postDataParams = Params(paramsData: paramsDict)
        
        HttpClientApi.instance().makeAPICall(url: url, params:postDataParams, method: .POST,
                                             success: { (_, response, _) in
            success()
            logger.infoNudgeInit(message: "Nudge registerToken: \(response?.statusCode)")
        }, failure: { (_, response, error) in
            logger.errorNudgeInit(message: "Nudge registerToken Error: \(response?.statusCode)")
            logger.debugNudgeInit(message: "Nudge registerToken Error Description: \(error?.localizedDescription)")
        })
    }


    
    // decomposed init functions
    public class func checkNotificationPermissions(){
        
        UNUserNotificationCenter.current().getNotificationSettings { notificationSettings in
                let isAuthorized = (notificationSettings.authorizationStatus == .authorized)

                DispatchQueue.main.async {
                    KeyValueStore.putString(
                        key: KeyValueStore.notificationPermission,
                        value: isAuthorized ? "Accept" : "Decline"
                    )
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
        
        let postDataParams = Params(paramsData: paramsDict)
        
        HttpClientApi.instance().makeAPICall(url: url, params:postDataParams, method: .POST,
                                             success: { (data, response, error) in
            
            NudgeBase.logger.infoNudgeInit(message: "Nudge setFederationId successful: \(response?.statusCode)")
            
            print("setFederationId call successful")
        }, failure: { (_, response, error) in
            NudgeBase.logger.errorNudgeInit(message: "Nudge setFederationId Error: \(response?.statusCode)")
            NudgeBase.logger.debugNudgeInit(message: "Nudge setFederationId Description: \(error.debugDescription)")
            
        })
        
        // call to new federationId endpoint goes here
        
        
    }
    
    public class func setNudgeEnabled(isNudgeEnabled: Bool, success: @escaping @Sendable (Bool) -> Void,
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
        
        let postDataParams = Params(paramsData: paramsDict)
        
        HttpClientApi.instance().makeAPICall(url: url, params:postDataParams, method: .POST,
                                             success: { (data, response, error) in
            
            do {
                if let data = data,
                let responseJson = try JSONSerialization.jsonObject(with: data) as? NSDictionary,
                   let res = responseJson[Constants.Core.GetData.notifications] as? String {
                    print("setNudgeEnabled call successful: " + res)
                    NudgeBase.logger.infoNudgePermissions(message: "Nudge setEnabled successful: \(response?.statusCode)")
                    success(res == Constants.Core.PostData.enable)
                } else {
                    NudgeBase.logger.errorNudgePermissions(message: "Nudge setEnabled Parse Error: \(response?.statusCode)")
                }
            } catch {
                NudgeBase.logger.errorNudgePermissions(message: "Nudge setEnabled Catch Error: \(response?.statusCode)")
                
            }
            
            
        }, failure: { (_, response, _) in
            NudgeBase.logger.errorNudgePermissions(message: "Nudge setEnabled Failure Error: \(response?.statusCode)")
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
        
        let postDataParams = Params(paramsData: paramsDict)
        
        HttpClientApi.instance().makeAPICall(url: url, params:postDataParams, method: .POST,
                                             success: { (data, response, error) in
            
            print("setNudgePermissions call successful")
            NudgeBase.logger.infoNudgePermissions(message: "Nudge setNotificationPermissions successful: \(response?.statusCode)")
            
        }, failure: { (data, response, error) in
            NudgeBase.logger.errorNudgePermissions(message: "Nudge setNotificationPermissions Error: \(response?.statusCode)")
            
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
        
        let postDataParams = Params(paramsData: paramsDict)
        
        HttpClientApi.instance().makeAPICall(url: url, params:postDataParams, method: .POST,
                                             success: { (data, response, error) in
            
            print("trackMessageData call successful")
            
        }, failure: { (data, response, error) in
            NudgeBase.logger.errorNudgeMessaging(message: "trackMessageData failure \(response?.statusCode)")
            
        })
    }
    
    
}
