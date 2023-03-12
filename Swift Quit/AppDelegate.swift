//
//  AppDelegate.swift
//  Swift Quit
//
//  Created by Johnny Baird on 5/25/22.
//

import Cocoa
import AXSwift
import Swindler
import PromiseKit

var userDefaults = UserDefaults.standard
var swiftQuitSettings = SwiftQuit.getSettings()
var swiftQuitExcludedApps = SwiftQuit.getExcludedApps()

let storyboard = NSStoryboard(name: "Main", bundle: nil)
var settingsWindow = (storyboard.instantiateController(withIdentifier: "settings") as! NSWindowController)
var menu = NSMenu()
var statusItem: NSStatusItem!
var swindler: Swindler.State!
var lastLaunchedAppPid : Int32 = 0;

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        
        guard AXSwift.checkIsProcessTrusted(prompt: true) else {
            print("Not trusted as an AX process; please authorize and re-launch")
            NSApp.terminate(self)
            return
        }
         
        
        Swindler.initialize().done { state in
            swindler = state
            SwiftQuit.activateAutomaticAppClosing()
        }.catch { error in
            print("Fatal error: failed to initialize Swindler: \(error)")
            NSApp.terminate(self)
        }
        
        if(swiftQuitSettings["menubarIconEnabled"] == "true"){
            SwiftQuit.loadMenu()
        }
        else{
            openSettings();
        }
        
        
        
    }
    
    func applicationWillEnterForeground(_ aNotification: Notification) {
        openSettings();
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationDidBecomeActive(_ aNotification: Notification) {
        openSettings();
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    
    @objc func openSettings() {
        settingsWindow.showWindow(self)
        settingsWindow.shouldCloseDocument = true
        NSApp.activate(ignoringOtherApps: true)
    }
 

}

