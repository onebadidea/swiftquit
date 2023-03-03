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
        
        loadMenu()
        
        if(swiftQuitSettings["launchAtLogin"] != "true"){
            openSettings();
        }
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    @objc func loadMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = #imageLiteral(resourceName: "MenuIcon")
            button.image?.size = NSSize(width: 18.0, height: 18.0)
            button.image?.isTemplate = true
        }
        statusItem.isVisible = true
        let closeAppsMenuItem = NSMenuItem(title: "Close Windowless Apps", action:  #selector(closeApps) , keyEquivalent: "c")
        menu.addItem(closeAppsMenuItem)
        menu.addItem(NSMenuItem.separator())
        let openSettings = NSMenuItem(title: "Settings", action: #selector(openSettings) , keyEquivalent: "s")
        menu.addItem(openSettings)
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    @objc func openSettings() {
        settingsWindow.showWindow(self)
        settingsWindow.shouldCloseDocument = true
        NSApp.activate(ignoringOtherApps: true)
    }
    @objc func closeApps(){
        SwiftQuit.closeWindowlessApps()
    }

}

