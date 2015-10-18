//
//  VerticalSplitViewController.swift
//  VerticalSplitView
//
//  Created by MiyakeAkira on 2015/10/18.
//  Copyright © 2015年 MiyakeAkira. All rights reserved.
//

import UIKit
import SwiftyEvents


public enum DisplayState {
    case Both
    case Top
    case Bottom
}

public enum DisplayStateEvent {
    case WillUpdate
    case DidUpdate
}

public class DisplayStateEventEmitter: EventEmitter<DisplayStateEvent, DisplayState> {
    
    public internal (set) var displayState: DisplayState {
        willSet {
            if displayState != newValue {
                emit(.WillUpdate, value: displayState)
            }
        }
        didSet {
            if displayState != oldValue {
                emit(.DidUpdate, value: displayState)
            }
        }
    }
    
    public init(displayState: DisplayState) {
        self.displayState = displayState
        
        super.init()
    }
    
}


public enum IsAnimatingEvent {
    case WillUpdate
    case DidUpdate
}

public class IsAnimatingEventEmitter: EventEmitter<IsAnimatingEvent, Bool> {
    
    public var isAnimating: Bool {
        willSet {
            if isAnimating != newValue {
                emit(.WillUpdate, value: isAnimating)
            }
        }
        didSet {
            if isAnimating != oldValue {
                emit(.DidUpdate, value: isAnimating)
            }
        }
    }
    
    public init(isAnimating: Bool) {
        self.isAnimating = isAnimating
        
        super.init()
    }
    
}



public class VerticalSplitViewController: UIViewController {
    
    // MARK: - Event emitter
    
    public let displayStateEventEmitter: DisplayStateEventEmitter
    public let isAnimatingEventEmitter: IsAnimatingEventEmitter
    
    
    // MARK: - State
    
    public var displayState: DisplayState {
        return displayStateEventEmitter.displayState
    }
    
    public var isAnimating: Bool {
        return isAnimatingEventEmitter.isAnimating
    }
    
    public private (set) var isInitialize: Bool
    
    
    // MARK: - Child view controllers
    
    public var topViewController: UIViewController {
        didSet {
            removeChildViewController(oldValue)
            setChildViewController(topViewController)
        }
    }
    
    public var bottomViewController: UIViewController {
        didSet {
            removeChildViewController(oldValue)
            setChildViewController(bottomViewController)
        }
    }
    
    
    // MARK: - Gesture
    
    private var panGestureRecognizer: UIPanGestureRecognizer?
    private var panGestureTranslation: CGPoint
    
    
    // MARK: - Initialize
    
