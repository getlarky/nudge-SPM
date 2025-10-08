//
//  Nudge.swift
//  nudge
//
//  Created by Connor Southwell on 10/17/24.
//

import Foundation
import os.log
import UserNotifications
import UIKit

private let fileName = "Nudge.swift"

@objc open class Nudge : NSObject {
    var myNudge: NudgeBase?
    var logger = CustomLog()
    var myNudgeVersion: Nudge.NudgeVersion = Nudge.NudgeVersion.nudgeLegacy
    
    public enum NudgeVersion: String, Sendable {
        case nudgeStandard = "nudgeStandard"
        case nudgeGeo = "nudgeGeo"
        case nudgeLegacy = "nudgeLegacy"
    }
    
    public static func fromNumeric(_ version: Int) -> NudgeVersion {
        switch version {
        case 0: return Nudge.NudgeVersion.nudgeStandard
        case 1:      return Nudge.NudgeVersion.nudgeGeo
        case 2:   return Nudge.NudgeVersion.nudgeLegacy
        default:
            return Nudge.NudgeVersion.nudgeGeo
        }
    }
    
    public enum NudgeErrors : Error {
        case unsupportediOSVersion
    }
    
    // shared functions
    @objc public init(options: Dictionary<String,Any> = [:]) {
        if options[Constants.Options.nudgeVersion] != nil {
            let userId = KeyValueStore.getString(key: KeyValueStore.userId)
            var currentEnabled = KeyValueStore.getBoolean(key: KeyValueStore.isNudgeEnabled)
            var nudgeVersion = options[Constants.Options.nudgeVersion]
            
            if (userId == nil){
                print("current user Id is none")
                currentEnabled = true
                KeyValueStore.putBoolean(key: KeyValueStore.isNudgeEnabled, value: true)
            }
            
            print("nudgeVersion Type: \(type(of: nudgeVersion)), Value: \(String(describing: nudgeVersion))")
            if let versionParam  = options[Constants.Options.nudgeVersion] as? Int {
                let swiftEnum = Nudge.fromNumeric(versionParam)
                nudgeVersion = swiftEnum
            }
            
            if ((nudgeVersion as? Nudge.NudgeVersion) == nil){
                return
            }
            
            
            if (nudgeVersion as! Nudge.NudgeVersion == Nudge.NudgeVersion.nudgeGeo){
                logger.debug(message: "nudgeGeo selected")
                
                self.myNudgeVersion = Nudge.NudgeVersion.nudgeGeo
                
                
                var parameters: [String:Any] = [
                    "apiKey": options[Constants.Options.apiKey] as! String,
                    "enabled": currentEnabled,
                    "showLocationDialog": options[Constants.Options.showLocationDialog] ?? true,
                    "nudgeVersion": self.myNudgeVersion
                    
                ]
                
                if options[Constants.Options.federationId] != nil {
                    parameters[Constants.Options.federationId] = options[Constants.Options.federationId]
                }
                
                myNudge = NudgeGeo(options: parameters)
            }
            else if (nudgeVersion as! Nudge.NudgeVersion == Nudge.NudgeVersion.nudgeStandard){
                logger.debug(message: "nudgeStandard selected")

                self.myNudgeVersion = Nudge.NudgeVersion.nudgeStandard
                var parameters: [String:Any] = [
                    "apiKey": options[Constants.Options.apiKey] as! String,
                    "enabled": currentEnabled,
                    "nudgeVersion": self.myNudgeVersion
                    
                ]
                
                if options[Constants.Options.federationId] != nil {
                    parameters[Constants.Options.federationId] = options[Constants.Options.federationId]
                }
                
                myNudge = NudgeBase(options: parameters)
            }
            else {
                logger.debug(message: "Valid nudge version is not specified")
            }
        } else {
            logger.debug(message: "nudge Legacy integration selected")
            self.myNudgeVersion = Nudge.NudgeVersion.nudgeLegacy
            var parameters: [String:Any] = [
                "apiKey": options[Constants.Options.apiKey] as! String,
                "enabled": options[Constants.Options.enabled] as? Bool ?? false,
                "showLocationDialog": options[Constants.Options.showLocationDialog] ?? true,
                "nudgeVersion": self.myNudgeVersion
                
            ]
            
            if options[Constants.Options.federationId] != nil {
                parameters[Constants.Options.federationId] = options[Constants.Options.federationId]
            }
            
            myNudge = NudgeGeo(options: parameters)
        }
    }
    
    @objc public func IsEnabled() -> Bool {
        if (myNudge != nil){
            return myNudge?.isEnabled() ?? false
        }
        else {
            return false
        }
    }
    
    // decomposed init functions
    @objc public func setFederationId(federationId: String){
        let formatedFederationId = federationId.trimmingCharacters(in: .whitespacesAndNewlines)
        if (myNudge != nil){
            if (myNudgeVersion == Nudge.NudgeVersion.nudgeStandard){
                myNudge?.setFederationId(federationId: formatedFederationId)
            } else if (myNudgeVersion == Nudge.NudgeVersion.nudgeGeo){
                myNudge?.setFederationId(federationId: formatedFederationId)
            } else {
                logger.debug(message: "nudge version is not specified")
            }
        } else {
            logger.debug(message: "nudge is not yet initialized")
        }
        
    }
    
