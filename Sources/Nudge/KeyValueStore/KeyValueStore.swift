import Foundation
import UIKit

public struct KeyValueStore {
    static let id = "id"
    public static let nudgeLibraryVersion = "4.1.1"
    public static let devicePlatform = "ios"
    public static let deviceManufacturer = "Apple"
    public static let apiKey = "apiKey"
    public static let nudgeVersion = "nudgeVersion"
    public static let deviceVersion = UIDevice.current.systemVersion
    public static let timezoneValue = TimeZone.current.identifier
    public static let userId = "nudgeUserId"
    public static let federationId = "nudgeFederationId"
    public static let deviceId = "nudgeDeviceId"
    public static let isAuthenticated = "nudgeIsAuthenticated"
    public static let coreServerToken = "coreServerToken"
    public static let pushToken = "nudgePushToken"
    public static let organizationId = "nudgeOrganizationId"
    public static let email = "nudgeEmail"
    public static let organizationName = "nudgeOrganizationName"
    public static let userName = "nudgeUserName"
    public static let isNudgeEnabled = "isNudgeEnabled"
    public static let APNtoken = "APNtoken"
    public static let orgDesiredAccuracy = "orgDesiredAccuracy"
    public static let orgDistanceFilter = "orgDistanceFilter"
    public static let orgAnalyticsApiKey = "orgAnalyticsApiKey"
    public static let orgTokenDealerSecret = "orgTokenDealerSecret"
    public static let showLocationDialog = "showLocationDialog"
    public static let orgLocationDialogTitle = "orgLocationDialogTitle"
    public static let orgLocationDialogBody = "orgLocationDialogBody"
    public static let lastPermissionsPromptTime = "lastPermissionsPromptTime"
    public static let howManyTimesPrompted = "howManyTimesPrompted"
    public static let notificationPermission = "notification_permission"
    public static let locationPermission = "location_permission"

    public struct Defaults {

    }
    
   // public struct Headers {
    public static let authorizationHeader = "Authorization"
    public static let bearer = "Bearer"
    public static let applicationJson = "application/json"
    public static let contentType = "Content-Type"
    public static let nudgeLibraryVersionHeader = "Nudge-Api-Version"
   // }
    
  //  struct Push {
    public struct MessageData {
        public static let messageId = "message_id"
        public static let messageBody = "message_body"
        public static let messageTitle = "message_title"
        public static let messageDescription = "message_description"
        public static let messageName = "message_name"
        public static let messageUrl = "message_url"
        public static let messageSuppress = "message_suppress"
        public static let messageBreadcrumbs = "breadcrumbs"
        public static let isDeepLink = "is_deep_link"
    }
  //  }

    public struct Location {
        public static let userLatitude = "user_latitude"
        public static let userLongitude = "user_longitude"
        public static let latitude = "nudgeLastLatitude"
        public static let longitude = "nudgeLastLongitude"
    }
    
    public init() {
    }
    
    public static func getString(key: String) -> String? {
        return UserDefaults.standard.string(forKey: key)
    }
    
    public static func putString(key: String, value: String?) -> Void {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    public static func getBoolean(key: String) -> Bool {
        return UserDefaults.standard.bool(forKey: key)
    }
    
    public static func putBoolean(key: String, value: Bool) -> Void {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    public static func getDouble(key: String) -> Double {
        return UserDefaults.standard.double(forKey: key)
    }
    
    public static func putDouble(key: String, value: Double) -> Void {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    public static func getFloat(key: String) -> Float {
        return UserDefaults.standard.float(forKey: key)
    }
    
    public static func putFloat(key: String, value: Float) -> Void {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    public static func getInt(key: String) -> Int {
        return UserDefaults.standard.integer(forKey: key)
    }
    
    public static func putInt(key: String, value: Int) -> Void {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    public static func removeObject(key: String) -> Void {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    public static func registerObjects(defaults: [String : Any]) -> Void {
        UserDefaults.standard.register(defaults: defaults)
    }

}
