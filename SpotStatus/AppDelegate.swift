//
//  AppDelegate.swift
//  SpotStatus
//
//  Created by Josh Spicer <https://joshspicer.com/>. (c) 2019 - All rights reserved.
//

import Cocoa
import Foundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let currentTrackScript = """
    if application "Spotify" is running then
        tell application "Spotify"
            if player state is playing then
                return name of current track
            else
                return ""
        end if
        end tell
    else
        return ""
    end if
    """
    
    let currentArtistScript = """
    tell application "Spotify"
        return artist of current track
    end tell
    """
    
    let songURLScript = """
    tell application "Spotify"
        return spotify url of current track
    end tell
        
    """
    
    
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    var songName: String!
    var moreDetail: String!
    var url: String!
    var out: NSAppleEventDescriptor?
    
    
    // Used to place something onto the user's clipboard
    @objc func shareToClipboard(_ sender: Any?) {
        
        // If there's no url to share.
        if (url == "" || url == nil) {
            return
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
        pasteboard.setString(url, forType: NSPasteboard.PasteboardType.string)
    }
    
    // Generates the dropdown menu
    func constructMenu() {
        let menu = NSMenu()
        
        // If there's no spotify running
        if (songName == "") {
            return
        }
        
        menu.addItem(NSMenuItem(title: moreDetail, action: Selector(""), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Share (song to clipboard)", action: #selector(AppDelegate.shareToClipboard(_:)), keyEquivalent: "P"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    // OnTick.  Reloads the data.
    @objc func reloadSong() {
        
        // Get SONG
        if let scriptObject = NSAppleScript(source: currentTrackScript) {
            var errorDict: NSDictionary? = nil
            out = scriptObject.executeAndReturnError(&errorDict)
            songName = out?.stringValue ?? ""
            
            // If we don't have a song, abort this round!
            // Else place it into the button
            
            if let button = statusItem.button {
                button.image = songName == "" ? NSImage(named:NSImage.Name("StatusBarButtonImage")) : nil
                button.title = songName
                button.action = #selector(shareToClipboard(_:))
            }
            
            if let error = errorDict {
                print(error)
            }
        }
        
        // Check if Spotify is even running...
        if (songName == "") {
            return
        }
        
        // Get ARTIST (more details)
        if let scriptObject = NSAppleScript(source: currentArtistScript) {
            var errorDict: NSDictionary? = nil
            out = scriptObject.executeAndReturnError(&errorDict)
            let artist = out?.stringValue ?? ""
            moreDetail = songName + " by " + artist
            
            if let error = errorDict {
                print(error)
            }
        }
        
        // Run these again to refresh the data.
        trackURL()
        constructMenu()
    }
    
    func trackURL() {
        
        var out: NSAppleEventDescriptor?
        if let scriptObject = NSAppleScript(source: songURLScript) {
            var errorDict: NSDictionary? = nil
            out = scriptObject.executeAndReturnError(&errorDict)
            
            if let error = errorDict {
                print(error)
            }
        }
        let tmpUrl = out?.stringValue ?? "No URL" //will get "spotify:track:3O8AgNdf569SM1tcUA4xnK"
        // Make it match: https://open.spotify.com/track/3O8AgNdf569SM1tcUA4xnK
        let splitUrl = tmpUrl.components(separatedBy: ":")
        url = "https://open.spotify.com/track/" + splitUrl[2]
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        reloadSong()
        
        var refreshTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(AppDelegate.reloadSong), userInfo: nil, repeats: true)
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
}

