

// Created by Martin Lexow.
// https://martinlexow.de
// http://ixeau.com


import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    
    
    private let menuBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        guard let created = desktopCreated else { return }
        
        // Menu
        let menuBarMenu = NSMenu()
        
        let toggleMenuItem = NSMenuItem(title: "Hide Desktop", action: #selector(toggleCreateDesktop), keyEquivalent: "")
        updateToggleMenu(toggleMenuItem, for: created)
        menuBarMenu.addItem(toggleMenuItem)
        
        menuBarMenu.addItem(NSMenuItem.separator())
        
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        menuBarMenu.addItem(quitMenuItem)
        
        // Menu Bar Item
        menuBarItem.button?.title = "Camo"
        menuBarItem.menu = menuBarMenu
        updateMenuBarIcon(for: created)
        
    }
    
    
    
    private func execute(path: String, arguments: [String]) -> (output: String?, error: String?) {
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        let task = Process()
        task.launchPath = path
        task.arguments = arguments
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        task.launch()

        var output: String? = nil
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        if let o = String(data: outputData, encoding: .utf8) {
            output = o
        }
        
        var error: String? = nil
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        if let e = String(data: errorData, encoding: .utf8) {
            error = e
        }
        
        return (output, error)
    }
    
    
    
    private let defaultsLaunchPath = "/usr/bin/defaults"
    
    
    
    private var desktopCreated: Bool? {
        
        var arguments = ["read"]
        arguments.append("com.apple.finder")
        arguments.append("CreateDesktop")
        arguments.append("-bool")
        
        let response = execute(path: defaultsLaunchPath, arguments: arguments)
        if let output = response.output {
            if output == "1\n" || output == "1" {
                return true
            } else if output == "0\n" || output == "0" {
                return false
            }
        }
        return nil
        
    }
    
    

    @objc private func toggleCreateDesktop(_ sender: Any?) {
        
        guard let created = desktopCreated else { return }
        
        var arguments = ["write"]
        arguments.append("com.apple.finder")
        arguments.append("CreateDesktop")
        arguments.append("-bool")
        
        if created {
            arguments.append("false")
        } else {
            arguments.append("true")
        }
        
        let _ = execute(path: defaultsLaunchPath, arguments: arguments)
        let _ = execute(path: "/usr/bin/killAll", arguments: ["Finder"])
        
        updateMenuBarIcon(for: !created)
        
        if let item = sender as? NSMenuItem {
            updateToggleMenu(item, for: !created)
        }
        
    }
    
    
    
    private func updateMenuBarIcon(for created: Bool) {
        if created {
            menuBarItem.button?.image = NSImage(named: "nocamo")
        } else {
            menuBarItem.button?.image = NSImage(named: "camo")
        }
        menuBarItem.button?.image?.isTemplate = true
    }
    
    
    
    private func updateToggleMenu(_ item: NSMenuItem, for created: Bool) {
        if created {
           item.state = .off
       } else {
           item.state = .on
       }
    }
    
    
    
    @objc private func quit() {
        NSApp.terminate(self)
    }
    
    

}
