//
//  SwiftQuit.swift
//  Swift Quit
//
//  Created by Johnny Baird on 5/25/22.
//

import Foundation
import AppKit
import AXSwift
import Swindler
import PromiseKit

class SwiftQuit {
    static let defaultSettings: [String: String] = [
        "launchAtLogin": "false",
        "menubarIconEnabled": "true",
        "excludeBehaviour": "excludeApps",
        "launchHidden": "true",
        "closeDelay": "2"
    ]
    
    /*
     Settings
     */
    
    @objc class func getSettings() -> [String:String] {
        var settings = defaultSettings
        if let savedSettings = userDefaults.object(forKey: "SwiftQuitSettings") as? [String:String] {
            settings.merge(savedSettings) { _, saved in saved }
        }

        let closeDelay = Int(settings["closeDelay"] ?? "") ?? 2
        settings["closeDelay"] = String(min(max(closeDelay, 1), 300))
        return settings
    }
    
    @objc class func updateSettings(){
        userDefaults.set(swiftQuitSettings, forKey: "SwiftQuitSettings")
    }
    
    @objc class func getExcludedApps() -> [String] {
        let savedApps = userDefaults.object(forKey: "SwiftQuitExcludedApps") as? [String] ?? []
        return savedApps.map(normalizedApplicationPath)
    }
    
    @objc class func updateExcludedApps(){
        userDefaults.set(swiftQuitExcludedApps, forKey: "SwiftQuitExcludedApps")
    }
    
    @objc class func enableExcludedApps(){
        swiftQuitSettings["excludeBehaviour"] = "excludeApps"
        updateSettings()
    }
    
    @objc class func enableIncludedApps(){
        swiftQuitSettings["excludeBehaviour"] = "includeApps"
        updateSettings()
    }
    
    @objc class func enableMenubarIcon(){
        swiftQuitSettings["menubarIconEnabled"] = "true"
        updateSettings()
    }
    @objc class func disableMenubarIcon(){
        swiftQuitSettings["menubarIconEnabled"] = "false"
        updateSettings()
    }
    
    @objc class func enableLaunchAtLogin(){
        swiftQuitSettings["launchAtLogin"] = "true"
        updateSettings()
    }
    @objc class func disableLaunchAtLogin(){
        swiftQuitSettings["launchAtLogin"] = "false"
        updateSettings()
    }
    
    @objc class func enableLaunchHidden(){
        swiftQuitSettings["launchHidden"] = "true"
        updateSettings()
    }
    @objc class func disableLaunchHidden(){
        swiftQuitSettings["launchHidden"] = "false"
        updateSettings()
    }

    @objc class func setCloseDelay(_ delay: String){
        guard let closeDelay = Int(delay), (1...300).contains(closeDelay) else {
            swiftQuitSettings["closeDelay"] = "2"
            updateSettings()
            return
        }
        swiftQuitSettings["closeDelay"] = String(closeDelay)
        updateSettings()
    }

    class func normalizedApplicationPath(_ application: String) -> String {
        SwiftQuitPolicy.normalizedApplicationPath(application)
    }

    @objc class func activateAutomaticAppClosing(){
        swindler.on { (event: WindowDestroyedEvent) in
            let processIdentifier = event.window.application.processIdentifier
            closeApplication(pid:processIdentifier, eventApp:event.window.application)
        }
    }
    
    class func closeApplication(pid:Int32, eventApp:Swindler.Application) {
        let myAppPid = ProcessInfo.processInfo.processIdentifier

        guard let app = AppKit.NSRunningApplication.init(processIdentifier: pid) else {
            print("Application with PID \(pid) no longer running")
            return
        }

        guard let bundleURL = app.bundleURL else {
            print("Application with PID \(pid) has no bundle URL")
            return
        }
        let applicationName = normalizedApplicationPath(bundleURL.path)
        
        if app.isFinishedLaunching && !app.isTerminated {
            if myAppPid != pid {
                let excludedServices = [
                    "/System/Library/CoreServices/Spotlight.app",
                    "/System/Library/CoreServices/Finder.app",
                    "/System/Library/CoreServices/NotificationCenter.app"
                ]

                if !excludedServices.contains(applicationName),
                   shouldCloseApplication(applicationName: applicationName) {
                    let closeDelay = Int(swiftQuitSettings["closeDelay"] ?? "2") ?? 2
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(min(max(closeDelay, 1), 300))) {
                        if app.isTerminated {
                            return
                        }

                        guard let hasRemainingWindows = liveWindowCheck(pid: pid) else {
                            print("Could not determine remaining windows for \(applicationName); aborting")
                            return
                        }

                        if !hasRemainingWindows,
                           !SwiftQuitPolicy.shouldCancelForHiddenApp(
                            isHidden: app.isHidden,
                            hasRemainingWindows: hasRemainingWindows
                           ) {
                            terminateApplication(app: app)
                        }
                    }
                }
            }
        }
        
        
    }
    
    class func shouldCloseApplication(applicationName:String) -> Bool {
        SwiftQuitPolicy.shouldCloseApplication(
            applicationName: applicationName,
            settings: swiftQuitSettings,
            excludedApplications: swiftQuitExcludedApps
        )
    }

    class func liveWindowCheck(pid: Int32) -> Bool? {
        guard let application = AXSwift.Application(forProcessID: pid) else {
            return nil
        }

        do {
            guard let windows = try application.windows() else {
                return nil
            }
            return !windows.isEmpty
        } catch {
            NSLog("Swift Quit could not read Accessibility windows for PID %d: %@", pid, error.localizedDescription)
            return nil
        }
    }
    
    class func terminateApplication(app:NSRunningApplication) {
        print("Terminated " + (app.localizedName ?? "<no_name>"))
        app.terminate()
    }
    
    class func hideMenu(){
        statusItem.isVisible = false
    }
    
    class func showMenu(){
        statusItem.isVisible = true
    }
    
    
}
