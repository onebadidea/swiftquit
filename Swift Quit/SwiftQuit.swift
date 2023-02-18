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
        return userDefaults.object(forKey: "SwiftQuitSettings") as? [String:String] ?? ["automaticQuitEnabled":"true","quitWhen":"lastWindowClosed","launchAtLogin":"false"]
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
    
    @objc class func enableAutomaticQuit(){
        swiftQuitSettings["automaticQuitEnabled"] = "true"
        updateSettings()
    }
    @objc class func disableAutomaticQuit(){
        swiftQuitSettings["automaticQuitEnabled"] = "false"
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
    
    
    @objc class func enableQuitOnLastWindow(){
        swiftQuitSettings["quitWhen"] = "lastWindowClosed"
        updateSettings()
    }
    @objc class func enableQuitOnAnyWindow(){
        swiftQuitSettings["quitWhen"] = "anyWindowClosed"
        updateSettings()
    }
    
    
    @objc class func closeWindowlessApps(){
        let runningApplications = NSWorkspace.shared.runningApplications
        let finderBundleIdentifier = "com.apple.finder"
        
        let myAppPid = ProcessInfo.processInfo.processIdentifier
        
        
        runningApplications.filter {
            $0 != NSRunningApplication.current
            && $0.activationPolicy == .regular
            && $0.bundleIdentifier != finderBundleIdentifier
        }
        .forEach {
            app in
            
            let applicationPID = app.processIdentifier
            
            if(myAppPid != applicationPID){
            
            var applicationName = app.bundleURL!.absoluteString
            applicationName.remove(at: applicationName.index(before: applicationName.endIndex))
            applicationName = applicationName.replacingOccurrences(of: "file://", with: "")
            applicationName = applicationName.replacingOccurrences(of: "%20", with: " ")
            

                if (shouldCloseApplication(applicationName: applicationName)) {
                
                var closeApp = true as Bool
                
                if let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[ String : Any]]{
                    
                    for window in windowList {
                        if let windowName = window[kCGWindowOwnerName as String] as? String {
                            if windowName == app.localizedName!{
                                closeApp = false
                            }
                        }
                    }
                }
                
                if (closeApp == true){
                    terminateApplication(app: app)
                }
        
                
            }
            }
        }
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
        
            if(swiftQuitSettings["automaticQuitEnabled"] == "true"){
            
            applicationName.remove(at: applicationName.index(before: applicationName.endIndex))
            applicationName = applicationName.replacingOccurrences(of: "file://", with: "")
            applicationName = applicationName.replacingOccurrences(of: "%20", with: " ")

            if(myAppPid != pid){
                if (shouldCloseApplication(applicationName: applicationName)) {

                    if(swiftQuitSettings["quitWhen"] == "anyWindowClosed"){
                        terminateApplication(app: app)
                    }
                    else {
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
}
