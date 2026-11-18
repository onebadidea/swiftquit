//
//  ViewController.swift
//  Swift Quit
//
//  Created by Johnny Baird on 5/25/22.
//

import Cocoa
import ServiceManagement

class ViewController: NSViewController, NSTableViewDelegate, NSWindowDelegate {
    @IBOutlet weak var launchHiddenSwitch: NSSwitch!
    @IBOutlet weak var displayMenubarIcon: NSSwitch!
    @IBOutlet weak var excludeBehaviourPopupOutlet: NSPopUpButton!
    @IBOutlet weak var excludeBehaviourLabelOutlet: NSTextField!
    @IBOutlet weak var excludedAppsTableView: NSTableView!
    @IBOutlet weak var removeExcludedAppButtonOutlet: NSButton!
    @IBOutlet weak var launchAtLoginSwitch: NSSwitch!
    @IBOutlet weak var closeDelayTextField: NSTextField!
    @IBOutlet weak var closeDelayLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSApp.activate(ignoringOtherApps: true)
        view.window?.delegate = self
        
        setupViews()
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func setupViews() {
        if #available(macOS 13.0, *) {
            launchAtLoginSwitch.state = SMAppService.mainApp.status == .enabled
                ? .on
                : .off
        } else {
            launchAtLoginSwitch.state = .off
            launchAtLoginSwitch.isEnabled = false
        }

        if(swiftQuitSettings["menubarIconEnabled"] == "true"){
            displayMenubarIcon.state = NSControl.StateValue.on
        }

        if(swiftQuitSettings["launchHidden"] == "true"){
            launchHiddenSwitch.state = NSControl.StateValue.on
        }

        excludeBehaviourLabelOutlet.textColor = .labelColor

        if(swiftQuitSettings["excludeBehaviour"] == "excludeApps"){
            excludeBehaviourPopupOutlet.title = "All Apps Except The Following"
        }
        else{
            excludeBehaviourPopupOutlet.title = "The Following Apps"
        }

        excludedAppsTableView.dataSource = self
        excludedAppsTableView.delegate = self

        // Set the close delay value from settings
        closeDelayTextField.stringValue = swiftQuitSettings["closeDelay"] ?? "2"
    }

    @objc func closeDelayChanged(_ sender: NSTextField) {
        let value = sender.stringValue
        // Validate that it's a positive number
        if let intValue = Int(value), intValue > 0 {
            SwiftQuit.setCloseDelay(value)
        } else {
            // Reset to previous value if invalid
            sender.stringValue = swiftQuitSettings["closeDelay"] ?? "2"
        }
    }
    
    @IBAction func launchAtLoginToggle(_ sender: Any) {
        guard #available(macOS 13.0, *) else { return }

        do {
            if launchAtLoginSwitch.state == .on {
                try SMAppService.mainApp.register()
                SwiftQuit.enableLaunchAtLogin()
            } else {
                try SMAppService.mainApp.unregister()
                SwiftQuit.disableLaunchAtLogin()
            }
        } catch {
            launchAtLoginSwitch.state = SMAppService.mainApp.status == .enabled ? .on : .off
            let alert = NSAlert()
            alert.messageText = "Unable to Update Login Item"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
    
    @IBAction func displayMenubarIconToggle(_ sender: Any) {
        
        if displayMenubarIcon.state == NSControl.StateValue.on {
            SwiftQuit.enableMenubarIcon()
            SwiftQuit.showMenu()
        }
        else{
            SwiftQuit.disableMenubarIcon()
            SwiftQuit.hideMenu()
            
            let disableMenubarAlert = NSAlert()
            disableMenubarAlert.messageText = "App Hidden from Menubar"
            disableMenubarAlert.informativeText = "If you need to access it, simply launch the app again to display the settings page."
            disableMenubarAlert.alertStyle = .informational
            disableMenubarAlert.addButton(withTitle: "OK")
            disableMenubarAlert.beginSheetModal(for: self.view.window!, completionHandler: nil)

        }
        
    }
    
    @IBAction func launchHiddenToggle(_ sender: Any) {
        
        if launchHiddenSwitch.state == NSControl.StateValue.on {
            SwiftQuit.enableLaunchHidden()
        }
        else{
            SwiftQuit.disableLaunchHidden()
        }
    }
    
    @IBAction func changeExcludeBehaviour(_ sender: Any) {
        
        if(excludeBehaviourPopupOutlet.title == "All Apps Except The Following"){
            SwiftQuit.enableExcludedApps()
        }
        else{
            swiftQuitSettings["excludeBehaviour"] = "includeApps"
            SwiftQuit.enableIncludedApps()
        }
    }
    
    @IBAction func addExcludedApp(_ sender: Any) {
        let dialog = NSOpenPanel();
        let directory = URL(fileURLWithPath: "/Applications", isDirectory: true)
        
        dialog.title                   = "Choose Application";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseFiles = true;
        dialog.canChooseDirectories = false;
        dialog.treatsFilePackagesAsDirectories = true
        dialog.directoryURL = directory
        
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            let result = dialog.url
            
            if (result != nil) {
                
                swiftQuitExcludedApps.append(result!.path)
                
                let count = swiftQuitExcludedApps.count - 1
                let indexSet = IndexSet(integer:count)
                
                excludedAppsTableView.beginUpdates()
                excludedAppsTableView.insertRows(at:indexSet, withAnimation:.effectFade)
                excludedAppsTableView.endUpdates()
                
                SwiftQuit.updateExcludedApps()
            }
        } else {
            return
        }
    }
    
    @IBAction func removeExcludedApp(_ sender: Any) {
        let row = excludedAppsTableView.selectedRow
        
        if(row != -1){
            
            let indexSet = IndexSet(integer:row)
            excludedAppsTableView.beginUpdates()
            swiftQuitExcludedApps.remove(at: row)
            excludedAppsTableView.removeRows(at:indexSet, withAnimation:.effectFade)
            excludedAppsTableView.endUpdates()
            
            if(swiftQuitExcludedApps.isEmpty){
                removeExcludedAppButtonOutlet.isHidden = true
            }
            
            SwiftQuit.updateExcludedApps()
        }
        
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectionCount = excludedAppsTableView.selectedRowIndexes.count
        if(selectionCount != 0){
            removeExcludedAppButtonOutlet.isHidden = false
        }
        else{
            removeExcludedAppButtonOutlet.isHidden = true
        }
    }
    
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return swiftQuitExcludedApps.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let application = swiftQuitExcludedApps[row]
        
        let columnIdentifier = tableColumn!.identifier.rawValue
        
        if columnIdentifier == "path" {
            return application
        } else {
            return nil
        }
    }
    
}
