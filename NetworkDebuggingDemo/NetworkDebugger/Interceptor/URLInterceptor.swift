//
//  URLInterceptor.swift
//  NetworkDebuggingDemo
//
//  Created by Darshan Dodia on 02/06/25.
//

import Foundation

class URLInterceptor: URLProtocol {

    // MARK: Properties

    private var dataTask: URLSessionDataTask?
    private var activeMock: Mock?
    private lazy var session: URLSession = {
        // Create a session configuration that *doesn't* use this protocol to avoid an infinite loop.

        // We don't need to explicitly remove our protocol here because
        // this session is only used internally by this protocol instance.
        // It won't inherit the protocolClasses from the original request's session config.
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()

    // MARK: Overrides
    
    override class func canInit(with request: URLRequest) -> Bool {
        let urlString = request.url?.absoluteString ?? "NO_URL"

        guard let scheme = request.url?.scheme, ["http", "https"].contains(scheme.lowercased()) else {
            print("[URLInterceptor][canInit]: NO - Scheme '\(request.url?.scheme ?? "nil")' not http/https for \(urlString)")
            return false
        }

        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        // We don't need to modify the request for canonicalization.
        return request
    }

    override func startLoading() {
        print("[URLInterceptor][startLoading]: startLoading for \(request.url?.absoluteString ?? "no URL")")

        // Mark this request as handled by our protocol.
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            fatalError("[URLInterceptor][startLoading]: Could not make mutable request")
        }
        
        let currentRequest = mutableRequest as URLRequest

        // Log the outgoing request
        NetworkLogger.shared.logRequest(currentRequest, taskId: taskIdentifierForLogging)

        // Check for an active mock
        if let mock = NetworkLogger.shared.activeMock(for: currentRequest) {
            self.activeMock = mock
            print("[URLInterceptor][startLoading]: Mocking request for \(currentRequest.url?.absoluteString ?? "unknown URL") with \(mock.jsonFileName)")
            handleMockedResponse(mock: mock, for: currentRequest)
            return
        }

        // If no mock, proceed with the actual network request
        self.dataTask = session.dataTask(with: currentRequest) { [weak self] data, response, error in
            guard let self = self else { return }

            // Request resulted in an error
            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
                NetworkLogger.shared.logResponse(for: currentRequest, response: response, data: data, error: error)
                return
            }

            // Request resulted in an response
            guard let response = response else {
                // This case should ideally not happen if error is nil, but as a safeguard:
                let unknownError = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
                self.client?.urlProtocol(self, didFailWithError: unknownError)
                NetworkLogger.shared.logResponse(for: currentRequest, response: nil, data: data, error: unknownError)
                return
            }

            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data = data {
                self.client?.urlProtocol(self, didLoad: data)
            }
            
            self.client?.urlProtocolDidFinishLoading(self)
            NetworkLogger.shared.logResponse(for: currentRequest, response: response, data: data, error: nil)
        }
        
        NetworkLogger.shared.logRequest(currentRequest, taskId: taskIdentifierForLogging)
        self.dataTask?.resume()
    }

    override func stopLoading() {
        dataTask?.cancel()
        dataTask = nil
    }

    // MARK: Helpers

    /// A helper to get a form of task
    private var taskIdentifierForLogging: Int {
        return Int(Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 1_000_000))
    }

    // MARK: - Mock Handling

    /// Handle mock response for a given request
    private func handleMockedResponse(mock: Mock, for request: URLRequest) {
        guard let client = client else { return }

        guard let mockFilePath = Bundle.main.path(forResource: mock.jsonFileName, ofType: nil),
              let mockData = try? Data(contentsOf: URL(fileURLWithPath: mockFilePath)) else {
            let error = NSError(domain: "NetworkDebugger",
                                code: 404,
                                userInfo: [NSLocalizedDescriptionKey: "Mock file '\(mock.jsonFileName)' not found in 'Mocks' directory."])
            client.urlProtocol(self, didFailWithError: error)
            NetworkLogger.shared.logResponse(for: request, response: nil, data: nil, error: error)
            return
        }

        // Create mock response
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: mock.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: mock.headers
        )!

        client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client.urlProtocol(self, didLoad: mockData)
        client.urlProtocolDidFinishLoading(self)
        NetworkLogger.shared.logResponse(for: request, response: response, data: mockData, error: nil)
    }
}
