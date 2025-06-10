//
//  ViewController.swift
//  NetworkDebuggingDemo
//
//  Created by Darshan Dodia on 30/05/25.
//

import UIKit

class ViewController: UIViewController {

    // MARK: - UI Elements
    
    private let dictionaryTitleLabel = UILabel()
    private let wordDisplayView = UIView()
    private let wordLabel = UILabel()
    private let definitionLabel = UILabel()
    private let wordTextField = UITextField()
    private let searchButton = UIButton()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI Setup

    private func setupUI() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.7, green: 0.15, blue: 0.15, alpha: 1.0).cgColor,
            UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0).cgColor,
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)

        dictionaryTitleLabel.text = "Dictionary"
        dictionaryTitleLabel.font = UIFont.boldSystemFont(ofSize: 42)
        dictionaryTitleLabel.textAlignment = .center
        dictionaryTitleLabel.textColor = .white
        view.addSubview(dictionaryTitleLabel)

        wordDisplayView.backgroundColor = UIColor(red: 0.98, green: 0.9, blue: 0.9, alpha: 0.95)
        wordDisplayView.layer.cornerRadius = 16
        view.addSubview(wordDisplayView)

        // Default text
        wordLabel.text = "Name"
        wordLabel.font = UIFont.boldSystemFont(ofSize: 28)
        wordLabel.textColor = .systemBlue
        wordDisplayView.addSubview(wordLabel)

        // Default text
        definitionLabel.text = "What's in a name?"
        definitionLabel.font = UIFont.systemFont(ofSize: 20)
        definitionLabel.textColor = .black
        definitionLabel.numberOfLines = 0
        wordDisplayView.addSubview(definitionLabel)

        wordTextField.placeholder = "Type a word"
        wordTextField.borderStyle = .roundedRect
        wordTextField.font = UIFont.italicSystemFont(ofSize: 20)
        wordTextField.backgroundColor = .white
        wordTextField.textColor = .black
        view.addSubview(wordTextField)

        searchButton.setTitle("Search", for: .normal)
        searchButton.backgroundColor = .systemBlue
        searchButton.setTitleColor(.white, for: .normal)
        searchButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        searchButton.layer.cornerRadius = 16
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        view.addSubview(searchButton)

        // MARK: - Auto Layout Constraints

        // Disable autoresizing masks for programmatic Auto Layout
        dictionaryTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        wordDisplayView.translatesAutoresizingMaskIntoConstraints = false
        wordLabel.translatesAutoresizingMaskIntoConstraints = false
        definitionLabel.translatesAutoresizingMaskIntoConstraints = false
        wordTextField.translatesAutoresizingMaskIntoConstraints = false
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Dictionary Title Label Constraints
            dictionaryTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 140),
            dictionaryTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dictionaryTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dictionaryTitleLabel.heightAnchor.constraint(equalToConstant: 40),

            // Word Display View Constraints
            wordDisplayView.bottomAnchor.constraint(equalTo: wordTextField.bottomAnchor, constant: -80),
            wordDisplayView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            wordDisplayView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            wordDisplayView.heightAnchor.constraint(equalToConstant: 250), // Fixed height for the box

            // Word Label Constraints (inside wordDisplayView)
            wordLabel.topAnchor.constraint(equalTo: wordDisplayView.topAnchor, constant: 20),
            wordLabel.leadingAnchor.constraint(equalTo: wordDisplayView.leadingAnchor, constant: 20),
            wordLabel.trailingAnchor.constraint(equalTo: wordDisplayView.trailingAnchor, constant: -20),

            // Definition Label Constraints (inside wordDisplayView)
            definitionLabel.topAnchor.constraint(equalTo: wordLabel.bottomAnchor, constant: 10),
            definitionLabel.leadingAnchor.constraint(equalTo: wordDisplayView.leadingAnchor, constant: 20),
            definitionLabel.trailingAnchor.constraint(equalTo: wordDisplayView.trailingAnchor, constant: -20),
            definitionLabel.bottomAnchor.constraint(lessThanOrEqualTo: wordDisplayView.bottomAnchor, constant: -20),

            // Word Text Field Constraints
            wordTextField.bottomAnchor.constraint(equalTo: searchButton.topAnchor, constant: -20),
            wordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            wordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            wordTextField.heightAnchor.constraint(equalToConstant: 50),

            // Search Button Constraints
            searchButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            searchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            searchButton.widthAnchor.constraint(equalToConstant: 100),
            searchButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Actions

    @objc private func searchButtonTapped() {
        if let word = wordTextField.text, !word.isEmpty {
            print("[DictionaryApp] Searching for: \(word)")
            fetchDataWithPatchedConfig(for: word)
        } else {
            print("[DictionaryApp] Text field is empty.")
        }
    }
    
    private func fetchDataWithPatchedConfig(for word: String) {
            guard let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(word)") else {
                print("[DictionaryApp] Error: Invalid URL")
                return
            }

            let patchedConfig = NetworkDebugger.patchedConfiguration()
            let sessionWithPatchedConfig = URLSession(configuration: patchedConfig)

            let task = sessionWithPatchedConfig.dataTask(with: url) { [weak self] data, response, error in
                guard let self = self else { return }

                if let error = error {
                    print("[DictionaryApp] Network Error: \(error.localizedDescription)")

                    DispatchQueue.main.async {
                        self.wordLabel.text = "Error"
                        self.definitionLabel.text = "Could not fetch data: \(error.localizedDescription)"
                    }
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    print("Server Error: HTTP Status Code \(statusCode)")
                    DispatchQueue.main.async {
                        self.wordLabel.text = "Error"
                        self.definitionLabel.text = "Server responded with status code: \(statusCode)"
                    }
                    return
                }

                guard let data = data else {
                    print("[DictionaryApp] Error: No data received")
                    DispatchQueue.main.async {
                        self.wordLabel.text = "Error"
                        self.definitionLabel.text = "No data received from API."
                    }
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let definitions = try decoder.decode([WordDefinitionResponse].self, from: data)

                    // All UI updates MUST be performed on the main thread
                    DispatchQueue.main.async {
                        if let firstEntry = definitions.first {
                            self.wordLabel.text = firstEntry.word.capitalized
                            if let firstMeaning = firstEntry.meanings.first,
                               let firstDefinition = firstMeaning.definitions.first {
                                self.definitionLabel.text = firstDefinition.definition
                            } else {
                                self.definitionLabel.text = "No definition found."
                            }
                        } else {
                            self.wordLabel.text = "Not Found"
                            self.definitionLabel.text = "No dictionary entry for '\(word)'."
                        }
                    }
                } catch {
                    print("[DictionaryApp] Decoding Error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.wordLabel.text = "Error"
                        self.definitionLabel.text = "Failed to decode data: \(error.localizedDescription)"
                    }
                }
            }
            task.resume()
        }
}
