//
//  DrawerView.swift
//  SideDrawer
//
//  Created by Astemir Eleev on 26/11/2018.
//  Copyright © 2018 Astemir Eleev. All rights reserved.
//  Modified by Mitchell Tucker on 3/10/2020 under the MIT license agreement

import UIKit

// DrawerView UI Component. Intended to be a part of an another UIView and present additional view when needed. The view is not @IBDesignable since there is nothing to present (custom) in the interface builder. However, some properties are @IBInspectable, so you are able to adjust them at design time (in case if you use interface builder).
public class SideDrawerView: UIView {
    
    public enum State {
        case closed
        case open
    }
    
    /// Currently not used
    //public enum Side {
    //    case leading
    //    case trailing
    //}
    
    // MARK: - Public properties
    
    public var closedWidth:CGFloat
    public private(set) var visibleWidth: CGFloat
    public let blurStyle: UIBlurEffect.Style

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

    /// The component will change drawer orientation behavior by keeping aspect ratio by switching height/width
    @IBInspectable public var flipHeightWidthOnRotation         = true
    
    /// The component will give the user haptic feedback at after state change
    @IBInspectable public var givesHapticFeedback               = true
    
    /// The component will change drawer animation duration in seconds
    @IBInspectable public var animationDuration: TimeInterval   = 0.5
    @IBInspectable public var animationDampingRatio: CGFloat    = 1.0
    
    /// The component will change drawer corner radius
    @IBInspectable public var cornerRadius: CGFloat             = 20.0
    
    /// Use this close if you want to animate any other UIKit related component alongside with this component
    public var animationClosure:        (_ state: State)->() = { _ in }
    /// Use this cloure if you want to get animation completion callbacks
    public var completionClosure:       (_ state: State)->() = { _ in }
    /// Use this clossure if you want to get callbacks when State changes
    public var onStateChangeClosure:    (_ state: State)->() = { _ in }
    /// Use this clossure if you want to get callbacks on orientation change
    public var onOrientaitonChange: (_ orientation: UIDeviceOrientation )->() = { _ in}
    // MARK: - Private properties
    
    /// height of drawer
    private var drawerHeight:CGFloat? = nil
    private var currentOrintation = UIDevice.current.orientation
    /// Drawer Constraints
    private var customHeightAnchor = NSLayoutConstraint()
    private var customWidthAnchor = NSLayoutConstraint()
    private var leadingConstraint = NSLayoutConstraint()
    
    private var shouldRecalculateConstraints = false
    
    private lazy var hapticFeedback: UIImpactFeedbackGenerator = {
        return UIImpactFeedbackGenerator(style: UIImpactFeedbackGenerator.FeedbackStyle.medium)
    }()
    
    /// Holds all the running animators
    private var runningAnimators = [UIViewPropertyAnimator]()
    
    /// Holds propgresses of each animator
    private var animationProgress = [CGFloat]()
    
    // Gestures Recognizers
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
    
    // MARK: - SubLayers And Views
    private var lineArrowShapeLayer: LineArrowShapeLayer?
    private var blurView: UIVisualEffectView?
    private var handleView: UIView?
    private var superView:UIView?
    private var contentView: UIView? // view to add subviews
    private var subContentView: UIView?
    private var lineArrow:(height: CGFloat, width: CGFloat, color: UIColor)?
    private let drawerBackgroundColor:UIColor?
    
    // MARK: - Layout behavior
    private let useSafeAreaLayoutGuide:Bool?
    private let useTopSafeArea:Bool?
    private let setContentInSafeArea:Bool?
    //private var drawerSide: Side? // will be used in future update
    
    
    // MARK: - Initializers
    
