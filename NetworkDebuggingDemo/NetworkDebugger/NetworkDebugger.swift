//
//  NetworkDebugger.swift
//  NetworkDebuggingDemo
//
//  Created by Darshan Dodia on 30/05/25.
//

import UIKit

public class NetworkDebugger {

    // MARK: - Properties

    private static var isEnabled = false
    private static var debuggerWindow: DebuggerWindow?

    // MARK: - Lifecycle Management

    /// Starts the NetworkDebugger, enabling URLSession interception and showing the debug UI.
    public static func start() {
        guard !isEnabled else {
            print("[NetworkDebugger][start]: Already enabled")
            return
        }
                    
        isEnabled = true

        DispatchQueue.main.async {
            if debuggerWindow == nil {
                // Find an active foreground window scene to attach the debugger UI
                var activeScene: UIWindowScene? = UIApplication.shared.connectedScenes
                    .filter { $0.activationState == .foregroundActive }
                    .compactMap { $0 as? UIWindowScene }
                    .first
                
                // Fallback to foregroundInactive if no active scene is found immediately
                if activeScene == nil {
                    activeScene = UIApplication.shared.connectedScenes
                        .filter { $0.activationState == .foregroundInactive }
                        .compactMap { $0 as? UIWindowScene }
                        .first
                }

                guard let windowScene = activeScene else {
                    print("[NetworkDebugger][start]: Could not find an active UIWindowScene for overlay. Debugger UI will not be available via floating button.")
                    return
                }

                debuggerWindow = DebuggerWindow(windowScene: windowScene)
                debuggerWindow?.setup() // Perform any additional setup required for the debugger window
                            
            } else {
                debuggerWindow?.isHidden = false
                debuggerWindow?.setup() // Re-setup if it was hidden
            }

            print("[NetworkDebugger][start]: UI setup initiated on main thread")
            print("[NetworkDebugger][start]: Ensure mock files are placed inside `Mock` directory")
        }
    }

    /// Stops the NetworkDebugger, unregistering the URLSession interception and hiding the debug UI.
    public static func stop() {
        guard isEnabled else {
            print("[NetworkDebugger][stop]: Not enabled or already stopped.")
            return
        }

        var currentProtocols = URLSessionConfiguration.default.protocolClasses ?? []
        currentProtocols.removeAll { $0 == URLInterceptor.self }
        URLSessionConfiguration.default.protocolClasses = currentProtocols
        print("[NetworkDebugger][stop]: Attempted to remove URLInterceptor, Current: \(URLSessionConfiguration.default.protocolClasses ?? [])")

        DispatchQueue.main.async {
            debuggerWindow?.isHidden = true // Hide the debugger UI window
        }
            
        isEnabled = false // Mark debugger as stopped
        print("[NetworkDebugger][stop]: Stopped.")
    }

    // MARK: - URLSession Configuration

    /// Returns a URLSessionConfiguration with `URLInterceptor` inserted.
    /// Use this to explicitly patch your URLSession configurations.
    /// - Parameter originalConfiguration: An optional existing configuration to patch. If nil, `URLSessionConfiguration.ephemeral` is used as a base.
    /// - Returns: A new `URLSessionConfiguration` instance with `URLInterceptor` added.
    public static func patchedConfiguration(_ originalConfiguration: URLSessionConfiguration? = nil) -> URLSessionConfiguration {
        // Create a mutable copy of the original configuration or use ephemeral
        let configToUse = originalConfiguration?.copy() as? URLSessionConfiguration ?? URLSessionConfiguration.ephemeral
        
        var protocols = configToUse.protocolClasses ?? []
        
        // Insert URLInterceptor at the beginning if it's not already present
        if !protocols.contains(where: { $0 == URLInterceptor.self }) {
            protocols.insert(URLInterceptor.self, at: 0)
        }

        configToUse.protocolClasses = protocols
        print("[NetworkDebugger][patchedConfiguration]: Patched config protocols: \(configToUse.protocolClasses ?? [])")
        return configToUse
    }
}
