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
        return userDefaults.object(forKey: "SwiftQuitSettings") as? [String:String] ?? ["launchAtLogin":"false","menubarIconEnabled":"true","excludeBehaviour":"excludeApps","launchHidden":"true"]
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
    
    @objc class func activateAutomaticAppClosing(){
        swindler.on { (event: WindowDestroyedEvent) in
            if !event.window.application.knownWindows.isEmpty {
                print("Application still has windows; aborting")
                return
            }
            
            let processIdentifier = event.window.application.processIdentifier
            closeApplication(pid:processIdentifier, eventApp:event.window.application)
        }
    }
    
    class func closeApplication(pid:Int32, eventApp:Swindler.Application) {
        let myAppPid = ProcessInfo.processInfo.processIdentifier
        
        let app = AppKit.NSRunningApplication.init(processIdentifier: pid)!
        var applicationName = app.bundleURL!.absoluteString
        
        print(app.isFinishedLaunching);
        
        if(app.isFinishedLaunching){
            applicationName.remove(at: applicationName.index(before: applicationName.endIndex))
            applicationName = applicationName.replacingOccurrences(of: "file://", with: "")
            applicationName = applicationName.replacingOccurrences(of: "%20", with: " ")
            
            if(myAppPid != pid){
                
                let excludedServices:[String] = ["/System/Library/CoreServices/Spotlight.app","/System/Library/CoreServices/Finder.app","/System/Library/CoreServices/NotificationCenter.app"];
                
                if(!excludedServices.contains(applicationName)){
                    if (shouldCloseApplication(applicationName: applicationName)) {
                        
                        print(applicationName)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                            if eventApp.knownWindows.isEmpty {
                                terminateApplication(app: app)
                            }
                        }
                    }
                }
            }
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
