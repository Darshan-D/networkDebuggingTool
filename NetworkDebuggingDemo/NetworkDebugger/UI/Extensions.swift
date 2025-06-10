//
//  UIExtensions.swift
//  NetworkDebuggingDemo
//
//  Created by Darshan Dodia on 02/06/25.
//

import Foundation
import UIKit

extension Data {
    var prettyPrintedJSONString: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = String(data: data, encoding: .utf8) else { return nil }
        return prettyPrintedString
    }
}

extension URLRequest {
    var prettyDescription: String {
        var output = "URL: \(url?.absoluteString ?? "N/A")\n"
        output += "Method: \(httpMethod ?? "N/A")\n"
        output += "Headers:\n"
        allHTTPHeaderFields?.forEach { output += "  \($0.key): \($0.value)\n" }
        if let body = httpBody, let bodyString = String(data: body, encoding: .utf8) {
            if let jsonData = body.prettyPrintedJSONString {
                output += "Body (JSON):\n\(jsonData)"
            } else {
                output += "Body:\n\(bodyString)"
            }
        } else if httpBody != nil {
            output += "Body: (Non-UTF8 or empty)"
        }
        return output
    }
}

extension URLResponse {
    var prettyDescription: String {
        var output = "URL: \(url?.absoluteString ?? "N/A")\n"
        if let httpResponse = self as? HTTPURLResponse {
            output += "Status Code: \(httpResponse.statusCode)\n"
            output += "Headers:\n"
            httpResponse.allHeaderFields.forEach { output += "  \($0.key): \($0.value)\n" }
        }
        return output
    }
}

extension String {
    var nilIfEmpty: String? {
        return self.isEmpty ? nil : self
    }
}

extension Notification.Name {
    static let networkCallLogged = Notification.Name("networkCallLogged")
    static let networkCallUpdated = Notification.Name("networkCallUpdated")
    static let networkLogCleared = Notification.Name("networkLogCleared")
}
