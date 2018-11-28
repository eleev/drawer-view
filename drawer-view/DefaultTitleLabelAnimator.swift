//
//  DefaultTitleLabelAnimator.swift
//  drawer-view
//
//  Created by Astemir Eleev on 28/11/2018.
//  Copyright © 2018 Astemir Eleev. All rights reserved.
//

import UIKit

public struct DefaultTitleLabelAnimator: TitleLabelAnimator {
   
    // MARK: - Properties
    
    public let openedTitleLabel: UILabel
    public let closedTitleLabel: UILabel

    // MARK: - Initializers
    
    public init(text: String,
                fontSize: (opened: CGFloat, closed: CGFloat) = (20, 28),
                color: (opened: UIColor, closed: UIColor) = (.gray, .black)) {
        
        openedTitleLabel = UILabel()
        openedTitleLabel.font = UIFont.systemFont(ofSize: fontSize.opened, weight: .medium)
        openedTitleLabel.textColor = color.opened
        openedTitleLabel.text = text
        openedTitleLabel.textAlignment = .center
        openedTitleLabel.alpha = 0.0
        
        closedTitleLabel = UILabel()
        closedTitleLabel.font = UIFont.systemFont(ofSize: fontSize.closed, weight: .heavy)
        closedTitleLabel.textColor = color.closed
        closedTitleLabel.text = text
        closedTitleLabel.textAlignment = .center
        closedTitleLabel.alpha = 1.0
    }
    
    // MARK: - Public methods
    
    public func animate(for state: DrawerView.State) {
        switch state {
        case .open:
            openedTitleLabel.transform = .identity
            closedTitleLabel.transform = CGAffineTransform(scaleX: 0.65, y: 0.65).concatenating(CGAffineTransform(translationX: 0, y: -8))
            
            openedTitleLabel.alpha = 1.0
            closedTitleLabel.alpha = 0.0
        case .closed:
            openedTitleLabel.transform = CGAffineTransform(scaleX: 1.6, y: 1.6).concatenating(CGAffineTransform(translationX: 0, y: 8))
            closedTitleLabel.transform = .identity
            
            openedTitleLabel.alpha = 0.0
            closedTitleLabel.alpha = 1.0
        }
    }
    
    public func prepareLayoutConstraints() {
        guard let openedLabelSuperview = openedTitleLabel.superview, let closedLabelSuperview = closedTitleLabel.superview else {
            return
        }
        
        openedTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            openedTitleLabel.centerXAnchor.constraint(equalTo: openedLabelSuperview.centerXAnchor, constant: 0.0),
            openedTitleLabel.topAnchor.constraint(equalTo: openedLabelSuperview.topAnchor, constant: 36.0)
            ])
        
        closedTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closedTitleLabel.centerXAnchor.constraint(equalTo: closedLabelSuperview.centerXAnchor, constant: 0.0),
            closedTitleLabel.topAnchor.constraint(equalTo: closedLabelSuperview.topAnchor, constant: 36.0)
            ])
    }
}
