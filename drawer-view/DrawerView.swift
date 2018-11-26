//
//  DrawerView.swift
//  drawer-view
//
//  Created by Astemir Eleev on 26/11/2018.
//  Copyright © 2018 Astemir Eleev. All rights reserved.
//

import UIKit

// DrawerView UI Component. Intended to be a part of an another UIView and present additional view when needed. The view is not @IBDesignable since there is nothing to present (custom) in the interface builder. However, some properties are @IBInspectable, so you are able to adjust them at design time (in case if you use interface builder).
public class DrawerView: UIView {
    
    // MARK: - Enum types
    
    public enum State {
        case closed
        case open
    }
    
    // MARK: - Public properties
    
    public let bottomSpacing: CGFloat
    public let closedHeight: CGFloat
    public private(set) var visibleHeight: CGFloat
    public let shouldBlurBackground: Bool
    public let blurStyle: UIBlurEffect.Style
    
    @IBInspectable public var closeOnRotation                   = false
    @IBInspectable public var animationDuration: TimeInterval   = 1.5
    @IBInspectable public var cornerRadius: CGFloat             = 40.0
    @IBInspectable public var shadowOpacity: Float = 0.15 {
        didSet {
            layer.shadowOpacity = shadowOpacity
        }
    }
    @IBInspectable public var shadowRadius: CGFloat = 8 {
        didSet {
            layer.shadowRadius = shadowRadius
        }
    }
    
    public var animationClosure: (_ state: State) -> ()   = { _ in }
    public var completionClosure: (_ state: State) -> ()  = { _ in  }
    
    // MARK: - Private properties
    
    private var bottomConstraint            = NSLayoutConstraint()
    private var customHeightAnchor          = NSLayoutConstraint()
    private var currentState: State         = .closed
    private var sholdRecalculateConstraints = false
    
    /// Holds all the running animators
    private var runningAnimators = [UIViewPropertyAnimator]()
    
    /// Holds propgresses of each animator
    private var animationProgress = [CGFloat]()
    
