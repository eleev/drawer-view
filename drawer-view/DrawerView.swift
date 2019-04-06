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

    public enum BlurStyle {
        case none
        case extraLight
        case light
        case dark
    }
    
    public enum State {
        case closed
        case open
    }
    
    // MARK: - Public properties
    
    public let topLayoutGuidePadding: CGFloat
    public let closedHeight: CGFloat
    public private(set) var visibleHeight: CGFloat
    public let blurStyle: BlurStyle
    
    public private(set) var currentState: State = .closed {
        didSet {
            if givesHapticFeedback {
                hapticFeedback.impactOccurred()
            }
            onStateChangeClosure(currentState)
        }
    }
    
    /// The component will change its state when device is rotated to .closed if the component was in .open state
    @IBInspectable public var closeOnRotation                   = false
    /// The component will change its state to .closed when child views are interacted
    @IBInspectable public var closeOnChildViewTaps              = false
    /// The component will change its state to .closed when the drawer is tapped
    @IBInspectable public var closeOnDrawerTaps                 = true
    /// The component will change its state to .closed when a tap occurs out of itself
    @IBInspectable public var closeOnBlurTapped                 = false
    /// The component will give the user haptic feedback at after state change
    @IBInspectable public var givesHapticFeedback               = true
    @IBInspectable public var animationDuration: TimeInterval   = 1.5
    @IBInspectable public var animationDampingRatio: CGFloat    = 1.0
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
    
    /// Use this close if you want to animate any other UIKit related component alongside with this component
    public var animationClosure:        (_ state: State)->() = { _ in }
    /// Use this cloure if you want to get animation completion callbacks
    public var completionClosure:       (_ state: State)->() = { _ in }
    /// Use this clossure if you want to get callbacks when State changes
    public var onStateChangeClosure:    (_ state: State)->() = { _ in }
    
    public var titleLabelAnimator: TitleLabelAnimator? {
        didSet {
            guard let titleLabelAnimator = self.titleLabelAnimator else {
                return
            }
            self.addSubview(titleLabelAnimator.openedTitleLabel)
            self.addSubview(titleLabelAnimator.closedTitleLabel)
            titleLabelAnimator.prepareLayoutConstraints()
        }
    }
    
    // MARK: - Private properties
    
    private var bottomConstraint            = NSLayoutConstraint()
    private var customHeightAnchor          = NSLayoutConstraint()
    
    private var sholdRecalculateConstraints = false
    private let shouldBlurBackground: Bool
    private lazy var hapticFeedback: UIImpactFeedbackGenerator = {
        return UIImpactFeedbackGenerator(style: UIImpactFeedbackGenerator.FeedbackStyle.medium)
    }()
    
    /// Holds all the running animators
    private var runningAnimators = [UIViewPropertyAnimator]()
    
    /// Holds propgresses of each animator
    private var animationProgress = [CGFloat]()
    
    private lazy var blurEffectView: UIVisualEffectView? = {
        guard let style = blurStyle.convert() else {
            return nil
        }
        let blurEffect = UIBlurEffect(style: style)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.addGestureRecognizer(outTapGesture)
        return effectView
    }()
    
    private lazy var outTapGesture: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer()
        recognizer.addTarget(self, action: #selector(drawerViewGestureTappedOut(recognizer:)))
        return recognizer
    }()
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer()
        recognizer.addTarget(self, action: #selector(drawerViewGestureTapped(recognizer:)))
        recognizer.delegate = self
        return recognizer
    }()
    
    private lazy var panGesture: ImmediatePanGestureRecognizer = {
        let recognizer = ImmediatePanGestureRecognizer()
        recognizer.addTarget(self, action: #selector(drawerViewGesturePanned(recognizer:)))
        recognizer.delegate = self
        return recognizer
    }()
    
    // MARK: - Line Arrow Shape Layer
    
    private var lineArrowShapeLayer: LineArrowShapeLayer?
    
    
    // MARK: - Initializers
    
    /// A designated initialier for DrawerView. Use initializer to create a new instnace of a DrawerView. Note that the view will add itself to the super view and must not do that manually. A typical use-case of this class it to instantiate a variable or property and optionally use closures to animate UIKit related contnet alongside with the DrawerView.
    public init(topLayoutGuidePadding: CGFloat = 100,
                closedHeight: CGFloat = 80,
                blurStyle: BlurStyle = .extraLight,
                lineArrow: (height: CGFloat, width: CGFloat, color: UIColor)? = (8, 100, .lightGray),
                superView: UIView) {
        
        self.topLayoutGuidePadding = topLayoutGuidePadding
        self.closedHeight = closedHeight
        self.shouldBlurBackground = blurStyle != .none
        self.blurStyle = blurStyle
        self.visibleHeight = (superView.bounds.height - topLayoutGuidePadding) - closedHeight
        
        super.init(frame: .zero)
        
        superView.addSubview(self)
        setupConstraints()
        
        if let lineArrow = lineArrow {
            lineArrowShapeLayer = LineArrowShapeLayer(height: lineArrow.height,
                                                      width: lineArrow.width,
                                                      color: lineArrow.color)
            // We know for sure that LineArrowShapeLayer is not nil since it was just instantiated
            layer.addSublayer(lineArrowShapeLayer!)
        }

        
        // Inserts the blur effect view below the current view and adds autolayout constraints that fill in the superview
        if shouldBlurBackground, let blurEffectView = blurEffectView {
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
    
    //
    
    /// In some cases (seems to depend on the view (controller) hierarchy) on has to call this function BEFORE the first animation to make it look right.
    ///
    /// Otherwise it may look like the component is expanding from the origin of its superview instead of appearing from the bottom.
    public func setInitial(frame: CGRect) {
        self.blurEffectView?.frame = frame
        
        var initialFrame = frame
        initialFrame.origin.y = initialFrame.size.height
        initialFrame.size.height = 0
        
        self.frame = initialFrame
    }
    
    deinit {
        removeGestureRecognizer(tapGesture)
        removeGestureRecognizer(panGesture)
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        
        subviews.forEach { $0.removeFromSuperview() }
        removeFromSuperview()
    }
    
    // MARK: - Overrides
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        resolveLayoutChanges()
    }
    
    // MARK: - Methods
    
    public func change(state: DrawerView.State, shouldAnimate: Bool = true) {
        let animationDuration = shouldAnimate ? self.animationDuration : 0.0
        animateTransitionIfNeeded(to: state, duration: animationDuration)
    }
    
    @objc private func orientationDidChange(notification: Notification) {
        if closeOnRotation {
            animateTransitionIfNeeded(to: .closed, duration: animationDuration)
        } else if currentState == .open {
            animateTransitionIfNeeded(to: .open, duration: animationDuration)
        }
        sholdRecalculateConstraints = true
    }
    
    private func animateTransitionIfNeeded(to state: State, duration: TimeInterval) {
        guard runningAnimators.isEmpty else { return }
        
        let transitionAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: animationDampingRatio, animations: {
            switch state {
            case .open:
                self.bottomConstraint.constant = 0
                self.layer.cornerRadius = self.cornerRadius
                
                if self.shouldBlurBackground { self.blurEffectView?.alpha = 1.0 }
            case .closed:
                self.bottomConstraint.constant = self.visibleHeight
                self.layer.cornerRadius = 0.0
                if self.shouldBlurBackground { self.blurEffectView?.alpha = 0.0 }
            }
            
            self.titleLabelAnimator?.animate(for: state)
            self.lineArrowShapeLayer?.animate(for: state)
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
            @unknown default:
                fatalError("The unknown case is not handled. Please, review the transition animator and make the appropriate changes.")
            }
            
            switch self.currentState {
            case .open:
                self.bottomConstraint.constant = 0
            case .closed:
                self.bottomConstraint.constant = self.visibleHeight
            }
            
            self.lineArrowShapeLayer?.completeAnimation(for: self.currentState)
            self.completionClosure(self.currentState)
            
            self.runningAnimators.removeAll()
        }
        
        transitionAnimator.startAnimation()
        runningAnimators += [transitionAnimator]
    }
    
    @objc private func drawerViewGestureTappedOut(recognizer: UITapGestureRecognizer) {
        guard closeOnBlurTapped else { return }
        animateTransitionIfNeeded(to: .closed, duration: animationDuration)
    }
    
    @objc private func drawerViewGestureTapped(recognizer: UITapGestureRecognizer) {
        guard closeOnDrawerTaps else { return }
        let state = currentState.opposite
        animateTransitionIfNeeded(to: state, duration: animationDuration)
    }
    
    @objc private func drawerViewGesturePanned(recognizer: UIPanGestureRecognizer) {
        
        // Discard all gestures that are propagated from the child views
        let tapLocation = recognizer.location(in: self)
        let containsLocationPoint = self.layer.presentation()?.frame.contains(tapLocation)
        
        if let containsLocationPoint = containsLocationPoint, containsLocationPoint, !closeOnChildViewTaps {
            return
        }
        
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

private extension DrawerView {
    
    func setupConstraints() {
        guard let superview = self.superview else { return }
        
        translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
        
        bottomConstraint = bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: currentState == .closed ? visibleHeight : 0.0)
        bottomConstraint.isActive = true
        
        customHeightAnchor = heightAnchor.constraint(equalToConstant: topLayoutGuidePadding)
        customHeightAnchor.isActive = true
    }
    
    func resolveLayoutChanges() {
        guard sholdRecalculateConstraints, let superview = self.superview else { return }
        let newHeight = superview.bounds.height - topLayoutGuidePadding
        
        visibleHeight = newHeight - closedHeight
        bottomConstraint.constant = visibleHeight
        customHeightAnchor.constant = newHeight
        superview.layoutIfNeeded()
        
        if lineArrowShapeLayer != nil {
            // Update the bounds of the list arrow shape layer view
            lineArrowShapeLayer?.calculateBounds(from: bounds)
            lineArrowShapeLayer?.update()
        }
        
        sholdRecalculateConstraints = false
    }
}

extension DrawerView : UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        for subview in subviews {
            guard let subview = subview as? DrawerViewTouchHandling else { continue }
            if subview.drawerViewIntercepts(touch: touch) { return false }
        }
        return true
    }
}
