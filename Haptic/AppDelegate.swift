//
//  AppDelegate.swift
//  Haptic
//
//  Created by Todd Laney on 6/6/18.
//  Copyright © 2018 Todd Laney. All rights reserved.
//

import UIKit


// recieve data from user info from watch app
func didReceive(message: [String : Any]) {
    print("RECIEVE: \(message)")
}

func activationDone(active:Bool) {
    // check for missing Watch app, and tell user to install it....
    if WatchSession.isSupported && !WatchSession.isPaired {
        print("*** an APPLE WATCH is not Paired with this iPhone  ****")
    }
    
    // check for missing Watch app, and tell user to install it....
    if WatchSession.isPaired && !WatchSession.isWatchAppInstalled {
        print("*** WATCH APP IS NOT INSTALLED ****")
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // setup comunication with Watch
        WatchSession.activate(recieveMessage:didReceive, activationDone:activationDone)

        return true
    }

}

