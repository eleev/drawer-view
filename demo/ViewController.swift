//
//  ViewController.swift
//  demo
//
//  Created by Astemir Eleev on 26/11/2018.
//  Copyright © 2018 Astemir Eleev. All rights reserved.
//

import UIKit
import drawer_view

class ViewController: UIViewController {

    private var drawerView: DrawerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        drawerView = DrawerView(bottomSpacing: 200,
                                closedHeight: 80,
                                blurStyle: .none,
                                lineArrow: nil,
                                superView: view)
        
//        drawerView.closeOnRotation = true
//        drawerView.change(state: .open, shouldAnimate: true)
//        drawerView.closeOnChildViewTaps = true
//        drawerView.animationClosure
//        drawerView.completionClosure
//        drawerView.onStateChangeClosure
//        drawerView.cornerRadius = 60
//        drawerView.animationDuration = 1.5
//        drawerView.animationDampingRatio = 1.0
//        drawerView.shadowRadius
//        drawerView.shadowOpacity

        return ()
        
        drawerView.titleLabelAnimator = DefaultTitleLabelAnimator(text: "Title Label Experiment")
        
        let closeButton = UIButton(type: .system)
        drawerView.addSubview(closeButton)
        
        closeButton.backgroundColor = UIColor.init(white: 1.0, alpha: 0.5)
        closeButton.setTitleColor(.black, for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        closeButton.setTitle("Close", for: .normal)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            closeButton.centerXAnchor.constraint(equalTo: (drawerView?.centerXAnchor)!, constant: 0.0),
            closeButton.centerYAnchor.constraint(equalTo: (drawerView?.centerYAnchor)!, constant: 0.0)
            ])
        
        debugPrint("DrawerView subviews: ", drawerView.subviews)
    }
   
}
