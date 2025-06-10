//
//  LogsTableViewController.swift
//  NetworkDebuggingDemo
//
//  Created by Darshan Dodia on 02/06/25.
//

import UIKit

class LogsTableViewController: UITableViewController {
    
    // MARK: - Properties

    private var calls: [NetworkCall] = []
    private var filteredCalls: [NetworkCall] = []

    private let searchController = UISearchController(searchResultsController: nil)
    private let buttonContainerView = UIView()
    private let combinedHeaderView = UIView()
    private var controlsStackView: UIStackView!

    // MARK: - Computed Properties

    var isSearchBarEmpty: Bool {
      return searchController.searchBar.text?.isEmpty ?? true
    }

    var isFiltering: Bool {
      return searchController.isActive && (!isSearchBarEmpty || searchController.searchBar.isFirstResponder)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupHeaderControls()
        setupNotificationObservers()
        
        // Initial setup for the tableHeaderView.
        // The width and height will be explicitly managed in viewDidLayoutSubviews.
        combinedHeaderView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableHeaderView = combinedHeaderView

        // Add a width constraint directly to the header view relative to the table view.
        // This constraint ensures the header view always matches the table view's width.
        // This is crucial for systemLayoutSizeFitting to work correctly.
        NSLayoutConstraint.activate([
            combinedHeaderView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            combinedHeaderView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
        ])

        loadLogs()
        definesPresentationContext = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableHeaderViewHeight()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Private Helpers (View Setup)

    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LogCell")
    }

    private func setupHeaderControls() {
        // Setup Button Bar Stack View
        controlsStackView = UIStackView()
        controlsStackView.axis = .horizontal
        controlsStackView.distribution = .fillEqually
        controlsStackView.spacing = 8
        controlsStackView.heightAnchor.constraint(equalToConstant: 30).isActive = true // Explicit height for stability

        let clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear All", for: .normal)
        clearButton.addTarget(self, action: #selector(clearLogsTapped), for: .touchUpInside)

        let refreshButton = UIButton(type: .system)
        refreshButton.setTitle("Refresh", for: .normal)
        refreshButton.addTarget(self, action: #selector(refreshLogs), for: .touchUpInside)

        controlsStackView.addArrangedSubview(clearButton)
        controlsStackView.addArrangedSubview(refreshButton)

        buttonContainerView.addSubview(controlsStackView)
        buttonContainerView.translatesAutoresizingMaskIntoConstraints = false
        controlsStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            controlsStackView.leadingAnchor.constraint(equalTo: buttonContainerView.leadingAnchor, constant: 16),
            controlsStackView.trailingAnchor.constraint(equalTo: buttonContainerView.trailingAnchor, constant: -16),
            controlsStackView.topAnchor.constraint(equalTo: buttonContainerView.topAnchor, constant: 8),
            controlsStackView.bottomAnchor.constraint(equalTo: buttonContainerView.bottomAnchor, constant: -8),
        ])

        // Setup Search Controller and Search Bar
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Filter by URL or Method"
        searchController.searchBar.delegate = self
        searchController.searchBar.translatesAutoresizingMaskIntoConstraints = false

        // Combine Button Container and Search Bar into combinedHeaderView
        combinedHeaderView.addSubview(buttonContainerView)
        combinedHeaderView.addSubview(searchController.searchBar)

        NSLayoutConstraint.activate([
            buttonContainerView.topAnchor.constraint(equalTo: combinedHeaderView.topAnchor),
            buttonContainerView.leadingAnchor.constraint(equalTo: combinedHeaderView.leadingAnchor),
            buttonContainerView.trailingAnchor.constraint(equalTo: combinedHeaderView.trailingAnchor),

            searchController.searchBar.topAnchor.constraint(equalTo: buttonContainerView.bottomAnchor),
            searchController.searchBar.leadingAnchor.constraint(equalTo: combinedHeaderView.leadingAnchor),
            searchController.searchBar.trailingAnchor.constraint(equalTo: combinedHeaderView.trailingAnchor),
            searchController.searchBar.bottomAnchor.constraint(equalTo: combinedHeaderView.bottomAnchor)
        ])
    }