    public init(topViewController: UIViewController, bottomViewController: UIViewController, viewState: DisplayState) {
        
        // Event emitter
        self.displayStateEventEmitter = DisplayStateEventEmitter(displayState: .Both)
        self.isAnimatingEventEmitter = IsAnimatingEventEmitter(isAnimating: false)
        
        // Child view controller
        self.topViewController = topViewController
        self.bottomViewController = bottomViewController
        
        // State
        self.isInitialize = false
        
        // Gesture
        panGestureTranslation = CGPointZero
        
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - View controller
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setChildViewController(topViewController)
        setChildViewController(bottomViewController)
        
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePanGestureRecognizer:")
        if let recognizer = panGestureRecognizer {
            view.addGestureRecognizer(recognizer)
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isInitialize {
            updateChildViewsLayout(displayState: displayState, animated: false)
            isInitialize = true
        }
    }
    
    
    // MARK: - Method
    
    private func setChildViewController(controller: UIViewController) {
        addChildViewController(controller)
        view.addSubview(controller.view)
        controller.didMoveToParentViewController(self)
    }
    
    private func removeChildViewController(controller: UIViewController) {
        controller.willMoveToParentViewController(nil)
        controller.view.removeFromSuperview()
        controller.removeFromParentViewController()
    }
    
    private func updateChildViewsLayout(displayState displayState: DisplayState, animated: Bool) {
        let width: CGFloat = view.frame.size.width
        let height: CGFloat = view.frame.size.height
        
        let topViewFrame: CGRect
        let bottomViewFrame: CGRect
        
        switch displayState {
        case .Both:
            topViewFrame = CGRectMake(0, 0, width, height / 2)
            bottomViewFrame = CGRectMake(0, height / 2, width, height / 2)
        case .Top:
            topViewFrame = CGRectMake(0, 0, width, height)
            bottomViewFrame = CGRectMake(0, height, width, 0)
        case .Bottom:
            topViewFrame = CGRectMake(0, 0, width, 0)
            bottomViewFrame = CGRectMake(0, 0, width, height)
        }
        
        if animated {
            isAnimatingEventEmitter.isAnimating = true
            
            UIView.animateWithDuration(
                0.5,
                delay: 0,
                usingSpringWithDamping: 0.6,
                initialSpringVelocity: 0.3,
                options: .CurveEaseOut,
                animations: { () -> Void in
                    self.topViewController.view.frame = topViewFrame
                    self.bottomViewController.view.frame = bottomViewFrame
                },
                completion: { (completion) -> Void in
                    self.displayStateEventEmitter.displayState = displayState
                    self.isAnimatingEventEmitter.isAnimating = false
                })
        } else {
            topViewController.view.frame = topViewFrame
            bottomViewController.view.frame = bottomViewFrame
            
            displayStateEventEmitter.displayState = displayState
            isAnimatingEventEmitter.isAnimating = false
        }
    }
    
    private func updateChildViewsLayoutWithGestrue(difference difference: CGPoint) {
        let yDiff = difference.y
        
        let currentTopViewFrame = topViewController.view.frame
        let currentBottomViewFrame = bottomViewController.view.frame
        
        let topViewFrame: CGRect
        let bottomViewFrame: CGRect
        
        if yDiff > 0 && currentBottomViewFrame.height == 0 {
            topViewFrame = currentTopViewFrame
            bottomViewFrame = currentBottomViewFrame
        } else if yDiff < 0 && currentTopViewFrame.height == 0 {
            topViewFrame = currentTopViewFrame
            bottomViewFrame = currentBottomViewFrame
        } else {
            topViewFrame = CGRectMake(
                0,
                0,
                currentTopViewFrame.size.width,
                currentTopViewFrame.size.height + yDiff)
            
            bottomViewFrame = CGRectMake(
                0,
                currentBottomViewFrame.origin.y + yDiff,
                currentBottomViewFrame.size.width,
                currentBottomViewFrame.size.height - yDiff)
        }
        
        topViewController.view.frame = topViewFrame
        bottomViewController.view.frame = bottomViewFrame
    }
    
    
    // MARK: - Selector
    
    func handlePanGestureRecognizer(recognizer: UIPanGestureRecognizer) {
        enum Direction {
            case Top
            case None
            case Bottom
        }
        
        switch recognizer.state {
        case .Changed:
            let currentTranslation = recognizer.translationInView(view)
            let difference = CGPointMake(
                currentTranslation.x - panGestureTranslation.x,
                currentTranslation.y - panGestureTranslation.y)
            
            updateChildViewsLayoutWithGestrue(difference: difference)
            
            panGestureTranslation = currentTranslation
            
            isAnimatingEventEmitter.isAnimating = true
        case .Ended:
            let direction: Direction
            if recognizer.velocityInView(view).y > 0 {
                direction = .Top
            } else if recognizer.velocityInView(view).y < 0 {
                direction = .Bottom
            } else {
                direction = .None
            }
            
            switch displayState {
            case .Both:
                if panGestureTranslation.y > 0 && direction == .Top {
                    updateChildViewsLayout(displayState: .Top, animated: true)
                } else if panGestureTranslation.y < 0 && direction == .Bottom {
                    updateChildViewsLayout(displayState: .Bottom, animated: true)
                } else {
                    updateChildViewsLayout(displayState: .Both, animated: true)
                }
            case .Top:
                if panGestureTranslation.y < 0 && direction == .Bottom {
                    updateChildViewsLayout(displayState: .Both, animated: true)
                } else {
                    updateChildViewsLayout(displayState: .Top, animated: true)
                }
            case .Bottom:
                if panGestureTranslation.y > 0 && direction == .Top {
                    updateChildViewsLayout(displayState: .Both, animated: true)
                } else {
                    updateChildViewsLayout(displayState: .Bottom, animated: true)
                }
            }
            
            panGestureTranslation = CGPointZero
            recognizer.setTranslation(CGPointZero, inView: view)
        default:
            break
        }
    }
    
}
