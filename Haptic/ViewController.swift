//
//  ViewController.swift
//  Haptic
//
//  Created by Todd Laney on 6/6/18.
//  Copyright © 2018 Todd Laney. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let stack = UIStackView()
    
    @objc func buttonTap(sender:UIButton) {
        guard let str = sender.titleLabel?.text else {return}
        
        print("TAP: \(str)")
        WatchSession.send(message:["play":str])
        
        switch str {
        case "Notification":
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case "Start", "Stop":
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case "Up", "Down":
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case "Success":
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case "Failure":
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case "Retry":
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case "Click":
            UISelectionFeedbackGenerator().selectionChanged()
        default:
            fatalError()
        }
    }
    
    override func viewDidLoad() {
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 8.0
        stack.layoutMargins = UIEdgeInsets(top:4, left:16, bottom:4, right:16)
        stack.isLayoutMarginsRelativeArrangement = true
        view.addSubview(stack)
        
        for str in ["Notification","Up","Down","Success","Failure","Retry","Start","Stop","Click"] {
            let button = UIButton()
            button.setTitle(str, for:.normal)
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 4.0
            button.backgroundColor = .blue
            button.addTarget(self, action: #selector(buttonTap(sender:)), for:.touchUpInside)
            stack.addArrangedSubview(button)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        stack.frame = UIEdgeInsetsInsetRect(self.view.bounds, self.view.safeAreaInsets)
    }

}

