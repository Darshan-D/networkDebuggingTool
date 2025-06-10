//
//  NetworkCall.swift
//  NetworkDebuggingDemo
//
//  Created by Darshan Dodia on 02/06/25.
//

import Foundation

/// Represents a single network transaction
struct NetworkCall: Identifiable {
    let id = UUID()
    let request: URLRequest
    var response: URLResponse?
    var responseData: Data?
    var error: Error?
    let timestamp: Date = Date()

    var requestBodyString: String? {
        guard let bodyData = request.httpBody, !bodyData.isEmpty else {
            return nil
        }

        return String(data: bodyData, encoding: .utf8) ?? "Non-UTF8 Body"
    }

    var responseBodyString: String? {
        guard let data = responseData, !data.isEmpty else {
            return nil
        }

        if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
           let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            return String(data: prettyData, encoding: .utf8) ?? "Non-UTF8 JSON Body"
        }

        return String(data: data, encoding: .utf8) ?? "Non-UTF8 Body"
    }

    var curlRepresentation: String {
        var components = ["curl -v"]

        // Method
        if let method = request.httpMethod, method != "GET" {
            components.append("-X \(method)")
        }

        // URL
        if let urlString = request.url?.absoluteString {
            components.append("'\(urlString)'")
        }

        // Headers
        request.allHTTPHeaderFields?.forEach { key, value in
            components.append("-H '\(key): \(value)'")
        }

        // Body
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            components.append("-d '\(bodyString)'")
        }
        
        return components.joined(separator: " \\\n\t")
    }
}
