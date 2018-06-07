//
//  HomePage.swift
//  Watch Extension
//
//  Created by Todd Laney on 6/6/18.
//  Copyright © 2018 Todd Laney. All rights reserved.
//
import WatchKit
import Foundation

class ItemRow : NSObject {
    static let identifier = "ItemRow"
    @IBOutlet var text: WKInterfaceLabel!
}

extension WKHapticType : LosslessStringConvertible {
    
    public init?(_ description: String) {
        var rawValue = 0
        while let haptic = WKHapticType(rawValue:rawValue) {
            if haptic.description == description {
                self.init(rawValue: rawValue)
                return
            }
            rawValue += 1
        }
        return nil
    }
    
    public var description: String {
        switch self {
        case .notification: return "Notification"
        case .directionUp: return "Up"
        case .directionDown: return "Down"
        case .success: return "Success"
        case .failure: return "Failure"
        case .retry: return "Retry"
        case .start: return "Start"
        case .stop: return "Stop"
        case .click: return "Click"
        }
    }
}

class HomePage : WKInterfaceController {
    
    
    @IBOutlet var table: WKInterfaceTable!
    
    var items = [WKHapticType.notification, .directionUp, .directionDown, .success, .failure, .retry, .start, .stop, .click]
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        table.setNumberOfRows(items.count, withRowType: ItemRow.identifier)
        
        for (index, item) in items.enumerated() {
            let row = table.rowController(at: index) as! ItemRow
            row.text.setText(item.description)
        }
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }

    // MARK - Table
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let row = table.rowController(at: rowIndex) as! ItemRow
        print("didSelectRowAt: \(rowIndex) \(row)")
        WKInterfaceDevice.current().play(items[rowIndex])
        WatchSession.send(message:["play":items[rowIndex].description])
    }
    
}
