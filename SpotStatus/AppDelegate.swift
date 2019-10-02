//
//  AppDelegate.swift
//  SpotStatus
//
//  Created by Josh Spicer <https://joshspicer.com/>. (c) 2019 - All rights reserved.
//

import Cocoa
import Foundation


enum SongInfoToShow {
    case title, artist
}

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
    var showTitleOrArtist: SongInfoToShow = .title
    var switchCount = 0
    let refreshInterval = 2.0
    let switchAfterCount = 3 // show artist every (refreshInterval * switchAfterCount) seconds
    
    var preferences: Preferences!
    
    
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
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences", action: #selector(showPrefs(_:)), keyEquivalent: "m"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        // If there's no spotify running
        if (songName != "") {
            menu.insertItem(NSMenuItem(title: moreDetail, action: nil, keyEquivalent: ""),at: 0)
            menu.insertItem(NSMenuItem(title: "Share - Song To Clipboard", action: #selector(AppDelegate.shareToClipboard(_:)), keyEquivalent: "P"), at: 1)

        }
        
        statusItem.menu = menu
    }
    
    // OnTick.  Reloads the data.
    @objc func reloadSong() {
        let defaults = UserDefaults.standard
        let displayName = defaults.string(forKey: "displayName") ?? ""
        let showArtist = defaults.bool(forKey: "showArtist")
        let cleanSongTitle = defaults.bool(forKey: "cleanSongTitle")
        var artist = ""
        var menuText = ""
        var errorDict: NSDictionary? = nil

        guard let button = statusItem.button else {
            return
        }
        
        // Apple Script for Current Song
        if let scriptObject = NSAppleScript(source: currentTrackScript) {
            out = scriptObject.executeAndReturnError(&errorDict)
            songName = out?.stringValue ?? ""
        }
        if let error = errorDict {
            print(error)
        }
        // Apple Script for Current Artist
        if let scriptObject = NSAppleScript(source: currentArtistScript) {
            out = scriptObject.executeAndReturnError(&errorDict)
            artist = out?.stringValue ?? "" // saving this to show in the moreDetail menu item
            if let error = errorDict {
                print(error)
            }
        }
        
        // assume Spotify isn't playing since we got an empty name
        if songName == "" {
            artist = ""
            if displayName == "" {
                // By default, show the status bar icon.
                button.title = ""
                button.image = NSImage(named: "StatusBarButtonImage")
                return
            }
            button.title = displayName // Show the standby name if we have one. Will be "" otherwise.
        }
        
        // At this point, we ARE playing music, and have a song/artist to display!

        button.title = ""
        button.image = nil
        
        if showTitleOrArtist == .title {
            // get the song title
            if showArtist {
                // if the user wants to show the artist, track when to show it
                switchCount += 1
                if switchCount > switchAfterCount {
                    showTitleOrArtist = .artist
                    switchCount = 0
                }
            }
            menuText = cleanSongTitle ? doCleanSongTitle(songName) : songName
        } else {
            // get the artist name
            showTitleOrArtist = .title
            menuText = artist
        }
        
        if menuText != "" {
            button.image = nil
            button.title = menuText
            button.action = #selector(shareToClipboard(_:))
        }
        
        // populate the more detail menu item
        moreDetail = songName + " by " + artist
        
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
    
    @objc func showPrefs(_ sender: NSMenuItem) {
        //Here I call the title of the Menu Item pressed
        preferences.showWindow(nil)

    }
    
    /**
     doCleanSongTitle -- removes " - Remastered" portions of song titles
     Many titles end with " - Remastered" or " - ##th Anniversary" etc. This gets
     rid of that portion of the name so that the title fits better on the menu bar.
    */
    fileprivate func doCleanSongTitle(_ songName: String) -> String {
        let pattern = " - "
        let components = songName.components(separatedBy: pattern)
        return components[0]
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        reloadSong()
        preferences = Preferences()
        constructMenu()
        

        
        var _ = Timer.scheduledTimer(timeInterval: refreshInterval, target: self, selector: #selector(AppDelegate.reloadSong), userInfo: nil, repeats: true)
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
}