    /// A designated initialier for DrawerView. Use initializer to create a new instnace of a DrawerView. Note that the view will add itself to the super view and must not do that manually. A typical use-case of this class it to instantiate a variable or property and optionally use closures to animate UIKit related contnet alongside with the DrawerView.
    public init(drawerHandleWidth: CGFloat = 25,
                drawerHeight:CGFloat = 50, // this changes based on orientation `drawerSize`
                flipHeightWidthOnRotation:Bool = true,
                
                useSafeAreaLayoutGuide:Bool = true,
                useTopSafeArea:Bool = true,
                setContentInSafeArea:Bool = true,
                
                blurStyle: UIBlurEffect.Style = UIBlurEffect.Style.regular,
                lineArrow: (height: CGFloat, width: CGFloat, color: UIColor)? = (20, 4, UIColor.systemBlue),
                drawerBackgroundColor:UIColor = .clear,
                
                superView: UIView) {
        
        

        self.visibleWidth = drawerHandleWidth
        self.drawerHeight = drawerHeight
        
        self.useSafeAreaLayoutGuide = useSafeAreaLayoutGuide
        self.useTopSafeArea = useTopSafeArea
        self.setContentInSafeArea = setContentInSafeArea
        
        self.flipHeightWidthOnRotation = flipHeightWidthOnRotation
        self.blurStyle = blurStyle
        self.drawerBackgroundColor = drawerBackgroundColor
        self.lineArrow = lineArrow
        self.superView = superView
        
        self.closedWidth = superView.bounds.width /// drawer will be
        
        super.init(frame: .zero)
        
        superView.addSubview(self)
        setupConstraints()
   
        // Setup visuals
        self.backgroundColor = drawerBackgroundColor // keep .clear for blur effect
        // Create and add blurEffectView to drawer
        let blurEffect = UIBlurEffect(style: blurStyle)
        blurView = UIVisualEffectView(effect:blurEffect)
        blurView!.frame = self.bounds // match drawer bounds
        blurView!.layer.cornerRadius = cornerRadius
        blurView!.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        blurView!.clipsToBounds = true
        self.addSubview(blurView!)
        
        // set up contentView used to correctly layout content displayed in drawer
        contentView = UIView(frame: .init(x: 0, y: 0, width: frame.width, height: drawerHeight))
        self.addSubview(contentView!)

        contentView!.translatesAutoresizingMaskIntoConstraints = false
        let topConstraint = contentView!.topAnchor.constraint(equalTo: self.topAnchor)
        let bottomConstraint = contentView!.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        let leadingConstraint = contentView!.leadingAnchor.constraint(equalTo: self.leadingAnchor)
        let trailingConstraint = contentView!.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -visibleWidth) // subtrack visibleWidth

