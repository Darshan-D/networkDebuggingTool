# iOS Network Debugging Tool & Dictionary App Demo

This repository contains a lightweight, in-app **Network Debugging Tool** for iOS applications, along with a **Simple Dictionary App** that demonstrates its usage.

## Network Debugging Tool Features

*   🔎 **See Network Requests:** View all outgoing HTTP/HTTPS requests fired by your app.
*   📄 **Inspect Server Responses:** Examine status codes, headers, and response bodies.
*   🎭 **Mock Server Responses:** Easily substitute actual server responses with local JSON files for testing different scenarios and edge cases.
*   🔘 **Overlay UI:** Access the debugger via a floating button that appears over your app.

## How It Works (Briefly)

The tool uses a custom `URLProtocol` to intercept network traffic. For it to work with your `URLSession` instances, you'll need to initialize your sessions with a specially patched `URLSessionConfiguration` provided by the tool (especially in debug builds).

## Dictionary App Demo

The included `Dictionary` app is a simple application that fetches word definitions from a public API. It's pre-configured to use the Network Debugging Tool in `DEBUG` builds.

*   Run the `NetworkDebuggingDemo` app.
*   You'll see a floating "⚙️" button. Tap it to open the debugger.
*   Perform a search in the dictionary app to see network requests logged.
*   Explore the "Mocks" tab in the debugger to set up mock responses. (Example mock files can be added to the app's "Mocks" directory).

## Integrating the Tool into Your Own App

1.  **Add the Package/Source:**
    *   By directly adding the source files from the `NetworkDebugger` directory (`NetworkDebuggingDemo/NetworkDebugger`) to your project.
2.  **Initialize the Debugger:**
    In your `AppDelegate.swift` or `SceneDelegate.swift` (ensure it's called at an appropriate time, e.g., after the main window is set up if using `SceneDelegate`):
    ```swift
    #if DEBUG
        NetworkDebugger.start()
    #endif
    ```
3.  **Use Patched URLSession Configuration:**
    For requests you want to intercept, create your `URLSession` with a patched configuration in your debug builds:
    ```swift
    #if DEBUG
        let config = NetworkDebugger.patchedConfiguration()
        let sessionToUse = URLSession(configuration: config)
    #else
        let sessionToUse = URLSession.shared // Or your production session
    #endif

    // Use sessionToUse for your network tasks
    ```
4.  **Add Mock Files (Optional):**
    *   In your app project, create a **New Group** (yellow folder icon) named `Mocks`.
    *   Add your `.json` mock files to this `Mocks` group.
    *   **Important:** Ensure these files are added to your app's **Target Membership** and are included in the **Copy Bundle Resources** build phase.
    *   Configure mocks via the debugger's UI (Mocks tab). The "JSON File Name" should match the name of the file in your `Mocks` directory.

## Why this approach?

During the development of this tool, we discovered that attempts to globally modify `URLSessionConfiguration.default` (to inject our `URLProtocol` for `URLSession.shared`) were unreliable across different environments and app lifecycle states. Therefore, the current recommended and most robust method is to explicitly create `URLSession` instances using the `NetworkDebugger.patchedConfiguration()` for requests you wish to monitor or mock during debugging.

## Contributing

Feel free to fork, improve, and submit pull requests! If you encounter issues or have suggestions, please open an issue.
