//
//  Constants.swift
//
//  Created by Evan Snyder on 8/1/18.
//

import Foundation
import UIKit


public struct Constants {
//    static let id = "id"
//    public static let nudgeLibraryVersion = "4.0.0"
//    public static let devicePlatform = "ios"
//    static let deviceManufacturer = "Apple"
//    static let deviceModel = NudgeAnalytics.getDeviceModel()
//    static let deviceVersion = UIDevice.current.systemVersion
//    static let timezoneValue = TimeZone.current.identifier

    public struct Core {
        //public static let url = Config.coreServerUrl
        public struct Endpoints {
            static let initializeNudge = "mobile/initialize-nudge"
            static let registerToken = "mobile/register-token"
            public static let actionsByLocationAndDatetime = "mobile/ablad"
            static let toggleNotifications = "mobile/users/toggle-notifications"
            static let setFederationId = "mobile/federation-id"
            static let setNudgeEnabled = "mobile/enable-disable-nudge"
            static let setPermissionsParams = "mobile/notification-permissions"
            static let nudgeReceived = "mobile/nudge-received"
            static let nudgeTapped = "mobile/nudge-tapped"
        }
        static let url = EnvironmentUtils.getNudgeURL(service: EnvironmentUtils.Service.CORE.rawValue) // + Endpoints.initializeNudge

        struct PostData {
            static let apiKey = "api_key"
            static let federationId = "federation_id"
            static let userId = "user_id"
            static let deviceId = "device_id"
            static let token = "token"
            static let bundleId = "bundle_id"
            static let devicePlatform = "device_platform"
            static let platform = "platform"
            static let platformVersion = "device_platform_version"
            static let iosPlatform = "ios"
            static let manufacturer = "device_manufacturer"
            static let model = "device_model"
            static let timezone = "timezone"
            static let toggle = "toggle"
            static let enable = "enable"
            static let disable = "disable"
            static let isEnabled = "is_enabled"
            static let organizationId = "organization_id"
            static let notificationPermission = "notification_permission"
            static let locationPermission = "location_permission"
            static let messageId = "message_id"
            static let breadcrumbs = "breadcrumbs"
            static let timestamp = "timestamp"
        }
        struct GetData {
            static let userId = "user_id"
            static let deviceId = "device_id"
            static let organizationId = "organization_id"
            static let notifications = "notifications"
            static let libraryConfig = "library_config"
        }
        struct LibraryConfigVariables {
            static let desiredAccuracy = "desired_accuracy"
            static let distanceFilter = "distance_filter"
            static let analyticsApiKey = "analytics_api_key_ios"
            static let tokenDealerSecret = "tokendealer_secret_ios"
            static let locationDialogTitle = "ios_location_dialog_title"
            static let locationDialogBody = "ios_location_dialog_body"
        }
    }
    
    struct Tokendealer {
        //static let url = Config.tokendealerServerUrl
        static let url = EnvironmentUtils.getNudgeURL(service: EnvironmentUtils.Service.TOKENDEALER.rawValue)
        struct Endpoints {
            static let createToken = "token"
        }
        struct PostData {
            static let coreAudience = "CORE"
            static let accessToken = "access_token"
        }
    }
    
    struct Options {
        static let apiKey = "apiKey"
        static let enabled = "enabled"
        static let showLocationDialog = "showLocationDialog"
        static let federationId = "federationId"
        static let nudgeVersion = "nudgeVersion"
    }
//    struct Push {
//        struct MessageData {
//            static let messageId = "message_id"
//            static let messageBody = "message_body"
//            static let messageTitle = "message_title"
//            static let messageDescription = "message_description"
//            static let messageName = "message_name"
//            static let messageUrl = "message_url"
//            static let messageSuppress = "message_suppress"
//            static let messageBreadcrumbs = "breadcrumbs"
//        }
//    }
    
    // renamesd  "Location"
//    struct Analytics {
//        static let userLatitude = "user_latitude"
//        static let userLongitude = "user_longitude"
//    }
    
//    public struct Defaults {
//        public static let userId = "nudgeUserId"
//        static let federationId = "nudgeFederationId"
//        public static let deviceId = "nudgeDeviceId"
//        static let isAuthenticated = "nudgeIsAuthenticated"
//        static let coreServerToken = "coreServerToken"
//        static let pushToken = "nudgePushToken"
//        public static let organizationId = "nudgeOrganizationId"
//        public static let email = "nudgeEmail"
//        public static let organizationName = "nudgeOrganizationName"
//        public static let userName = "nudgeUserName"
////        public static let latitude = "nudgeLastLatitude"
////        public static let longitude = "nudgeLastLongitude"
//        public static let isNudgeEnabled = "isNudgeEnabled"
//        public static let APNtoken = "APNtoken"
//        public static let orgDesiredAccuracy = "orgDesiredAccuracy"
//        public static let orgDistanceFilter = "orgDistanceFilter"
//        static let orgAnalyticsApiKey = "orgAnalyticsApiKey"
//        static let orgTokenDealerSecret = "orgTokenDealerSecret"
//        public static let showLocationDialog = "showLocationDialog"
//        public static let orgLocationDialogTitle = "orgLocationDialogTitle"
//        public static let orgLocationDialogBody = "orgLocationDialogBody"
//        public static let lastPermissionsPromptTime = "lastPermissionsPromptTime"
//        public static let howManyTimesPrompted = "howManyTimesPrompted"
//    }
    
//    public struct Headers {
//        static let authorizationHeader = "Authorization"
//        static let bearer = "Bearer"
//        static let applicationJson = "application/json"
//        static let contentType = "Content-Type"
//        static let nudgeLibraryVersionHeader = "Nudge-Api-Version"
//    }
    
    public static let dateFormat = "yyyy-MM-dd HH:mm:ss"
}
