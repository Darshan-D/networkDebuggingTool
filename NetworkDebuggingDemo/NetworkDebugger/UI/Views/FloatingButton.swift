//
//  FloatingButton.swift
//  NetworkDebuggingDemo
//
//  Created by Darshan Dodia on 02/06/25.
//

import Foundation
import UIKit

class FloatingButton: UIButton {
    
    // MARK: Properties

    var tapAction: (() -> Void)?

    // MARK: Inits

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        setupButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private Helpers

    private func setupButton() {
        backgroundColor = UIColor.systemYellow.withAlphaComponent(0.8)

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        if let settingsImage = UIImage(systemName: "gearshape", withConfiguration: symbolConfig) {
            setImage(settingsImage, for: .normal)
            tintColor = .black
            imageView?.contentMode = .scaleAspectFit
        } else {
            setTitle("⚙️", for: .normal)
            titleLabel?.font = .systemFont(ofSize: 24)
            setTitleColor(.white, for: .normal)
            print("[FloatingButton][setupButton]: SF Symbol 'gearshape' not found. Using fallback text.")
        }
 
        layer.cornerRadius = 20
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 5
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 3)

        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedButton(_:)))
        addGestureRecognizer(panGesture)
    }

    // MARK: Interaction Handlers

    @objc private func buttonTapped() {
        tapAction?()
    }

    /// Place the button wherever user places it
    @objc private func draggedButton(_ sender: UIPanGestureRecognizer) {
        guard let buttonView = sender.view, let superview = buttonView.superview else { return }
        let translation = sender.translation(in: superview)
        
        var newCenter = CGPoint(x: buttonView.center.x + translation.x,
                                y: buttonView.center.y + translation.y)

        // Keep within bounds of superview (window)
        let halfWidth = buttonView.bounds.width / 2
        let halfHeight = buttonView.bounds.height / 2
        let superviewBounds = superview.bounds.inset(by: superview.safeAreaInsets)


        newCenter.x = max(superviewBounds.minX + halfWidth, newCenter.x)
        newCenter.x = min(superviewBounds.maxX - halfWidth, newCenter.x)
        newCenter.y = max(superviewBounds.minY + halfHeight, newCenter.y)
        newCenter.y = min(superviewBounds.maxY - halfHeight, newCenter.y)

        buttonView.center = newCenter
        sender.setTranslation(.zero, in: superview)
    }
}
