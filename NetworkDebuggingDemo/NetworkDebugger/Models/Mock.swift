//
//  Mock.swift
//  NetworkDebuggingDemo
//
//  Created by Darshan Dodia on 02/06/25.
//

import Foundation

/// Represents a mock configuration
struct Mock: Identifiable, Codable {
    let id = UUID()
    var urlPattern: String // Simple string contains, or could be regex
    var httpMethod: String? // Optional: "GET", "POST", etc.
    var jsonFileName: String // e.g., "user_profile.json"
    var statusCode: Int = 200
    var headers: [String: String]? = ["Content-Type": "application/json"]
    var isEnabled: Bool = true
}
