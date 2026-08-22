//
//  SwiftQuit.swift
//  Swift Quit
//
//  Created by Johnny Baird on 5/25/22.
//

import Foundation
import AppKit
import ApplicationServices

class SwiftQuit {

    private static let windowMonitoringQueue = DispatchQueue(
        label: "onebadidea.Swift-Quit.window-monitoring",
        qos: .utility
    )
    private static var windowPollingTimer: DispatchSourceTimer?
    private static var knownWindowCounts: [pid_t: Int] = [:]
    private static var scheduledTerminationProcessIdentifiers = Set<pid_t>()
    
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
        guard windowPollingTimer == nil else {
            return
        }

        // Window-destroyed events are not delivered reliably on macOS 26.
        // Poll the accessibility window list and detect nonzero-to-zero
        // transitions instead.
        let pollingTimer = DispatchSource.makeTimerSource(
            queue: windowMonitoringQueue
        )
        pollingTimer.schedule(
            deadline: .now(),
            repeating: .milliseconds(500),
            leeway: .milliseconds(100)
        )
        pollingTimer.setEventHandler {
            inspectRunningApplications()
        }
        windowPollingTimer = pollingTimer
        pollingTimer.resume()
    }

    private class func inspectRunningApplications() {
        autoreleasepool {
            let applications = NSWorkspace.shared.runningApplications.filter {
                shouldMonitor(application: $0)
            }
            let runningProcessIdentifiers = Set(
                applications.map(\.processIdentifier)
            )

            for application in applications {
                guard let currentWindowCount = accessibleWindowCount(
                    for: application
                ) else {
                    continue
                }

                let processIdentifier = application.processIdentifier
                let previousWindowCount = knownWindowCounts.updateValue(
                    currentWindowCount,
                    forKey: processIdentifier
                )

                if previousWindowCount ?? 0 > 0 && currentWindowCount == 0 {
                    scheduleTermination(for: application)
                }
            }

            knownWindowCounts = knownWindowCounts.filter {
                runningProcessIdentifiers.contains($0.key)
            }
            scheduledTerminationProcessIdentifiers.formIntersection(
                runningProcessIdentifiers
            )
        }
    }

    private class func shouldMonitor(
        application: NSRunningApplication
    ) -> Bool {
        guard let applicationPath = application.bundleURL?.path else {
            return false
        }

        return application.processIdentifier
            != ProcessInfo.processInfo.processIdentifier
            && !application.isTerminated
            && application.isFinishedLaunching
            && application.activationPolicy == .regular
            && !excludedSystemApplications.contains(applicationPath)
    }

    private class func accessibleWindowCount(
        for application: NSRunningApplication
    ) -> Int? {
        let applicationElement = AXUIElementCreateApplication(
            application.processIdentifier
        )
        var copiedWindowElements: CFTypeRef?
        let copyError = AXUIElementCopyAttributeValue(
            applicationElement,
            kAXWindowsAttribute as CFString,
            &copiedWindowElements
        )

        guard copyError == .success else {
            return nil
        }

        return (copiedWindowElements as? [AXUIElement] ?? []).count
    }

    private class func scheduleTermination(
        for application: NSRunningApplication
    ) {
        let processIdentifier = application.processIdentifier
        guard !scheduledTerminationProcessIdentifiers.contains(
            processIdentifier
        ) else {
            return
        }

        scheduledTerminationProcessIdentifiers.insert(processIdentifier)
        let expectedBundleIdentifier = application.bundleIdentifier
        let expectedBundleURL = application.bundleURL
        let currentSettings = getSettings()
        let closeDelay = Int(currentSettings["closeDelay"] ?? "2") ?? 2

        windowMonitoringQueue.asyncAfter(
            deadline: .now() + .seconds(closeDelay)
        ) {
            scheduledTerminationProcessIdentifiers.remove(processIdentifier)

            guard let runningApplication = NSRunningApplication(
                processIdentifier: processIdentifier
            ),
            shouldMonitor(application: runningApplication),
            runningApplication.bundleIdentifier == expectedBundleIdentifier,
            runningApplication.bundleURL == expectedBundleURL,
            let currentWindowCount = accessibleWindowCount(
                for: runningApplication
            ) else {
                return
            }

            knownWindowCounts[processIdentifier] = currentWindowCount

            guard currentWindowCount == 0,
                  let applicationPath = runningApplication.bundleURL?.path,
                  shouldCloseApplication(applicationPath: applicationPath)
            else {
                return
            }

            DispatchQueue.main.async {
                terminateApplication(application: runningApplication)
            }
        }
    }

    private static let excludedSystemApplications: Set<String> = [
        "/System/Library/CoreServices/Spotlight.app",
        "/System/Library/CoreServices/Finder.app",
        "/System/Library/CoreServices/NotificationCenter.app"
    ]
    
    class func shouldCloseApplication(applicationPath: String) -> Bool {
        let currentSettings = getSettings()
        let currentExcludedApplications = getExcludedApps()

        return (
            currentSettings["excludeBehaviour"] == "excludeApps"
                && !currentExcludedApplications.contains(applicationPath)
        ) || (
            currentSettings["excludeBehaviour"] == "includeApps"
                && currentExcludedApplications.contains(applicationPath)
        )
    }
    
    class func terminateApplication(application: NSRunningApplication) {
        print("Terminated " + (application.localizedName ?? "<no_name>"))
        application.terminate()
    }
    
    class func hideMenu(){
        statusItem.isVisible = false
    }
    
    class func showMenu(){
        statusItem.isVisible = true
    }
    
    
}
