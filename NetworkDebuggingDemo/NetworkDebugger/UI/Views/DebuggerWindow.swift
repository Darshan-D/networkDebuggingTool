//
//  DebuggerWindo.swift
//  NetworkDebuggingDemo
//
//  Created by Darshan Dodia on 02/06/25.
//

import UIKit

/// An additional UIWindow which will contain our debug overlay button
class DebuggerWindow: UIWindow {
    
    // MARK: Properties
    
    // Debug overlay button
    private var floatingButton: FloatingButton?
    
    // Reference to debug view controller
    private var mainDebuggerViewController: MainDebuggerViewController?

    // Internal view controller which displays the overlay button
    private lazy var internalRootViewController: UIViewController = {
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        return vc
    }()

    // MARK: Initializers

    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        // Set the window's level above the `.normal` level,
        // ensuring it appears on top of your main application's windows.
        windowLevel = .normal + 1
        backgroundColor = .clear

        rootViewController = internalRootViewController
        isUserInteractionEnabled = true
    }

    // MARK: APIs

    func setup() {
        if floatingButton == nil {
            floatingButton = FloatingButton()
            floatingButton?.tapAction = { [weak self] in
                self?.showDebuggerView()
            }

            // Add button to the internalRootViewController's view, not directly to the window.
            // This makes touch handling more standard.
            internalRootViewController.view.addSubview(floatingButton!)
            floatingButton?.frame.origin = CGPoint(x: UIScreen.main.bounds.width - 80 - safeAreaInsets.right,
                                                   y: 100 + safeAreaInsets.top)
        }

        // Ensure that everything is visible
        self.isHidden = false
        floatingButton?.isHidden = false
        print("[DebuggerWindow][setup]: Setup complete. Floating button added.")
    }

    func showDebuggerView() {        
        guard internalRootViewController.presentedViewController == nil else {
            // Avoid presenting multiple times
            print("[DebuggerWindow][showDebuggerView]: Debugger view already (or is being) presented.")
            return
        }

        if mainDebuggerViewController == nil {
            mainDebuggerViewController = MainDebuggerViewController()
            mainDebuggerViewController!.modalPresentationStyle = .overFullScreen
        }

        guard let vcToPresent = mainDebuggerViewController else {
            return
        }

        floatingButton?.isHidden = true
        internalRootViewController.present(vcToPresent, animated: true)
    }

    func dismissDebuggerView() {
        mainDebuggerViewController?.dismiss(animated: true)
        floatingButton?.isHidden = false
    }

    // MARK: Overrides

    /// Determine who should process the tap
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Case - If the MainDebuggerViewController is presented by our internalRootViewController
        if internalRootViewController.presentedViewController != nil {
            // Let the presented view controller (and its children) decide.
            // The touch is within the bounds of this window, so super.point(inside:with:) will pass it to internalRootViewController.
            // The window should process the touch.
            return true
        }

        // Case - If the MainDebuggerViewController is NOT presented, check if the touch is on the floating button.
        if let button = floatingButton, !button.isHidden {
            // Convert point to the button's superview's coordinate system (which is internalRootViewController.view)
            let pointInButtonSuperview = convert(point, to: button.superview)
            if button.frame.contains(pointInButtonSuperview) {
                // Touch is on the button.
                return true
            }
        }
        
        // Case - Otherwise, the touch is not for this window's active UI.
        // Pass the touch to windows below.
        return false
    }
}
