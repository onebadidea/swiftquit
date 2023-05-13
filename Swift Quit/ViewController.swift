//
//  ViewController.swift
//  Swift Quit
//
//  Created by Johnny Baird on 5/25/22.
//

import Cocoa
import LaunchAtLogin

class ViewController: NSViewController, NSTableViewDelegate, NSWindowDelegate {
    @objc dynamic var launchAtLogin = LaunchAtLogin.kvo
    
    @IBOutlet weak var launchHiddenSwitch: NSSwitch!
    @IBOutlet weak var displayMenubarIcon: NSSwitch!
    @IBOutlet weak var excludeBehaviourPopupOutlet: NSPopUpButton!
    @IBOutlet weak var excludeBehaviourLabelOutlet: NSTextField!
    @IBOutlet weak var excludedAppsTableView: NSTableView!
    @IBOutlet weak var removeExcludedAppButtonOutlet: NSButton!
    @IBOutlet weak var launchAtLoginSwitch: NSSwitch!
    
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
        print("launch at login:")
        print(launchAtLogin)
        
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
        
    }
    
    @IBAction func launchAtLoginToggle(_ sender: Any) {
        
        if launchAtLoginSwitch.state == NSControl.StateValue.on {
            SwiftQuit.enableLaunchAtLogin()
            LaunchAtLogin.isEnabled = true

        }
        else{
            SwiftQuit.disableLaunchAtLogin()
            LaunchAtLogin.isEnabled = false

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
        let directory = URL(string: "file:///System/Applications/")
        
        dialog.title                   = "Choose Application";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseFiles = true;
        dialog.canChooseDirectories = true;
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
