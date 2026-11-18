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
        NSLog("Swift Quit starting from %@", Bundle.main.bundleURL.path)
        terminateDuplicateInstances()

        self.loadMenu()

        if(swiftQuitSettings["menubarIconEnabled"] == "false"){
            SwiftQuit.hideMenu()
        }

        let promptKey = "SwiftQuitAccessibilityPromptRequested"
        let shouldPrompt = !UserDefaults.standard.bool(forKey: promptKey)
        if shouldPrompt {
            UserDefaults.standard.set(true, forKey: promptKey)
        }

        guard AXSwift.checkIsProcessTrusted(prompt: shouldPrompt) else {
            NSLog("Swift Quit is not authorized for Accessibility")
            showAccessibilityAlert()
            return
        }

        Swindler.initialize().done { state in
            swindler = state
            SwiftQuit.activateAutomaticAppClosing()

            if (swiftQuitSettings["launchHidden"] == "false"){
                self.openSettings()
            }
        }.catch { error in
            let message = "Swift Quit could not initialize window monitoring: \(error.localizedDescription)"
            NSLog("Fatal error: %@", message)
            self.showFatalAlert(
                title: "Swift Quit Could Not Start Window Monitoring",
                message: message
            )
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationDidBecomeActive(_ aNotification: Notification) {
        // Do not open the settings window automatically; this breaks launch-hidden mode.
    }
    
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

    private func terminateDuplicateInstances() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
        let currentPid = ProcessInfo.processInfo.processIdentifier
        let currentBundleURL = Bundle.main.bundleURL.standardizedFileURL

        for runningApp in NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier) {
            guard runningApp.processIdentifier != currentPid,
                  runningApp.bundleURL?.standardizedFileURL != currentBundleURL else {
                continue
            }

            NSLog(
                "Terminating duplicate Swift Quit process %d at %@",
                runningApp.processIdentifier,
                runningApp.bundleURL?.path ?? "<unknown>"
            )
            runningApp.terminate()
        }
    }

    private func showAccessibilityAlert() {
        let modernSettingsURL = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility")
        let legacySettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        if let modernSettingsURL,
           NSWorkspace.shared.open(modernSettingsURL) {
            // The System Settings pane is already opening.
        } else if let legacySettingsURL {
            NSWorkspace.shared.open(legacySettingsURL)
        }

        let alert = NSAlert()
        alert.messageText = "Swift Quit Needs Accessibility Access"
        alert.informativeText = "Grant Swift Quit access in System Settings so it can detect when app windows close."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let modernSettingsURL {
                NSWorkspace.shared.open(modernSettingsURL)
            } else if let legacySettingsURL {
                NSWorkspace.shared.open(legacySettingsURL)
            }
        }
    }

    private func showFatalAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "OK")

            if alert.runModal() == .alertFirstButtonReturn {
                self.openSettings()
            }
        }
    }
    
    
}

