//
//  Constants.swift
//
//  Created by Evan Snyder on 8/1/18.
//

import Foundation
import UIKit


public struct Constants {


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
            public static let preferredLanguage = "preferred_language"
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
    
    public static let dateFormat = "yyyy-MM-dd HH:mm:ss"
}


internal struct Params: @unchecked Sendable {
    let paramsData: [String:Any]?
}
