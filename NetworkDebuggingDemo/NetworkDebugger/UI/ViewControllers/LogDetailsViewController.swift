//
//  LogDetailsViewController.swift
//  NetworkDebuggingDemo
//
//  Created by Darshan Dodia on 02/06/25.
//

import Foundation
import UIKit

class LogDetailsViewController: UIViewController {

    // MARK: - Properties

    private let call: NetworkCall
    private let textView = UITextView()
    private let segmentedControl = UISegmentedControl(items: ["Request", "Response", "cURL"])

    // MARK: - Inits

    init(call: NetworkCall) {
        self.call = call
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViewAppearance()
        setupNavigationBar()
        setupSegmentedControl()
        setupTextView()
        addSubviews()
        setupConstraints()

        updateTextViewContent()
    }

    // MARK: - UI Setup Methods

    private func setupViewAppearance() {
        view.backgroundColor = .systemBackground
        title = "Call Details"
    }

    private func setupNavigationBar() {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        navigationItem.rightBarButtonItem = doneButton

        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped))
        navigationItem.leftBarButtonItem = shareButton
    }

    private func setupSegmentedControl() {
        segmentedControl.selectedSegmentIndex = 0 // Default to "Request"
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }

    private func setupTextView() {
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    }

    private func addSubviews() {
        view.addSubview(segmentedControl)
        view.addSubview(textView)
    }

    private func setupConstraints() {
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            textView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
    }

    // MARK: - Interaction Handlers

    @objc private func segmentChanged() {
        updateTextViewContent()
    }

    @objc private func doneTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func shareTapped() {
        let textToShare = textView.text ?? "No content to share."
        let activityViewController = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }

    // MARK: - Private Helpers

    private func updateTextViewContent() {
        switch segmentedControl.selectedSegmentIndex {
        case 0: // Request
            var requestText = call.request.prettyDescription
            if let body = call.request.httpBody {
                requestText += "\nBody (Raw Data): \(body.count) bytes"
            }
            textView.text = requestText
        case 1: // Response
            var responseText = call.response?.prettyDescription ?? "No Response"
            if let error = call.error {
                responseText += "\nError: \(error.localizedDescription)"
            }
            if let responseBody = call.responseBodyString {
                responseText += "\nBody:\n\(responseBody)"
            } else if let responseData = call.responseData, !responseData.isEmpty {
                responseText += "\nBody (Raw Data): \(responseData.count) bytes"
            } else if call.response != nil && call.responseData == nil {
                responseText += "\nBody: (Empty)"
                print("[LogDetailsViewController][updateTextViewContent] Response body is empty.")
            }
            textView.text = responseText
        case 2: // cURL
            textView.text = call.curlRepresentation
        default:
            textView.text = ""
            print("[LogDetailsViewController][updateTextViewContent] Unexpected segment index. Clearing text view.")
        }
    }
}
