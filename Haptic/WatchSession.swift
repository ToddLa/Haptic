//
//  WatchSession.swift
//  WatchConnectivityDemo
//
//  Created by Natasha Murashev on 9/3/15.
//  Copyright © 2015 NatashaTheRobot. All rights reserved.
//  Updated by Simon Krüger on 2/27/17.
//  Changes © 2017 Kayoslab.
//  Updated by Todd Laney on 3/27/17.
//  Changes © 2017 Wombat.
//
//  USAGE
//
//  you must call activate before sending/recieving
//      WatchSession.activate(recieveInfo:recieveFile:updateContext:)
//
//  call send functions to send data
//      WatchSession.update(context:)
//      WatchSession.send(info:)
//      WatchSession.send(url:metadata:)
//

import WatchKit
import WatchConnectivity

class WatchSession: NSObject, WCSessionDelegate {
    
    private static var shared : WatchSession?
    
    typealias RecieveInfo = ([String:Any]) -> Void
    typealias RecieveFile = (URL,[String:Any]?) -> Void
    private var updateContext : RecieveInfo?
    private var recieveInfo : RecieveInfo?
    private var recieveFile : RecieveFile?
    private var activationDone : ((Bool) -> Void)?

    private var pendingUserInfo = [[String:Any]]()
    
    private static let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    private static var validSession: WCSession? {
        // paired - the user has to have their device paired to the watch
        // watchAppInstalled - the user must have your watch app installed
        
        // Note: if the device is paired, but your watch app is not installed
        // consider prompting the user to install it for a better experience
        #if os(iOS)
            if let session = session, session.isPaired && session.isWatchAppInstalled {
                return session
            }
            return nil
        #else
            return session
        #endif
    }
    
    private init(updateContext : RecieveInfo? = nil,
                 recieveInfo : RecieveInfo? = nil,
                 recieveFile : RecieveFile? = nil,
                 activationDone: ((Bool) -> Void)? = nil) {
        super.init()
        self.updateContext = updateContext
        self.recieveInfo = recieveInfo
        self.recieveFile = recieveFile
        self.activationDone = activationDone
    }
    
    //
    // clients must call activate before data is recieved/sent
    //
    static func activate(updateContext : RecieveInfo? = nil,
                         recieveInfo  : RecieveInfo? = nil,
                         recieveFile  : RecieveFile? = nil,
                         activationDone: ((Bool) -> Void)? = nil) {
        
        assert(shared == nil, "activate called multiple times!")
        shared = WatchSession(updateContext: updateContext, recieveInfo: recieveInfo, recieveFile: recieveFile, activationDone:activationDone)
        
        session?.delegate = shared
        session?.activate()
    }
    
    #if os(iOS)
    //
    // isSupported - are we on a device that supports an Apple Watch
    //
    static var isSupported:Bool {
        return WCSession.isSupported()
    }
    //
    // isWatchAppInstalled - return True if Watch App is installed
    //
    static var isWatchAppInstalled:Bool {
        guard let session = session else {return false}
        assert(session.activationState == .activated)
        return session.isWatchAppInstalled
    }
    //
    // isPaired - return True if a watch if paired with phone
    //
    static var isPaired:Bool {
        guard let session = session else {return false}
        assert(session.activationState == .activated)
        return session.isPaired
    }
    #endif
    
    //
    // isReachable - return True if Watch and App can reach each other.
    //
    static var isReachable:Bool {
        return validSession?.isReachable ?? false
    }
    
    /**
     * Called when the session has completed activation.
     * If session state is WCSessionActivationStateNotActivated there will be an error with more details.
     */
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith: \(activationState.rawValue) \(error.debugDescription)")
        
        activationDone?(activationState == .activated)
        
        if activationState == .activated && !pendingUserInfo.isEmpty {
            pendingUserInfo.forEach({session.transferUserInfo($0)})
            pendingUserInfo.removeAll()
        }
    }

    /** Called when the reachable state of the counterpart app changes. The receiver should check the reachable property on receiving this delegate callback. */
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("sessionReachabilityDidChange: \(session.isReachable)")
    }
    
    #if os(iOS)
    /**
     * Called when the session can no longer be used to modify or add any new transfers and,
     * all interactive messages will be cancelled, but delegate callbacks for background transfers can still occur.
     * This will happen when the selected watch is being changed.
     */
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive")
    }
    /**
     * Called when all delegate callbacks for the previously selected watch has occurred.
     * The session can be re-activated for the now selected watch using activateSession.
     */
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate")
    }
    
    /** Called when any of the Watch state properties change. */
    func sessionWatchStateDidChange(_ session: WCSession) {
        print("sessionWatchStateDidChange")
    }
    #endif
    
    // MARK: Application Context
    // use when your app needs only the latest information, if the data was not sent, it will be replaced
    
    // Current context
    static var applicationContext: [String : Any]? {
        assert(shared != nil, "activate must be called first!")
        return validSession?.applicationContext
    }
    
    // Sender
    static func update(context: [String : Any]) {
        assert(shared != nil, "activate must be called first!")
        try? validSession?.updateApplicationContext(context)
    }
    
    // Receiver
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("didReceiveApplicationContext: \(applicationContext)")
        DispatchQueue.main.async() {
            assert(self.updateContext != nil)
            self.updateContext?(applicationContext)
        }
    }
    
    // MARK: User Info
    // use when your app needs all the data, FIFO
    
    // Sender
    static func send(info: [String : Any]) {
        assert(shared != nil, "activate must be called first!")
        if validSession?.activationState == .notActivated {
            print("transferUserInfo when not activated yet!")
            shared?.pendingUserInfo.append(info)
            return
        }
        print("SEND: \(info)")
        validSession?.transferUserInfo(info)
    }
    
    // Receiver
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        DispatchQueue.main.async() {
            assert(self.recieveInfo != nil)
            self.recieveInfo?(userInfo)
        }
    }
    
    // MARK: Transfer File
    
    // Sender
    static func send(url:URL, metadata: [String : Any]? = nil) {
        assert(shared != nil, "activate must be called first!")
        validSession?.transferFile(url, metadata:metadata)
    }
    
    // Receiver
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        // handle receiving file
        DispatchQueue.main.async() {
            assert(self.recieveFile != nil)
            self.recieveFile?(file.fileURL, file.metadata)
        }
    }
}
