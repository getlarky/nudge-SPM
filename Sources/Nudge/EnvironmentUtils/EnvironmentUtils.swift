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
    
    // return the proper URL for the current environment (all mobile requests use the mobile subdomain)
    public static func getNudgeURL(service: String) -> String {
        switch (_env) {
            case Environment.DEV:       return "https://mobile.dev.nudge.rocks/"
            case Environment.STAGING:   return "https://mobile.stg.nudge.rocks/"
            case Environment.DR:        return "https://mobile.proddr.dr.larky.cloud/"
            case Environment.PROD:      return "https://mobile.nudge.larky.cloud/"
        }
    }
    
}
    