    private func updateTableHeaderViewHeight() {
        // Ensure header view and table view width are valid
        guard let headerView = tableView.tableHeaderView, tableView.bounds.width > 0 else {
            return
        }

        var currentHeaderFrame = headerView.frame

        // Ensure the headerView's width matches the tableView's current bounds width.
        // This is crucial for systemLayoutSizeFitting to calculate height correctly.
        if abs(currentHeaderFrame.width - tableView.bounds.width) > 0.01 {
            currentHeaderFrame.size.width = tableView.bounds.width
            headerView.frame = currentHeaderFrame
        }

        // Force layout pass on the headerView to calculate its intrinsic height
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()

        let targetSize = CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let calculatedHeight = headerView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        // Only update if the calculated height is positive and significantly different
        if calculatedHeight > 0 && abs(currentHeaderFrame.size.height - calculatedHeight) > 0.01 {
            currentHeaderFrame.size.height = calculatedHeight
            headerView.frame = currentHeaderFrame
            // Re-assigning the header view is essential to trigger UITableView to update its layout
            tableView.tableHeaderView = headerView
        }
    }

    // MARK: - Private Helper Methods (Data and Filtering)

    private func loadLogs() {
        self.calls = NetworkLogger.shared.calls.sorted(by: { $0.timestamp > $1.timestamp })
        if isFiltering {
            filterContentForSearchText(searchController.searchBar.text ?? "")
        } else {
            tableView.reloadData()
        }
    }

    func filterContentForSearchText(_ searchText: String) {
        if searchText.isEmpty {
            filteredCalls = calls
        } else {
            let lowercasedSearchText = searchText.lowercased()
            filteredCalls = calls.filter { call in
                let urlMatch = call.request.url?.absoluteString.lowercased().contains(lowercasedSearchText) ?? false
                let methodMatch = call.request.httpMethod?.lowercased().contains(lowercasedSearchText) ?? false
                var statusMatch = false
                if let numSearch = Int(searchText), let httpResponse = call.response as? HTTPURLResponse {
                    statusMatch = httpResponse.statusCode == numSearch
                }
                return urlMatch || methodMatch || statusMatch
            }
        }
        tableView.reloadData()
    }

    // MARK: - Notification Handling

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNetworkCallLogged), name: .networkCallLogged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNetworkCallUpdated), name: .networkCallUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNetworkLogCleared), name: .networkLogCleared, object: nil)
    }

    @objc private func handleNetworkCallLogged() {
        DispatchQueue.main.async {
            self.loadLogs()
        }
    }

    @objc private func handleNetworkCallUpdated(notification: Notification) {
        DispatchQueue.main.async {
            self.loadLogs()
        }
    }

    @objc private func handleNetworkLogCleared() {
        DispatchQueue.main.async {
            self.calls.removeAll()
            self.filteredCalls.removeAll()
            self.tableView.reloadData()
        }
    }

    // MARK: - Interaction Handlers

    @objc private func clearLogsTapped() {
        NetworkLogger.shared.clearLogs()
    }

    @objc private func refreshLogs() {
        loadLogs()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltering ? filteredCalls.count : calls.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LogCell", for: indexPath)
        let call = isFiltering ? filteredCalls[indexPath.row] : calls[indexPath.row]

        var content = cell.defaultContentConfiguration()
        let method = call.request.httpMethod ?? "???"
        let urlPath = call.request.url?.pathComponents.dropFirst().joined(separator: "/") ?? (call.request.url?.host ?? "Unknown path")
        var statusString = ""
        var statusColor = UIColor.label

        if let httpResponse = call.response as? HTTPURLResponse {
            statusString = "\(httpResponse.statusCode)"
            if (200..<300).contains(httpResponse.statusCode) { statusColor = .systemGreen }
            else if (400..<500).contains(httpResponse.statusCode) { statusColor = .systemOrange }
            else if (500..<600).contains(httpResponse.statusCode) { statusColor = .systemRed }
            else { statusColor = .systemBlue }
        } else if call.error != nil {
            statusString = "Error 💔"; statusColor = .systemRed
        } else if call.response == nil {
            statusString = "Pending..."; statusColor = .systemGray
        }
            
        content.text = "\(method) /\(urlPath)"
        content.secondaryText = "\(statusString) - \(call.request.url?.host ?? "")"
        content.secondaryTextProperties.color = statusColor
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let call = isFiltering ? filteredCalls[indexPath.row] : calls[indexPath.row]
        let detailVC = LogDetailsViewController(call: call)
        let navController = UINavigationController(rootViewController: detailVC)
        self.parent?.present(navController, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UISearchResultsUpdating

extension LogsTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text ?? "")
    }
}

// MARK: - UISearchBarDelegate

extension LogsTableViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        tableView.reloadData()
    }
}