    private lazy var blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: blurStyle)
        let effectView = UIVisualEffectView(effect: blurEffect)
        return effectView
    }()
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer()
        recognizer.addTarget(self, action: #selector(drawerViewGestureRecognizerAction(recognizer:)))
        return recognizer
    }()
    
    private lazy var panGesture: ImmediatePanGestureRecognizer = {
        let recognizer = ImmediatePanGestureRecognizer()
        recognizer.addTarget(self, action: #selector(popupViewPanned(recognizer:)))
        return recognizer
    }()
    
    // MARK: - Initializers
    
    /// A designated initialier for DrawerView. Use initializer to create a new instnace of a DrawerView.
    public init(bottomSpacing: CGFloat = 100,
                closedHeight: CGFloat = 80,
                shouldBlurBackground: Bool = false,
                blurStyle: UIBlurEffect.Style = .extraLight,
                superView: UIView) {
        
        self.bottomSpacing = bottomSpacing
        self.closedHeight = closedHeight
        self.shouldBlurBackground = shouldBlurBackground
        self.blurStyle = blurStyle
        self.visibleHeight = (superView.bounds.height - bottomSpacing) - closedHeight
        
        super.init(frame: .zero)
        
        superView.addSubview(self)
        
        // Inserts the blur effect view below the current view and adds autolayout constraints that fill in the superview
        if shouldBlurBackground {
            superView.insertSubview(blurEffectView, belowSubview: self)
            blurEffectView.alpha = currentState == .open ? 1.0 : 0.0
            
            blurEffectView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                blurEffectView.leadingAnchor.constraint(equalTo: superView.leadingAnchor),
                blurEffectView.trailingAnchor.constraint(equalTo: superView.trailingAnchor),
                blurEffectView.topAnchor.constraint(equalTo: superView.topAnchor),
                blurEffectView.bottomAnchor.constraint(equalTo: superView.bottomAnchor)
                ])
        }
        
        backgroundColor = .white
        layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius = shadowRadius
        
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(panGesture)
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange(notification:)), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeGestureRecognizer(tapGesture)
        removeGestureRecognizer(panGesture)
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        
        subviews.forEach { $0.removeFromSuperview() }
        removeFromSuperview()
    }
    
    // MARK: - Overrides
    
    public override func updateConstraints() {
        super.updateConstraints()
        
        guard let superview = self.superview else { return }
        
        translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
        
        bottomConstraint = bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: currentState == .closed ? visibleHeight : 0.0)
        bottomConstraint.isActive = true
        
        customHeightAnchor = heightAnchor.constraint(equalToConstant: bottomSpacing)
        customHeightAnchor.isActive = true
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        debugPrint(#function)
        
        if sholdRecalculateConstraints {
            guard let superview = self.superview else { return }
            let newHeight = superview.bounds.height - bottomSpacing
            debugPrint("new height: ", newHeight)
            
            visibleHeight = newHeight - 80
            bottomConstraint.constant = visibleHeight
            customHeightAnchor.constant = newHeight
            superview.layoutIfNeeded()
            
            sholdRecalculateConstraints = false
        }
    }
    
    
    // MARK: - Methods
    
    @objc private func orientationDidChange(notification: Notification) {
        if closeOnRotation {
            animateTransitionIfNeeded(to: .closed, duration: animationDuration)
        } else if currentState == .open {
            animateTransitionIfNeeded(to: .open, duration:   animationDuration)
        }
        sholdRecalculateConstraints = true
    }
    
    private func animateTransitionIfNeeded(to state: State, duration: TimeInterval) {
        guard runningAnimators.isEmpty else { return }
        
        let transitionAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1.0, animations: {
            switch state {
            case .open:
                self.bottomConstraint.constant = 0
                self.layer.cornerRadius = self.cornerRadius
                
                if self.shouldBlurBackground { self.blurEffectView.alpha = 1.0 }
            case .closed:
                self.bottomConstraint.constant = self.visibleHeight
                self.layer.cornerRadius = 0.0
                if self.shouldBlurBackground { self.blurEffectView.alpha = 0.0 }
            }
            self.animationClosure(state)
            self.superview?.layoutIfNeeded()
        })
        
        transitionAnimator.addCompletion { position in
            switch position {
            case .start:
                self.currentState = state.opposite
            case .end:
                self.currentState = state
            case .current: ()
            }
            
            switch self.currentState {
            case .open:
                self.bottomConstraint.constant = 0
            case .closed:
                self.bottomConstraint.constant = self.visibleHeight
            }
            self.completionClosure(self.currentState)
            
            self.runningAnimators.removeAll()
        }
        
        transitionAnimator.startAnimation()
        runningAnimators += [transitionAnimator]
    }
    
    @objc private func drawerViewGestureRecognizerAction(recognizer: UITapGestureRecognizer) {
        let state = currentState.opposite
        animateTransitionIfNeeded(to: state, duration: animationDuration)
    }
    
    @objc private func popupViewPanned(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            animateTransitionIfNeeded(to: currentState.opposite, duration: animationDuration)
            runningAnimators.forEach { $0.pauseAnimation() }
            animationProgress = runningAnimators.map { $0.fractionComplete }
            
        case .changed:
            let translation = recognizer.translation(in: self)
            var fraction = -translation.y / visibleHeight
            
            if currentState == .open { fraction *= -1 }
            if runningAnimators[0].isReversed { fraction *= -1 }
            
            for (index, animator) in runningAnimators.enumerated() {
                animator.fractionComplete = fraction + animationProgress[index]
            }
        case .ended:
            let yVelocity = recognizer.velocity(in: self).y
            let shouldClose = yVelocity > 0
            
            @inline(__always) func continueRunningAnimators() {
                runningAnimators.forEach { $0.continueAnimation(withTimingParameters: nil, durationFactor: 0) }
            }
            
            // if there is no motion, continue all animations and exit early
            if yVelocity == 0 {
                continueRunningAnimators()
                break
            }
            
            @inline(__always) func reverseRunningAnimators() {
                runningAnimators.forEach { $0.isReversed = !$0.isReversed }
            }
            
            // reverse the animations based on their current state and pan motion
            switch currentState {
            case .open:
                if !shouldClose, !runningAnimators[0].isReversed {
                    reverseRunningAnimators()
                }
                if shouldClose, runningAnimators[0].isReversed {
                    reverseRunningAnimators()
                }
            case .closed:
                if shouldClose, !runningAnimators[0].isReversed {
                    reverseRunningAnimators()
                }
                if !shouldClose, runningAnimators[0].isReversed {
                    reverseRunningAnimators()
                }
            }
            continueRunningAnimators()
        default: ()
        }
    }
}

// MARK: - DrawerView.State extension
extension DrawerView.State {
    var opposite: DrawerView.State {
        switch self {
        case .open: return .closed
        case .closed: return .open
        }
    }
}
