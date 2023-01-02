

// Created by Martin Lexow
// https://martinlexow.de
// http://ixeau.com


import Cocoa
import os.log


fileprivate let logger = Logger(subsystem: "de.ixeau", category: "AppDelegate")


@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
    
    
    private let menuBarItem: NSStatusItem = {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if #available(macOS 13.0, *) {
            statusItem.button?.title = ""
            // Other than the previous versions, macOS 13 Ventura starts showing the `title` when set
        } else {
            statusItem.button?.title = Bundle.main.appName
        }
        statusItem.button?.setAccessibilityTitle(Bundle.main.appName)
        return statusItem
    }()
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        guard let didCreateDesktop = self.didCreateDesktop else {
            logger.fault("Error: Couldn’t get com.apple.finder CreateDesktop")
            return
        }
        
        // Menu
        let menuBarMenu = NSMenu()
        
        // Toggle Menu Item
        let toggleMenuItem = NSMenuItem(title: "Hide Desktop",
                                        action: #selector(toggleCreateDesktop),
                                        keyEquivalent: "")
        self.updateToggleMenu(toggleMenuItem, for: didCreateDesktop)
        menuBarMenu.addItem(toggleMenuItem)
        
        // Separator
        menuBarMenu.addItem(NSMenuItem.separator())
        
        // Quit Menu Item
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        menuBarMenu.addItem(quitMenuItem)
        
        // Apply Changes
        self.menuBarItem.menu = menuBarMenu
        self.updateMenuBarIcon(for: didCreateDesktop)
        
    }
    
    
    @discardableResult
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
    
    
    private static let defaultsLaunchPath = "/usr/bin/defaults"
    
    
    private var didTryCreatingKeyEntry: Bool = false
    
    
    private func createKeyEntry() {
        
        var arguments = ["write"]
        arguments.append("com.apple.finder")
        arguments.append("CreateDesktop")
        arguments.append("-bool")
        arguments.append("true")
        
        let launchPath = AppDelegate.defaultsLaunchPath
        self.execute(path: launchPath, arguments: arguments)
        self.didTryCreatingKeyEntry = true
        
    }
    
    
    private var didCreateDesktop: Bool? {
        
        var arguments = ["read"]
        arguments.append("com.apple.finder")
        arguments.append("CreateDesktop")
        arguments.append("-bool")
        
        let launchPath = AppDelegate.defaultsLaunchPath
        let response = self.execute(path: launchPath, arguments: arguments)
        if let output = response.output {
            if output == "1\n" || output == "1" || output == "true\n" || output == "true" {
                return true
            } else if output == "0\n" || output == "0" || output == "false\n" || output == "false" {
                return false
            }
        }
        
        if self.didTryCreatingKeyEntry {
            return nil
        } else {
            self.createKeyEntry()
            return self.didCreateDesktop
        }
        
    }
    
    
    @objc private func toggleCreateDesktop(_ sender: Any?) {
        
        guard let didCreateDesktop = self.didCreateDesktop else {
            return
        }
        
        var arguments = ["write"]
        arguments.append("com.apple.finder")
        arguments.append("CreateDesktop")
        arguments.append("-bool")
        
        if didCreateDesktop {
            arguments.append("false")
        } else {
            arguments.append("true")
        }
        
        let launchPath = AppDelegate.defaultsLaunchPath
        self.execute(path: launchPath, arguments: arguments)
        self.execute(path: "/usr/bin/killAll", arguments: ["Finder"])
        
        self.updateMenuBarIcon(for: !didCreateDesktop)
        
        if let item = sender as? NSMenuItem {
            self.updateToggleMenu(item, for: !didCreateDesktop)
        }
        
    }
    
    
    private func updateMenuBarIcon(for created: Bool) {
        if created {
            self.menuBarItem.button?.image = NSImage(named: "nocamo")
        } else {
            self.menuBarItem.button?.image = NSImage(named: "camo")
        }
        self.menuBarItem.button?.image?.isTemplate = true
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


extension Bundle {
    var appName: String {
        if let name = self.infoDictionary?["CFBundleName"] as? String {
            return name
        }
        return "–"
    }
}
