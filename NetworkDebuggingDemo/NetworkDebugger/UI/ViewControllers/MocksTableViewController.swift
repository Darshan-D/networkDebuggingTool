//
//  MocksTableViewController.swift
//  NetworkDebuggingDemo
//
//  Created by Darshan Dodia on 02/06/25.
//

import Foundation
import UIKit

class MocksTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    private var mocks: [Mock] {
        NetworkLogger.shared.mocks
    }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Mocks"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MockCell")
        setupHeaderView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // MARK: - Private Helper
    
    private func setupHeaderView() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44))
        let addButton = UIButton(type: .system)
        addButton.setTitle("Add Mock", for: .normal)
        addButton.addTarget(self, action: #selector(addMockTapped), for: .touchUpInside)
        
        headerView.addSubview(addButton)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            addButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            addButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])

        tableView.tableHeaderView = headerView
    }
    
    private func editMock(_ mock: Mock, at indexPath: IndexPath) {
        let alert = UIAlertController(title: "Edit Mock", message: "Update mock details.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "URL Pattern"; $0.text = mock.urlPattern }
        alert.addTextField { $0.placeholder = "HTTP Method (optional)"; $0.text = mock.httpMethod }
        alert.addTextField { $0.placeholder = "JSON File Name"; $0.text = mock.jsonFileName }
        alert.addTextField { $0.placeholder = "Status Code"; $0.text = "\(mock.statusCode)"; $0.keyboardType = .numberPad }

        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let pattern = alert?.textFields?[0].text, !pattern.isEmpty,
                  let fileName = alert?.textFields?[2].text, !fileName.isEmpty,
                  let statusCodeStr = alert?.textFields?[3].text, let statusCode = Int(statusCodeStr) else {
                print("[MocksTableViewController][editMock]: Error: Mock can't be saved!")
                return
            }
            
            let method = alert?.textFields?[1].text?.nilIfEmpty?.uppercased()

            var updatedMock = mock
            updatedMock.urlPattern = pattern
            updatedMock.httpMethod = method
            updatedMock.jsonFileName = fileName
            updatedMock.statusCode = statusCode
            
            NetworkLogger.shared.updateMock(updatedMock)
            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
        }

        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Interaction Handlers
    
    @objc func mockStateChanged(_ sender: UISwitch) {
        let index = sender.tag
        guard index < mocks.count else {
            return
        }

        var mockToUpdate = mocks[index]
        mockToUpdate.isEnabled = sender.isOn
        NetworkLogger.shared.updateMock(mockToUpdate) // This will trigger save
    }

    @objc private func addMockTapped() {
        // Present a form to add/edit a mock
        let alert = UIAlertController(title: "Add Mock", message: "Enter mock details.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "URL Pattern (e.g., /users)" }
        alert.addTextField { $0.placeholder = "HTTP Method (GET, POST - optional)" }
        alert.addTextField { $0.placeholder = "JSON File Name (e.g., users.json)" }
        alert.addTextField { $0.placeholder = "Status Code (e.g., 200)"; $0.keyboardType = .numberPad; $0.text = "200" }

        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let pattern = alert?.textFields?[0].text, !pattern.isEmpty,
                  let fileName = alert?.textFields?[2].text, !fileName.isEmpty,
                  let statusCodeStr = alert?.textFields?[3].text, let statusCode = Int(statusCodeStr)
            else {
                // Basic validation
                let errorAlert = UIAlertController(title: "Error", message: "URL Pattern, JSON File, and Status Code are required.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(errorAlert, animated: true)
                return
            }
            
            let method = alert?.textFields?[1].text?.nilIfEmpty?.uppercased()
            
            let newMock = Mock(urlPattern: pattern,
                               httpMethod: method,
                               jsonFileName: fileName,
                               statusCode: statusCode,
                               headers: ["Content-Type": "application/json"],
                               isEnabled: true)
            NetworkLogger.shared.addMock(newMock)
            self?.tableView.reloadData()
        }
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mocks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MockCell", for: indexPath)
        let mock = mocks[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = "\(mock.httpMethod ?? "ANY") - \(mock.urlPattern)"
        content.secondaryText = "File: \(mock.jsonFileName), Status: \(mock.statusCode)"
        
        let switchView = UISwitch()
        switchView.isOn = mock.isEnabled
        switchView.tag = indexPath.row
        switchView.addTarget(self, action: #selector(mockStateChanged(_:)), for: .valueChanged)
        
        cell.accessoryView = switchView
        cell.contentConfiguration = content
        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let mockToDelete = mocks[indexPath.row]
            NetworkLogger.shared.deleteMock(id: mockToDelete.id)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let mock = mocks[indexPath.row]
        editMock(mock, at: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
