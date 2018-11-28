//
//  DrawerView.BlurStyle+Convert.swift
//  drawer-view
//
//  Created by Astemir Eleev on 28/11/2018.
//  Copyright © 2018 Astemir Eleev. All rights reserved.
//

import UIKit

// MARK: - DrawerView.BlurStyle extension

extension DrawerView.BlurStyle {
    func convert() -> UIBlurEffect.Style? {
        switch self {
        case .none:
            return nil
        case .light:
            return .light
        case .extraLight:
            return .extraLight
        case .dark:
            return .dark
        }
    }
}
