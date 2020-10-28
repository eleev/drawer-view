//
//  InstantPanGestureRecognizer.swift
//  drawer-view
//
//  Created by Astemir Eleev on 26/11/2018.
//  Copyright © 2018 Astemir Eleev. All rights reserved.
//

import UIKit

class ImmediatePanGestureRecognizer: UIPanGestureRecognizer {
    
    // MARK: - Overrides
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if self.state == UIGestureRecognizer.State.began { return }
        super.touchesBegan(touches, with: event)
        self.state = UIGestureRecognizer.State.began
    }
}