    @objc public func registerForLocationServices(showLocationDialog: Bool) {
        
        if (myNudgeVersion == Nudge.NudgeVersion.nudgeGeo && (KeyValueStore.getString(key: KeyValueStore.notificationPermission) == "Accept")){
            if let myNudgeGeo = myNudge as? NudgeGeo {
                KeyValueStore.putBoolean(key: KeyValueStore.showLocationDialog, value: showLocationDialog)
                myNudgeGeo.registerForLocationServices()
            }
        } else {
            logger.debug(message: "This feature is only available in the Geo version of nudge")
        }
    }
    
    @objc public func setNudgeEnabled(isNudgeEnabled: Bool){
        if (myNudge != nil){
            NudgeBase.setNudgeEnabled(isNudgeEnabled: isNudgeEnabled, success: { res in }, failure: { (message) in NSLog(message)})
        }
    }
    
    
    // managing notifications logic
    
    @objc public static func registerForPushNotifications() throws{
//        NudgeAnalytics.setupAnalytics()
        print("------------registerForPushNotifications------------")
        if #available(iOS 10.0, *) {
            print("------------registerForPushNotifications #available(iOS 10.0, *) ------------")
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
                (granted, error) in
                print("------------ in UNUserNotificationCenter.current().requestAuthorization ------------")
                if (granted){
                    NudgeBase.setNotificationPermissions(result: "Accept")
//                    NudgeAnalytics.track(eventName: NudgeAnalytics.NOTIFICATION_PERMISSION, data: ["notification_permission" : "Accept"])
                    KeyValueStore.putString(key: KeyValueStore.notificationPermission, value: "Accept")
                    print("------------Accepted Notification Permissions------------")
                    print("------------Now registerForRemoteNotification ------------")
                }
                else{
                    NudgeBase.setNotificationPermissions(result: "Decline")
//                    NudgeAnalytics.track(eventName: NudgeAnalytics.NOTIFICATION_PERMISSION, data: ["notification_permission" : "Decline"])
                    KeyValueStore.putString(key: KeyValueStore.notificationPermission, value: "Decline")
                    print("------------Decined Notification Permissions------------")
                }
                guard granted else { return }
                self.getNotificationSettings()
            }
        } else {
//            NudgeAnalytics.trackError(error: "Unsupported version of iOS", file: fileName, function: "registerForPushNotifications")
            throw Nudge.NudgeErrors.unsupportediOSVersion
        }
    }
    
    @objc public static func onRegisteredForNotifications(deviceToken: Data) {
//        NudgeAnalytics.setupAnalytics()
        let tokenParts = deviceToken.map { data -> String in
            // Convert from Data to base-16 encoded hex string. More info here: https://stackoverflow.com/a/40031342
            // and here: https://www.raywenderlich.com/156966/push-notifications-tutorial-getting-started
            return String(format: "%02.2hhx", data)
        }
        let token = tokenParts.joined()
        KeyValueStore.putString(key: KeyValueStore.APNtoken, value: token)
        print("---------- onRegisteredForNotifications(deviceToken: " + token + " --------------")
    }
    
    @objc public static func onFailedToRegisterForNotifications(error: Error){
//        NudgeAnalytics.setupAnalytics()
        print("Failed to register: \(error)")
    }
    
    @objc public static func receivedPush(notificationPayload: [AnyHashable:Any], application: UIApplication) {
        NSLog("receivedPush called");
        NudgeBase.trackMessageEvent(endpointName: Constants.Core.Endpoints.nudgeReceived, notificationPayload: notificationPayload)
    }
    
    @MainActor @available(iOS 10.0, *)
    @objc public static func tappedNotification(notification: UNNotification) {
        NudgeBase.trackMessageEvent(endpointName: Constants.Core.Endpoints.nudgeTapped, notificationPayload: notification.request.content.userInfo)
        let isDeepLink = notification.request.content.userInfo[KeyValueStore.MessageData.isDeepLink] as? Bool ?? false
        if let url = (notification.request.content.userInfo[KeyValueStore.MessageData.messageUrl] as? String), !isDeepLink {
            redirectToUrl(messageUrl: url)
            NSLog("nudge tapped - redirecting to url")
        }
        else {
            NSLog("nudge tapped")
        }
    }
    
    @MainActor
    private static func redirectToUrl(messageUrl: String) {
        guard let url = URL(string: messageUrl) else {
            return
        }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
        
    }
    
    private static func getNotificationSettings(){
        // This #available check has to be included, but the only place this is called is within registerForPushNotifications, which already has the if#available block
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                
                guard settings.authorizationStatus == .authorized else { return }
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    

    
    
    
    
    
}

@objc public class NudgeVersionBridge: NSObject {
    public static let nudgeBase = Nudge.NudgeVersion.nudgeStandard
    public static let nudgeGeo = Nudge.NudgeVersion.nudgeGeo
    public static let nudgeLegacy = Nudge.NudgeVersion.nudgeLegacy
}
