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

@objc(Nudge) open class NudgeSDK : NSObject {
    var myNudge: NudgeBase?
    var logger = CustomLog()
    var myNudgeVersion: NudgeSDK.NudgeVersion = NudgeSDK.NudgeVersion.nudgeLegacy
    
    public enum NudgeVersion: String, Sendable {
        case nudgeStandard = "nudgeStandard"
        case nudgeGeo = "nudgeGeo"
        case nudgeLegacy = "nudgeLegacy"
    }
    
    public static func fromNumeric(_ version: Int) -> NudgeVersion {
        switch version {
        case 0: return NudgeSDK.NudgeVersion.nudgeStandard
        case 1:      return NudgeSDK.NudgeVersion.nudgeGeo
        case 2:   return NudgeSDK.NudgeVersion.nudgeLegacy
        default:
            return NudgeSDK.NudgeVersion.nudgeGeo
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
            
            if ((nudgeVersion as? NudgeSDK.NudgeVersion) == nil){
                return
            }
            
            
            if (nudgeVersion as! NudgeSDK.NudgeVersion == NudgeSDK.NudgeVersion.nudgeGeo){
                logger.debug(message: "nudgeGeo selected")
                
                self.myNudgeVersion = NudgeSDK.NudgeVersion.nudgeGeo
                
                
                var parameters: [String:Any] = [
                    "apiKey": options[Constants.Options.apiKey] as! String,
                    "enabled": currentEnabled,
                    "showLocationDialog": options[Constants.Options.showLocationDialog] ?? true,
                    "nudgeVersion": self.myNudgeVersion
                    
                ]
                
                if options[Constants.Options.federationId] != nil {
                    parameters[Constants.Options.federationId] = options[Constants.Options.federationId]
                }

                #if GEO_ENABLED
                myNudge = NudgeGeo(options: parameters)
                #else
                logger.debug(message: "nudgeGeo was requested but this build does not include location code; falling back to nudgeStandard")
                self.myNudgeVersion = NudgeSDK.NudgeVersion.nudgeStandard
                parameters[Constants.Options.nudgeVersion] = self.myNudgeVersion
                myNudge = NudgeBase(options: parameters)
                #endif
            }
            else if (nudgeVersion as! NudgeSDK.NudgeVersion == NudgeSDK.NudgeVersion.nudgeStandard){
                logger.debug(message: "nudgeStandard selected")

                self.myNudgeVersion = NudgeSDK.NudgeVersion.nudgeStandard
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
            self.myNudgeVersion = NudgeSDK.NudgeVersion.nudgeLegacy
            var parameters: [String:Any] = [
                "apiKey": options[Constants.Options.apiKey] as! String,
                "enabled": options[Constants.Options.enabled] as? Bool ?? false,
                "showLocationDialog": options[Constants.Options.showLocationDialog] ?? true,
                "nudgeVersion": self.myNudgeVersion
                
            ]
            
            if options[Constants.Options.federationId] != nil {
                parameters[Constants.Options.federationId] = options[Constants.Options.federationId]
            }

            #if GEO_ENABLED
            myNudge = NudgeGeo(options: parameters)
            #else
            logger.debug(message: "Legacy integration defaults to nudgeGeo but this build does not include location code; falling back to nudgeStandard")
            self.myNudgeVersion = NudgeSDK.NudgeVersion.nudgeStandard
            parameters[Constants.Options.nudgeVersion] = self.myNudgeVersion
            myNudge = NudgeBase(options: parameters)
            #endif
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
            if (myNudgeVersion == NudgeSDK.NudgeVersion.nudgeStandard){
                myNudge?.setFederationId(federationId: formatedFederationId)
            } else if (myNudgeVersion == NudgeSDK.NudgeVersion.nudgeGeo){
                myNudge?.setFederationId(federationId: formatedFederationId)
            } else {
                logger.debug(message: "nudge version is not specified")
            }
        } else {
            logger.debug(message: "nudge is not yet initialized")
        }
        
    }
    
    #if GEO_ENABLED
    @objc public func registerForLocationServices(showLocationDialog: Bool) {

        if (myNudgeVersion == NudgeSDK.NudgeVersion.nudgeGeo && (KeyValueStore.getString(key: KeyValueStore.notificationPermission) == "Accept")){
            if let myNudgeGeo = myNudge as? NudgeGeo {
                KeyValueStore.putBoolean(key: KeyValueStore.showLocationDialog, value: showLocationDialog)
                myNudgeGeo.registerForLocationServices()
            }
        } else {
            logger.debug(message: "This feature is only available in the Geo version of nudge")
        }
    }
    #endif
    
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
            throw NudgeSDK.NudgeErrors.unsupportediOSVersion
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
        
        let deviceId = KeyValueStore.getString(key: KeyValueStore.deviceId)
        
        if (token != nil && deviceId != nil){
            NudgeBase.registerToken(deviceId: deviceId, token: token, bundleId: NudgeBase.bundleId, success: {() in
                KeyValueStore.putString(key: KeyValueStore.APNtoken, value: token)
            DispatchQueue.main.async {
                NSLog("You've been nudged!")
            }
            }, failure: {(message) in
                NSLog("registerToken error:" + message)
            })
        }
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
        if let urlString = (notification.request.content.userInfo[KeyValueStore.MessageData.messageUrl] as? String),
           let url = URL(string: urlString) {
            if isAssociatedDomainLink(url) {
                // This URL belongs to the host app's own domain — leave routing to
                // the host app's own navigation code; it already knows how.
                NSLog("nudge tapped - associated domain link, leaving routing to host app")
            } else {
                redirectToUrl(messageUrl: urlString)
                NSLog("nudge tapped - redirecting to url")
            }
        }
        else {
            NSLog("nudge tapped")
        }
    }

