//
//  DrawerView.State+Opposite.swift
//  drawer-view
//
//  Created by Astemir Eleev on 28/11/2018.
//  Copyright © 2018 Astemir Eleev. All rights reserved.
//

import UIKit

// MARK: - DrawerView.State extension

extension SideDrawerView.State {
    var opposite: SideDrawerView.State {
        switch self {
        case .open: return .closed
        case .closed: return .open
        }
    }
}
