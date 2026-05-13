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
            
            self.loadMenu()
            
            if(swiftQuitSettings["menubarIconEnabled"] == "false"){
                SwiftQuit.hideMenu()
            }
            
            // 1. Check if the app was launched silently or via system login items
            let isAutoLogin = CommandLine.arguments.contains("--autologin")
            
            // 2. ONLY open UI if it's NOT an auto-login AND launchHidden setting is false
            if !isAutoLogin && (swiftQuitSettings["launchHidden"] == "false") {
                self.openSettings()
            }
            
        }.catch { error in
            print("Fatal error: failed to initialize Swindler: \(error)")
            NSApp.terminate(self)
        }
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    // ⚠️ REMOVED: `applicationDidBecomeActive` previously called `openSettings()`.
    // When macOS boots the app at system login, it marks it active, which triggered the UI.
    func applicationDidBecomeActive(_ aNotification: Notification) {
        // Keep blank so auto-activation doesn't force windows open on startup.
    }
    
    // 3. User explicitly clicks the app icon in Dock/Finder to reveal settings manually
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if (!flag) {
            openSettings();
        }
        return true
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    @objc func loadMenu(){
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = #imageLiteral(resourceName: "MenuIcon")
            button.image?.size = NSSize(width: 18.0, height: 18.0)
            button.image?.isTemplate = true
        }
        statusItem.isVisible = true
        let openSettings = NSMenuItem(title: "Settings...", action: #selector(openSettings) , keyEquivalent: ",")
        menu.addItem(openSettings)
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    @objc func openSettings() {
        settingsWindow.showWindow(self)
        settingsWindow.shouldCloseDocument = true
        NSApp.activate(ignoringOtherApps: true)
    }
}