    // Whether the given URL's host matches one of the host app's own Associated
    // Domains entitlements. Lets a host app's own module decide to route a tapped
    // link in-app (e.g. via its own navigation API) without requiring any flag from
    // the integrator — this reads the same entitlement already required for real
    // Universal Links to work at all.
    @objc public static func isAssociatedDomainLink(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return associatedDomains().contains { domain in
            host == domain || host.hasSuffix("." + domain)
        }
    }

    private static var cachedAssociatedDomains: [String]?

    private static func associatedDomains() -> [String] {
        if let cached = cachedAssociatedDomains { return cached }
        let domains = loadAssociatedDomainsFromExecutable()
        cachedAssociatedDomains = domains
        return domains
    }

    // The Associated Domains entitlement is baked into the app's executable at
    // signing time (code-signature blob on device, __entitlements section on
    // simulator), and iOS has no public API to query it (SecTask is macOS-only).
    // So read our own binary and pull the embedded entitlements plist out directly.
    private static func loadAssociatedDomainsFromExecutable() -> [String] {
        guard let execURL = Bundle.main.executableURL,
              let data = try? Data(contentsOf: execURL, options: .alwaysMapped) else { return [] }

        guard let keyRange = data.range(of: Data("com.apple.developer.associated-domains".utf8)) else { return [] }

        // Extract the plist that encloses the key.
        guard let startRange = data.range(of: Data("<?xml".utf8), options: .backwards, in: 0..<keyRange.lowerBound),
              let endRange = data.range(of: Data("</plist>".utf8), in: keyRange.upperBound..<data.count) else { return [] }

        let plistData = data.subdata(in: startRange.lowerBound..<endRange.upperBound)
        guard let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any],
              let entries = plist["com.apple.developer.associated-domains"] as? [String] else { return [] }

        return entries.compactMap { entry in
            entry
                .replacingOccurrences(of: "applinks:", with: "")
                .components(separatedBy: "?")
                .first?
                .lowercased()
        }
    }

    @MainActor
    private static func redirectToUrl(messageUrl: String) {
        guard let url = URL(string: messageUrl) else { return }

        func attemptOpen() {
            // Not this app's own domain — let iOS resolve it normally: another
            // installed app registered for this universal link, or Safari.
            UIApplication.shared.open(url, options: [.universalLinksOnly: true]) { success in
                if !success {
                    // Not a universal link, open normally (Safari)
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }

        if UIApplication.shared.applicationState == .active {
            attemptOpen()
        } else {
            // One-shot: remove the observer as soon as it fires, otherwise every
            // future foregrounding of the app would re-open the same stale link.
            var token: NSObjectProtocol?
            token = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
                if let token = token {
                    NotificationCenter.default.removeObserver(token)
                }
                attemptOpen()
            }
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
    

    @objc public static func handleRichPushNotification(request: UNNotificationRequest,
    contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        guard let bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
            contentHandler(request.content)
            return
        }
        
        let fallback = DispatchWorkItem {
            NSLog("Extension has timed out")
            contentHandler(bestAttemptContent)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 25, execute: fallback)
        
        
        guard let imageURLString = bestAttemptContent.userInfo["image_url"] as? String,
              let url = URL(string: imageURLString) else {
            fallback.cancel()
            contentHandler(bestAttemptContent)
            return
        }

        let lower = imageURLString.lowercased()
        guard lower.hasSuffix(".png") || lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") else {
            NSLog("Failed to load image: Not a valid file type")
            fallback.cancel()
            contentHandler(bestAttemptContent)
            return
        }
        
        NSLog("Downloading image for notification")
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 20
        let session = URLSession(configuration: config)

        session.downloadTask(with: url) { location, response, error in
            if let error = error {
                os_log("Download error: %@", type: .error, error.localizedDescription)
                fallback.cancel()
                contentHandler(bestAttemptContent)
                return
            }

            guard let location = location else {
                fallback.cancel()
                contentHandler(bestAttemptContent)
                return
            }

            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(url.lastPathComponent)

            try? FileManager.default.moveItem(at: location, to: tempURL)

            if let attachment = try? UNNotificationAttachment(identifier: "image", url: tempURL, options: nil) {
                bestAttemptContent.attachments = [attachment]
            }

            fallback.cancel()
            contentHandler(bestAttemptContent)

        }.resume()
        
    }
    
    
    
    
    
}

@objc public class NudgeVersionBridge: NSObject {
    public static let nudgeBase = NudgeSDK.NudgeVersion.nudgeStandard
    public static let nudgeGeo = NudgeSDK.NudgeVersion.nudgeGeo
    public static let nudgeLegacy = NudgeSDK.NudgeVersion.nudgeLegacy
}

public typealias Nudge = NudgeSDK
