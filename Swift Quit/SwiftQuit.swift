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
    private static var pendingApplicationClosures: Set<pid_t> = []
    
    /*
     Settings
     */
    
    @objc class func getSettings() -> [String:String] {
        return userDefaults.object(forKey: "SwiftQuitSettings") as? [String:String] ?? ["launchAtLogin":"false","menubarIconEnabled":"true","excludeBehaviour":"excludeApps","launchHidden":"true","closeDelay":"2"]
    }
    
    @objc class func updateSettings(){
        userDefaults.set(swiftQuitSettings, forKey: "SwiftQuitSettings")
    }
    
    @objc class func getExcludedApps() -> [String] {
        return userDefaults.object(forKey: "SwiftQuitExcludedApps") as? [String] ?? []
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
        swiftQuitSettings["closeDelay"] = delay
        updateSettings()
    }

    @objc class func activateAutomaticAppClosing(){
        swindler.on { (event: WindowDestroyedEvent) in
            guard event.external else { return }
            closeApplication(pid: event.window.application.processIdentifier)
        }
    }
    
    class func closeApplication(pid:Int32) {
        let myAppPid = ProcessInfo.processInfo.processIdentifier

        guard let app = AppKit.NSRunningApplication.init(processIdentifier: pid) else {
            print("Application with PID \(pid) no longer running")
            return
        }

        guard let bundleURL = app.bundleURL else {
            print("Application with PID \(pid) has no bundle URL")
            return
        }
        var applicationName = bundleURL.absoluteString

        guard app.isFinishedLaunching,
              app.activationPolicy == .regular else { return }

        applicationName.remove(at: applicationName.index(before: applicationName.endIndex))
        applicationName = applicationName.replacingOccurrences(of: "file://", with: "")
        applicationName = applicationName.replacingOccurrences(of: "%20", with: " ")

        guard myAppPid != pid else { return }

        let excludedServices:[String] = ["/System/Library/CoreServices/Spotlight.app","/System/Library/CoreServices/Finder.app","/System/Library/CoreServices/NotificationCenter.app"]

        guard !excludedServices.contains(applicationName),
              shouldCloseApplication(applicationName: applicationName) else { return }

        guard !pendingApplicationClosures.contains(pid) else { return }
        pendingApplicationClosures.insert(pid)

        let closeDelay = Int(swiftQuitSettings["closeDelay"] ?? "2") ?? 2
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(closeDelay)) {
            defer { pendingApplicationClosures.remove(pid) }

            guard !app.isTerminated else { return }

            if WindowVisibility.hasUserVisibleWindow(for: pid) {
                print("Application still has a user-visible window; aborting")
                return
            }

            terminateApplication(app: app)
        }
    }
    
    class func shouldCloseApplication(applicationName:String) -> Bool {
        return (swiftQuitSettings["excludeBehaviour"] == "excludeApps" && !swiftQuitExcludedApps.contains(applicationName)) || (swiftQuitSettings["excludeBehaviour"] == "includeApps" && swiftQuitExcludedApps.contains(applicationName))
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
