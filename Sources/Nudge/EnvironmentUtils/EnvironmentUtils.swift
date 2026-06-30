//
//  EnvironmentUtils.swift
//
//  Created by Dana Haukoos on 3/17/22.
//


import Foundation

public class EnvironmentUtils {

    // default to production environment
    private static let _env: Environment = Environment.PROD
    public enum Environment: String, Sendable {
        case DEV = "dev"
        case STAGING = "staging"
        case PROD = "prod"
        case DR = "dr"
    }

    public enum Service: String {
        case CORE = "core"
        case TOKENDEALER = "tokendealer"
    }
    
    // default to production environment
    public init() {}

    public static func getEnv() -> String {
        return _env.rawValue
    }
    
    // return the proper URL given a desired environment and service (i.e. core or tokendealer endpoint)
    public static func getNudgeURL(service: String) -> String {
        if(Service(rawValue: service) == nil) {
            return "Service name not valid.";
        }
        switch (_env) {
            case Environment.DEV:       return "https://" + service + ".dev.nudge.rocks/"
            case Environment.STAGING:   return "https://" + service + ".stg.nudge.rocks/"
            case Environment.DR:        return "https://" + service + ".proddr.dr.larky.cloud/"
            case Environment.PROD:      return "https://" + service + ".nudge.larky.cloud/"
        }
    }
    
}
    
