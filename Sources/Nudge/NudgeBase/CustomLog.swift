//
//  File.swift
//  
//
//  Created by Dana Haukoos on 2/28/23.
//

import Foundation
import os.log

extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!

    static let locationTracking = OSLog(subsystem: subsystem, category: "locationTracking")
    static let nudgeInit = OSLog(subsystem: subsystem, category: "nudgeInit")
    static let nudge = OSLog(subsystem: subsystem, category: "nudge")
}

public class CustomLog : NSObject {
    
    
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
    
}
