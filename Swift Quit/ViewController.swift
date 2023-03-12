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
    
    @IBOutlet weak var quitAppsAutomaticallySwitchOutlet: NSSwitch!
    @IBOutlet weak var quitAppsWhenPopupOutlet: NSPopUpButton!
    @IBOutlet weak var quitAppsWhenLabelOutlet: NSTextField!
    
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
        if(swiftQuitSettings["automaticQuitEnabled"] == "true"){
            quitAppsAutomaticallySwitchOutlet.state = NSControl.StateValue.on
            showQuitAppsWhen()
        }
        
        if(swiftQuitSettings["menubarIconEnabled"] == "true"){
            displayMenubarIcon.state = NSControl.StateValue.on
            //showQuitAppsWhen()
        }
        
        if(swiftQuitSettings["quitWhen"] == "lastWindowClosed"){
            quitAppsWhenPopupOutlet.title = "Last Window Is Closed"
        }
        else{
            quitAppsWhenPopupOutlet.title = "Any Window Is Closed"
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
        }
        else{
            SwiftQuit.disableLaunchAtLogin()
        }
        
    }
    
    @IBAction func displayMenubarIconToggle(_ sender: Any) {
        
        if displayMenubarIcon.state == NSControl.StateValue.on {
            SwiftQuit.enableMenubarIcon()
            SwiftQuit.loadMenu()
        }
        else{
            SwiftQuit.disableMenubarIcon()
            SwiftQuit.hideMenu()
        }
        
    }
    
    
    
    @IBAction func automaticallyQuitApps(_ sender: Any) {
        
        if quitAppsAutomaticallySwitchOutlet.state == NSControl.StateValue.on {
            showQuitAppsWhen()
            SwiftQuit.enableAutomaticQuit()
            SwiftQuit.activateAutomaticAppClosing()
        }
        else{
            hideQuitAppsWhen()
            SwiftQuit.disableAutomaticQuit()
        }
        
    }
    
    func showQuitAppsWhen(){
        quitAppsWhenPopupOutlet.isEnabled = true
        quitAppsWhenLabelOutlet.textColor = .labelColor
    }
    
    func hideQuitAppsWhen(){
        quitAppsWhenPopupOutlet.isEnabled = false
        quitAppsWhenLabelOutlet.textColor = .systemGray
    }
    
    @IBAction func changeQuitOn(_ sender: Any) {
        
        if(quitAppsWhenPopupOutlet.title == "Last Window Is Closed"){
            SwiftQuit.enableQuitOnLastWindow()
        }
        else{
            swiftQuitSettings["quitWhen"] = "anyWindowClosed"
            SwiftQuit.enableQuitOnAnyWindow()
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