        NSLayoutConstraint.activate([topConstraint,bottomConstraint,leadingConstraint,trailingConstraint])
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange(notification:)), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// In some cases (seems to depend on the view (controller) hierarchy) on has to call this function BEFORE the first animation to make it look right.

    /// Otherwise it may look like the component is expanding from the origin of its superview instead of appearing from the bottom.
    public func setInitial(frame: CGRect) {
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
    
    public func change(state: SideDrawerView.State, shouldAnimate: Bool = true) {
        let animationDuration = shouldAnimate ? self.animationDuration : 0.0
        animateTransitionIfNeeded(to: state, duration: animationDuration)
    }
    
    // MARK: - setContentView
    /// Paramters: UIView - View to be added as subview of content view
    /// Sets `view`constraints anchors to `contentView` anchors
    public func setContentView(view:UIView){
        subContentView = view
        contentView!.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false // important
        let bottomConstraint = view.bottomAnchor.constraint(equalTo: contentView!.bottomAnchor)
        // check if usedSafeLayoutGuide
        var leadingConstraint = NSLayoutConstraint()
        var trailingConstraint = NSLayoutConstraint()
        var topConstraint = NSLayoutConstraint()
        if setContentInSafeArea! {// sets content view within safeArea
            trailingConstraint = view.trailingAnchor.constraint(equalTo: contentView!.safeAreaLayoutGuide.trailingAnchor)
            leadingConstraint = view.leadingAnchor.constraint(equalTo: contentView!.safeAreaLayoutGuide.leadingAnchor)
            topConstraint = view.topAnchor.constraint(equalTo: contentView!.safeAreaLayoutGuide.topAnchor)
        }else{
            trailingConstraint = view.trailingAnchor.constraint(equalTo: contentView!.trailingAnchor)
            topConstraint = view.topAnchor.constraint(equalTo: contentView!.topAnchor)
            leadingConstraint = view.leadingAnchor.constraint(equalTo: contentView!.leadingAnchor)
        }
        

        NSLayoutConstraint.activate([topConstraint,bottomConstraint,leadingConstraint,trailingConstraint])
    }
    
    @objc private func orientationDidChange(notification: Notification) {
        runningAnimators.forEach { $0.continueAnimation(withTimingParameters: nil, durationFactor: 0) }
        self.onOrientaitonChange(UIDevice.current.orientation)
        if closeOnRotation {
            currentState = .closed
        }
        switch UIDevice.current.orientation{
        case .portrait:
            self.customWidthAnchor.constant = self.superview!.bounds.width
            self.customHeightAnchor.constant = drawerHeight!
            currentOrintation = UIDevice.current.orientation
        case .landscapeLeft:
            self.customWidthAnchor.constant = drawerHeight!
            self.customHeightAnchor.constant = self.superview!.bounds.width
            currentOrintation = UIDevice.current.orientation
        case .landscapeRight:
            self.customWidthAnchor.constant = drawerHeight!
            self.customHeightAnchor.constant = self.superview!.bounds.width
            currentOrintation = UIDevice.current.orientation
        case .portraitUpsideDown: // only works on some devices

            if self.superview!.bounds.width > self.superview!.bounds.height{
                print("Device dosent support orintation `portraitUpsideDown`")
            }else{
                self.customWidthAnchor.constant = self.superview!.bounds.width
                self.customHeightAnchor.constant = drawerHeight!
                currentOrintation = UIDevice.current.orientation
            }
        default:
            return // dont react to orientation change
        }

        shouldRecalculateConstraints = true
    }
    
    private func animateTransitionIfNeeded(to state: State, duration: TimeInterval) {
        guard runningAnimators.isEmpty else { return }
        // view animation from open to closed position
        let transitionAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: animationDampingRatio, animations: {
            switch state {
            case .open:
                self.leadingConstraint.constant = 0
                self.layer.cornerRadius = 0.0
                self.blurView?.layer.cornerRadius = 0.0
            case .closed:
                if self.useSafeAreaLayoutGuide! && self.currentOrintation == .landscapeLeft {
                    let window = UIApplication.shared.keyWindow
                    let leadingPadding = window?.safeAreaInsets.left ?? 0
                    self.leadingConstraint.constant = -self.closedWidth + (self.visibleWidth + leadingPadding)
                }else{
                    self.leadingConstraint.constant = -self.closedWidth + self.visibleWidth
                }
                self.layer.cornerRadius = self.cornerRadius
                self.blurView?.layer.cornerRadius = self.cornerRadius
            }

            self.lineArrowShapeLayer?.animate(for: state)
            self.animationClosure(state)
            
            self.superview?.layoutIfNeeded()
        })
        // completion state of the animation
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
                    self.leadingConstraint.constant = 0
                    
                case .closed:
                    // check if safeLayout is used and landscape left
                    // landscape left used for devices with a indented top screen ie Iphone X
                    if self.useSafeAreaLayoutGuide! && self.currentOrintation == .landscapeLeft {
                        let window = UIApplication.shared.keyWindow
                        let leadingPadding = window?.safeAreaInsets.left ?? 0
                        self.leadingConstraint.constant = -self.closedWidth + (self.visibleWidth + leadingPadding)
                    }else{
                        self.leadingConstraint.constant = -self.closedWidth + self.visibleWidth
                    }
            }
            self.lineArrowShapeLayer?.completeAnimation(for: self.currentState)
            self.completionClosure(self.currentState)
            
            self.runningAnimators.removeAll()
        }
        transitionAnimator.startAnimation()
        runningAnimators += [transitionAnimator]
    }
    
    // MARK: Gestures
    /// NOTE tap/touch gesture orginates from `TouchView`
    @objc private func drawerViewGestureTapped(recognizer: UITapGestureRecognizer) {
        let state = currentState.opposite
        animateTransitionIfNeeded(to: state, duration: animationDuration)
    }
    
    @objc private func drawerViewGesturePanned(recognizer: UIPanGestureRecognizer) {

        switch recognizer.state {
        case .began:
            animateTransitionIfNeeded(to: currentState.opposite, duration: animationDuration)
            runningAnimators.forEach { $0.pauseAnimation() }
            animationProgress = runningAnimators.map { $0.fractionComplete }
            
        case .changed:
            
            var leadingPadding:CGFloat = 0.0
            if useSafeAreaLayoutGuide! {
                let window = UIApplication.shared.keyWindow
                leadingPadding = window?.safeAreaInsets.left ?? 0
            }
            let translation = recognizer.translation(in: self)
            var fraction = translation.x / (self.bounds.width - (visibleWidth + leadingPadding))
            
            if currentState == .open { fraction *= -1 }
            if runningAnimators[0].isReversed { fraction *= -1 }
            
            for (index, animator) in runningAnimators.enumerated() {
                animator.fractionComplete = fraction + animationProgress[index]
            }
        case .ended:
            let xVelocity = recognizer.velocity(in: self).x
            let shouldClose = xVelocity < 0
            
            @inline(__always) func continueRunningAnimators() {
                runningAnimators.forEach { $0.continueAnimation(withTimingParameters: nil, durationFactor: 0) }
            }
            
            // if there is no motion, continue all animations and exit early
            if xVelocity == 0 {
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
    var hasInit = false
}

private extension SideDrawerView {
    
    func setupConstraints() {

        guard let superview = self.superview else { return }
        
        translatesAutoresizingMaskIntoConstraints = false

        /// Set up top anchor
        if useTopSafeArea! {
            topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor,constant: 0).isActive = true
        }else{
            topAnchor.constraint(equalTo: superview.topAnchor,constant: 0).isActive = true
        }
        
        // Trailing constraint does dynamiclly move
        leadingConstraint = leadingAnchor.constraint(equalTo: superview.leadingAnchor ,constant: currentState == .closed ? -closedWidth + visibleWidth : 0.0)
        leadingConstraint.isActive = true

        // set up height and width constraints
        customWidthAnchor = widthAnchor.constraint(equalToConstant: closedWidth)
        customWidthAnchor.isActive = true
        
        customHeightAnchor = heightAnchor.constraint(equalToConstant:drawerHeight!)
        customHeightAnchor.isActive = true
        
    }
    
    // MARK: - ResolveLayoutChanges
    
    func resolveLayoutChanges() {
        guard shouldRecalculateConstraints, let superview = self.superview else { return }
        
        shouldRecalculateConstraints = false
        var heightChange = drawerHeight!
        let window = UIApplication.shared.keyWindow
        let leadingPadding = window?.safeAreaInsets.left ?? 0
        
        if UIDevice.current.orientation.isLandscape{
            // using safe area
            // used for useContentSaveArea
            if useSafeAreaLayoutGuide! || self.setContentInSafeArea!{
                // check if orientation is landscape right
                if (drawerHeight! + leadingPadding) > self.superview!.bounds.width {
                        self.closedWidth = drawerHeight! - leadingPadding
                    }else{
                        self.closedWidth = drawerHeight! + leadingPadding
                }
            }else{
                self.closedWidth = drawerHeight!
            }
            
            // could check if in landscape Right there will be no gap
            if useSafeAreaLayoutGuide! && self.currentOrintation == .landscapeLeft {
                // sub leading padding from width in landscape |     | <--
                self.closedWidth = drawerHeight!
            }
            
            // check if width height should be flipped
            if flipHeightWidthOnRotation {
                heightChange = superview.bounds.height
                customWidthAnchor.constant = self.closedWidth
                customHeightAnchor.constant = heightChange
            }else{
                customWidthAnchor.constant = self.closedWidth
                customHeightAnchor.constant = drawerHeight!
            }
            
        }else if UIDevice.current.orientation.isPortrait {
            self.closedWidth = superview.bounds.width
            customWidthAnchor.constant = self.closedWidth
            customHeightAnchor.constant = drawerHeight!
        }
        
        if currentState == .closed {
            self.layer.cornerRadius = self.cornerRadius
            self.blurView?.layer.cornerRadius = self.cornerRadius
            if useSafeAreaLayoutGuide! && UIDevice.current.orientation == .landscapeLeft {
                leadingConstraint.constant = -self.closedWidth + (visibleWidth + leadingPadding) // include safe Area Padding
            }else{
                leadingConstraint.constant = -self.closedWidth + visibleWidth
            }
        }else{
            leadingConstraint.constant = 0
        }
        
        superview.layoutIfNeeded()
        
        /// Create a view to act has touch area
        if handleView != nil{
            handleView!.removeFromSuperview()
        }

        let newX = self.bounds.maxX - visibleWidth 
        handleView = UIView(frame: .init(x: newX, y: self.bounds.minY, width: visibleWidth , height: heightChange))
        
        /// add gestureRecognizers
        handleView!.addGestureRecognizer(panGesture)
        handleView!.addGestureRecognizer(tapGesture)
        /// touchView background color
        handleView!.backgroundColor = .clear
        
        self.addSubview(handleView!)
        //lineArrowShapeLayer?.removeFromSuperlayer() // not sure if needed
        
        lineArrowShapeLayer = LineArrowShapeLayer(height: self.lineArrow!.height,
                                                  width: self.lineArrow!.width,
                                                  color: self.lineArrow!.color)
        lineArrowShapeLayer!.animate(for: currentState)
        if lineArrowShapeLayer != nil {
            // Update the bounds of the list arrow shape layer view
            lineArrowShapeLayer?.calculateBounds(from: self.handleView!.bounds)
            lineArrowShapeLayer?.update()
        }
        handleView!.layer.addSublayer(lineArrowShapeLayer!)
    }
}

extension SideDrawerView : UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        for subview in subviews {
            guard let subview = subview as? DrawerViewTouchHandling else { continue }
            if subview.drawerViewIntercepts(touch: touch) { return false }
        }
        return true
    }
}
