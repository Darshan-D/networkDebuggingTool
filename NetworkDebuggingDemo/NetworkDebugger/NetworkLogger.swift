//
//  NetworkLogger.swift
//  NetworkDebuggingDemo
//
//  Created by Darshan Dodia on 02/06/25.
//

import Combine
import Foundation

class NetworkLogger: ObservableObject {
    
    // MARK: Properties

    static let shared = NetworkLogger()

    @Published private(set) var calls: [NetworkCall] = []
    @Published var mocks: [Mock] = [] {
        didSet { saveMocks() } // Persist mocks
    }

    private let maxCalls = 100 // Limit stored calls to prevent memory issues
    private let mocksStorageKey = "NetworkDebuggerMocks"
    private let logQueue = DispatchQueue(label: "com.networkdebugger.logqueue")

    // MARK: Initializer

    private init() {
        loadMocks()
    }

    // MARK: APIs

    /// Log the network request and store them to display later on
    func logRequest(_ request: URLRequest, taskId: Int) {
        logQueue.async {
            let call = NetworkCall(request: request)
            print("[NetworkLogger][logRequest]: [Task \(taskId)] Logging request: \(request.url?.absoluteString ?? "unknown URL")")

            DispatchQueue.main.async {
                self.calls.insert(call, at: 0)
                if self.calls.count > self.maxCalls {
                    self.calls.removeLast(self.calls.count - self.maxCalls)
                }

                print("[NetworkLogger][logRequest]: [Task \(taskId)] Added request. Total calls: \(self.calls.count)")
                NotificationCenter.default.post(name: .networkCallLogged, object: nil)
            }
        }
    }

    /// Map the network response to its respective network request
    func logResponse(for request: URLRequest, response: URLResponse?, data: Data?, error: Error?) {
         logQueue.async {
            DispatchQueue.main.async {
                if let index = self.calls.firstIndex(where: { $0.request.url == request.url && $0.response == nil && $0.request.httpMethod == request.httpMethod }) {
                    self.calls[index].response = response
                    self.calls[index].responseData = data
                    self.calls[index].error = error
                    print("[NetworkLogger][logResponse]: Logged response for \(request.url?.absoluteString ?? "URL") (matched existing)")
                    NotificationCenter.default.post(name: .networkCallUpdated, object: self.calls[index].id)
                } else {
                    // Case - Didn't find a network request for given network response (May happen during race condition)
                    print("[NetworkLogger][logResponse]: Could not find matching request to log response for \(request.url?.absoluteString ?? "unknown URL")")

                    // Log it as a new call since we can't find the original
                    let newCall = NetworkCall(request: request, response: response, responseData: data, error: error)
                    self.calls.insert(newCall, at: 0)
                    if self.calls.count > self.maxCalls {
                       self.calls.removeLast(self.calls.count - self.maxCalls)
                    }

                    NotificationCenter.default.post(name: .networkCallLogged, object: nil)
                }
            }
        }
    }

    func clearLogs() {
        DispatchQueue.main.async {
            self.calls.removeAll()
            NotificationCenter.default.post(name: .networkLogCleared, object: nil)
        }
    }

    // --- Mock Management ---

    func activeMock(for request: URLRequest) -> Mock? {
        guard let urlString = request.url?.absoluteString else {
            return nil
        }

        return mocks.first { mock in
            guard mock.isEnabled else {
                return false
            }

            let urlMatches = urlString.contains(mock.urlPattern)
            let methodMatches = mock.httpMethod == nil || mock.httpMethod?.uppercased() == request.httpMethod?.uppercased()
            return urlMatches && methodMatches
        }
    }

    func addMock(_ mock: Mock) {
        // Prevent duplicates by URL pattern and method (can be more sophisticated)
        if !mocks.contains(where: { $0.urlPattern == mock.urlPattern && $0.httpMethod == mock.httpMethod }) {
            mocks.append(mock)
        }
    }

    func updateMock(_ mock: Mock) {
        if let index = mocks.firstIndex(where: { $0.id == mock.id }) {
            mocks[index] = mock
        }
    }
    
    func deleteMock(id: UUID) {
        mocks.removeAll(where: { $0.id == id })
    }

    // MARK: Private helpers

    private func saveMocks() {
        if let encoded = try? JSONEncoder().encode(mocks) {
            UserDefaults.standard.set(encoded, forKey: mocksStorageKey)
        }
    }

    private func loadMocks() {
        if let savedMocks = UserDefaults.standard.data(forKey: mocksStorageKey),
           let decodedMocks = try? JSONDecoder().decode([Mock].self, from: savedMocks) {
            mocks = decodedMocks
        }
    }
}
