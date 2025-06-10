//
//  MainDebuggerViewController.swift
//  NetworkDebuggingDemo
//
//  Created by Darshan Dodia on 02/06/25.
//

import Foundation
import UIKit

class MainDebuggerViewController: UIViewController {
    
    // MARK: Properties
    
    private let segmentedControl = UISegmentedControl(items: ["Logs", "Mocks"])
    private let logsVC = LogsTableViewController()
    private let mocksVC = MocksTableViewController()
    private var currentViewController: UIViewController?
    
    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupSegmentedControl()
        setupCloseButton()
        displayContentController(for: 0)
    }

    // MARK: Private Helpers

    private func setupCloseButton() {
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .systemGray
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupSegmentedControl() {
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        
        view.addSubview(segmentedControl)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    // MARK: Interaction Handlers

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        displayContentController(for: sender.selectedSegmentIndex)
    }
    

    @objc private func closeTapped() {
        // The MainDebuggerVC's view's window should be the DebuggerWindow
        if let debuggerWindow = self.view.window as? DebuggerWindow {
            debuggerWindow.dismissDebuggerView()
        } else {
            // This might happen if presentation context is unexpected.
            print("[MainDebuggerViewController][closeTapped]: Could not find DebuggerWindow, attempting direct dismiss.")
            self.dismiss(animated: true, completion: nil)
        }
    }

    private func displayContentController(for index: Int) {
        currentViewController?.willMove(toParent: nil)
        currentViewController?.view.removeFromSuperview()
        currentViewController?.removeFromParent()

        switch index {
        case 0:
            currentViewController = logsVC
        case 1:
            currentViewController = mocksVC
        default:
            return
        }

        if let viewController = currentViewController {
            addChild(viewController)
            view.addSubview(viewController.view)
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                viewController.view.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
                viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            viewController.didMove(toParent: self)
        }
    }
}


