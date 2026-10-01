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
            if !event.window.application.knownWindows.isEmpty {
                print("Application still has windows; aborting")
                return
            }
            
            let processIdentifier = event.window.application.processIdentifier
            closeApplication(pid:processIdentifier, eventApp:event.window.application)
        }

        // Some apps (Discord) hide themselves when their red button is clicked instead of
        // closing the window, so no WindowDestroyedEvent ever fires. Catch the click on the
        // close button itself and quit the app if it hid itself afterwards.
        closeButtonMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { event in
            guard let location = event.cgEvent?.location else { return }

            // The hit test asks another app over accessibility and can block while that app
            // is busy, so keep it off the main thread that Swindler runs on.
            DispatchQueue.global(qos: .userInitiated).async {
                guard let pid = closeButtonOwner(at: location) else { return }

                DispatchQueue.main.async {
                    guard let app = AppKit.NSRunningApplication.init(processIdentifier: pid),
                          !app.isHidden,
                          canCloseApplication(app: app) else { return }

                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(closeDelay())) {
                        if app.isHidden && !app.isTerminated {
                            terminateApplication(app: app)
                        }
                    }
                }
            }
        }
    }

    private static var closeButtonMonitor: Any?

    /// The PID of the app whose window close button is at this screen point, if there is one.
    class func closeButtonOwner(at location: CGPoint) -> pid_t? {
        var element: AXUIElement?
        guard AXUIElementCopyElementAtPosition(AXUIElementCreateSystemWide(), Float(location.x), Float(location.y), &element) == .success,
              let element else { return nil }

        var subrole: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subrole)
        guard subrole as? String == kAXCloseButtonSubrole else { return nil }

        var pid: pid_t = 0
        guard AXUIElementGetPid(element, &pid) == .success, pid != 0 else { return nil }
        return pid
    }

    class func closeDelay() -> Int {
        return Int(swiftQuitSettings["closeDelay"] ?? "2") ?? 2
    }

    class func closeApplication(pid:Int32, eventApp:Swindler.Application) {
        guard let app = AppKit.NSRunningApplication.init(processIdentifier: pid) else {
            print("Application with PID \(pid) no longer running")
            return
        }

        if canCloseApplication(app: app) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(closeDelay())) {
                if eventApp.knownWindows.isEmpty {
                    terminateApplication(app: app)
                }
            }
        }
    }

    /// Whether Swift Quit is allowed to quit this app: not itself, not a protected system
    /// service, and allowed by the user's exclude/include list.
    class func canCloseApplication(app:NSRunningApplication) -> Bool {
        let myAppPid = ProcessInfo.processInfo.processIdentifier

        guard let bundleURL = app.bundleURL else {
            print("Application with PID \(app.processIdentifier) has no bundle URL")
            return false
        }
        var applicationName = bundleURL.absoluteString

        print(app.isFinishedLaunching);

        guard app.isFinishedLaunching, myAppPid != app.processIdentifier else { return false }

        applicationName.remove(at: applicationName.index(before: applicationName.endIndex))
        applicationName = applicationName.replacingOccurrences(of: "file://", with: "")
        applicationName = applicationName.replacingOccurrences(of: "%20", with: " ")

        let excludedServices:[String] = ["/System/Library/CoreServices/Spotlight.app","/System/Library/CoreServices/Finder.app","/System/Library/CoreServices/NotificationCenter.app"];

        guard !excludedServices.contains(applicationName),
              shouldCloseApplication(applicationName: applicationName) else { return false }

        print(applicationName)
        return true
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
