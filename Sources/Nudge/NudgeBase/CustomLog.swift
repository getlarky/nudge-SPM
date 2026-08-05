//
//  File.swift
//  
//
//  Created by Dana Haukoos on 2/28/23.
//

import Foundation
import os.log

extension OSLog {
    private static let subsystem: String = {
        Bundle(for: NudgeSDK.self).bundleIdentifier ?? "com.yourcompany.yourlibrary"
    }()

    static let locationTracking = OSLog(subsystem: subsystem, category: "locationTracking")
    static let nudgeInit = OSLog(subsystem: subsystem, category: "nudgeInit")
    static let nudge = OSLog(subsystem: subsystem, category: "nudge")
    static let nudgePermissions = OSLog(subsystem: subsystem, category: "nudgePermissions")
    static let nudgeMessaging = OSLog(subsystem: subsystem, category: "nudgeMessaging")
   
}

public final class CustomLog : NSObject, Sendable {
    
    
    public override init() {
        super.init()
    }
    
    public func infoLocationTracking(message: String) {
        os_log("%@", log: OSLog.locationTracking, type: .info, message)
    }
    
    public func debugLocationTracking(message: String) {
        os_log("%@", log: OSLog.locationTracking, type: .debug, message)
    }

    public func errorLocationTracking(message: String) {
        os_log("%@", log: OSLog.locationTracking, type: .error, message)
    }
    
    public func infoNudgeInit(message: String) {
        os_log("%@", log: OSLog.nudgeInit, type: .info, message)
    }
    
    public func debugNudgeInit(message: String) {
        os_log("%@", log: OSLog.nudgeInit, type: .debug, message)
    }

    public func errorNudgeInit(message: String) {
        os_log("%@", log: OSLog.nudgeInit, type: .error, message)
    }
    
    public func debug(message: String) {
        os_log("%@", log: OSLog.nudge, type: .debug, message)
    }
    
    public func infoNudgePermissions(message: String) {
        os_log("%@", log: OSLog.nudgePermissions, type: .info, message)
    }
    
    public func debugNudgePermissions(message: String) {
        os_log("%@", log: OSLog.nudgePermissions, type: .debug, message)
    }

    public func errorNudgePermissions(message: String) {
        os_log("%@", log: OSLog.nudgePermissions, type: .error, message)
    }
    
    public func infoNudgeMessaging(message: String) {
        os_log("%@", log: OSLog.nudgeMessaging, type: .info, message)
    }
    
    public func debugNudgeMessaging(message: String) {
        os_log("%@", log: OSLog.nudgeMessaging, type: .debug, message)
    }

    public func errorNudgeMessaging(message: String) {
        os_log("%@", log: OSLog.nudgeMessaging, type: .error, message)
    }
    
}
