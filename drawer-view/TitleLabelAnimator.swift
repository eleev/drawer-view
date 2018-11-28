//
//  TitleLabelAnimator.swift
//  drawer-view
//
//  Created by Astemir Eleev on 28/11/2018.
//  Copyright © 2018 Astemir Eleev. All rights reserved.
//

import UIKit

public protocol TitleLabelAnimator {
    
    var openedTitleLabel: UILabel { get }
    var closedTitleLabel: UILabel { get }
    
    init(text: String,
         fontSize: (opened: CGFloat, closed: CGFloat),
         color: (opened: UIColor, closed: UIColor))
    
    func animate(for state: DrawerView.State)
    func prepareLayoutConstraints()
}
