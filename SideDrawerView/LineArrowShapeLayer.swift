//
//  LineArrowShapeLayer.swift
//  drawer-view
//
//  Created by Astemir Eleev on 28/11/2018.
//  Copyright © 2018 Astemir Eleev. All rights reserved.
//

import UIKit

class LineArrowShapeLayer: CAShapeLayer {
    
    // MARK: - Properties
    
    private var targetBounds: CGRect = .zero
    private var width: CGFloat
    private var height: CGFloat
    private var bezierPath = UIBezierPath()
    private var lastState: SideDrawerView.State = .closed
    
    // MARK: - Initialiezers
    
    init(height: CGFloat, width: CGFloat, color: UIColor) {
        self.height = height
        self.width = width
        super.init()
        
        fillColor = UIColor.clear.cgColor
        strokeColor = color.cgColor
        lineWidth = width
        lineCap = .round
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update() {
        animateBezierPath(to: lastState)
    }
    
    func animate(for state: SideDrawerView.State) {
        animateBezierPath(to: state)
    }
    
    func completeAnimation(for state: SideDrawerView.State) {
        if lastState == state { return }
        animateBezierPath(to: state)
    }
    
    func calculateBounds(from bounds: CGRect) {
        targetBounds = CGRect(x: (bounds.width / 2) - (width / 2), y: bounds.midY - (height / 2), width: width, height: height)
    }
    
    private func animateBezierPath(to state: SideDrawerView.State) {
        lastState = state
        
        let controlPoint = calculateControlPoint()
        let endPoint = calculateEndPoint()
        
        bezierPath.removeAllPoints()
        bezierPath.move(to: calculateStartPoint())
        
        switch state {
        case .open:
            bezierPath.addQuadCurve(to: endPoint, controlPoint: calculateOpened(controlPoint: controlPoint))
        case .closed:
            bezierPath.addQuadCurve(to: endPoint, controlPoint: controlPoint)
        }
        path = bezierPath.cgPath
    }
    
    private func calculateStartPoint() -> CGPoint {
        return CGPoint(x: targetBounds.midX, y: targetBounds.minY)
    }
    
    private func calculateEndPoint() -> CGPoint {
        return CGPoint(x: targetBounds.midX, y: targetBounds.maxY)
    }
    
    private func calculateControlPoint() -> CGPoint {
        return CGPoint(x: targetBounds.midX, y: targetBounds.midY)
    }
    
    private func calculateOpened(controlPoint: CGPoint) -> CGPoint {
        
        return CGPoint(x: controlPoint.x * 0.40 , y: controlPoint.y) // modifie x for arrow effect
    }
}
