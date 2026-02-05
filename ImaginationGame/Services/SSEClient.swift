//
//  SSEClient.swift
//  ImaginationGame
//
//  Server-Sent Events (SSE) Client for streaming narration
//

import Foundation

/// SSE Client for streaming progressive narration from backend
class SSEClient: NSObject {
    
    // MARK: - Properties
    
    private var urlSession: URLSession?
    private var dataTask: URLSessionDataTask?
    private var buffer = ""
    
    // Callbacks
    private var onChunk: ((String) -> Void)?
    private var onComplete: (([String: Any]) -> Void)?
    private var onError: ((Error) -> Void)?
    
    // MARK: - Public Methods
    
    /// Stream action from backend with progressive narration
    /// - Parameters:
    ///   - baseURL: API base URL (e.g., "http://localhost:8000/api/v1")
    ///   - sessionId: Game session ID
    ///   - action: Player action text
    ///   - onChunk: Called for each narration chunk
    ///   - onComplete: Called with final metadata when complete
    ///   - onError: Called if error occurs
    func streamAction(
        baseURL: String,
        sessionId: String,
        action: String,
        roomId: String,
        onChunk: @escaping (String) -> Void,
        onComplete: @escaping ([String: Any]) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        // Build URL
        guard let url = URL(string: "\(baseURL)/game/action/stream") else {
            onError(SSEError.invalidURL)
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        // Set body
        let body: [String: String] = [
            "session_id": sessionId,
            "action": action,
            "room_id": roomId
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        // Store callbacks
        self.onChunk = onChunk
        self.onComplete = onComplete
        self.onError = onError
        
        // Create session with delegate - optimized for streaming
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        config.httpMaximumConnectionsPerHost = 1
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        // Use operation queue with high quality of service for immediate processing
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
        
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: queue)
        
        // Start request
        dataTask = urlSession?.dataTask(with: request)
        dataTask?.resume()
    }
    
    /// Cancel the current streaming request
    func cancel() {
        dataTask?.cancel()
        urlSession?.invalidateAndCancel()
        buffer = ""
    }
    
    // MARK: - Private Methods
    
    private func processSSEMessage(_ message: String) {
        // Split on both \r\n and \n to handle different line endings
        let lines = message.components(separatedBy: CharacterSet.newlines)
        var event = ""
        var data = ""
        
        // Parse SSE format
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.hasPrefix("event:") {
                event = trimmedLine.replacingOccurrences(of: "event:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmedLine.hasPrefix("data:") {
                data = trimmedLine.replacingOccurrences(of: "data:", with: "").trimmingCharacters(in: .whitespaces)
            }
        }
        
        #if DEBUG
        print("🔍 SSE parsed - event: '\(event)', data: '\(data.prefix(100))'")
        #endif
        
        guard !event.isEmpty, !data.isEmpty else {
            #if DEBUG
            print("⚠️ SSE message skipped - event or data empty")
            #endif
            return
        }
        
        // Handle different event types
        switch event {
        case "narration_chunk":
            #if DEBUG
            print("📝 SSE handling narration_chunk")
            #endif
            handleNarrationChunk(data: data)
            
        case "complete":
            #if DEBUG
            print("✅ SSE handling complete")
            #endif
            handleComplete(data: data)
            
        case "error":
            #if DEBUG
            print("❌ SSE handling error")
            #endif
            handleError(data: data)
            
        default:
            #if DEBUG
            print("⚠️ SSE unknown event type: \(event)")
            #endif
            break
        }
    }
    
    private func handleNarrationChunk(data: String) {
        guard let jsonData = data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let chunk = json["chunk"] as? String else {
            #if DEBUG
            print("❌ Failed to parse narration_chunk JSON: \(data)")
            #endif
            return
        }
        
        #if DEBUG
        print("✅ Narration chunk: '\(chunk.prefix(50))'")
        #endif
        DispatchQueue.main.async {
            self.onChunk?(chunk)
        }
    }
    
    private func handleComplete(data: String) {
        guard let jsonData = data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            #if DEBUG
            print("❌ Failed to parse complete JSON: \(data)")
            #endif
            return
        }
        
        #if DEBUG
        print("✅ Complete data: \(json)")
        #endif
        DispatchQueue.main.async {
            self.onComplete?(json)
        }
    }
    
    private func handleError(data: String) {
        guard let jsonData = data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let errorMsg = json["error"] as? String else {
            #if DEBUG
            print("❌ Failed to parse error JSON: \(data)")
            #endif
            return
        }
        
        #if DEBUG
        print("❌ Error message: \(errorMsg)")
        #endif
        let error = SSEError.serverError(errorMsg)
        DispatchQueue.main.async {
            self.onError?(error)
        }
    }
}

// MARK: - URLSessionDataDelegate

extension SSEClient: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }
        #if DEBUG
        let timestamp = Date().timeIntervalSince1970
        print("📥 [\(String(format: "%.3f", timestamp))] SSE received (\(data.count) bytes): \(text.prefix(100))...")
        #endif
        buffer += text
        
        // SSE messages are separated by \r\n\r\n (or \n\n)
        // Split on both formats
        var separator = "\r\n\r\n"
        var messages = buffer.components(separatedBy: separator)
        
        // If no \r\n\r\n, try \n\n
        if messages.count == 1 {
            separator = "\n\n"
            messages = buffer.components(separatedBy: separator)
        }
        
        // Keep last incomplete message in buffer
        buffer = messages.last ?? ""
        
        // Process complete messages
        for message in messages.dropLast() where !message.isEmpty {
            #if DEBUG
            print("📨 SSE processing message: \(message.prefix(100))...")
            #endif
            processSSEMessage(message)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        #if DEBUG
        print("🏁 SSE stream completed. Error: \(error?.localizedDescription ?? "none")")
        #endif
        
        // Process any remaining buffered data
        if !buffer.isEmpty {
            #if DEBUG
            print("📨 SSE processing final buffer: \(buffer.prefix(100))...")
            #endif
            processSSEMessage(buffer)
            buffer = ""
        }
        
        if let error = error {
            DispatchQueue.main.async {
                self.onError?(error)
            }
        }
    }
}

// MARK: - Error Types

enum SSEError: LocalizedError {
    case invalidURL
    case serverError(String)
    case connectionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid streaming URL"
        case .serverError(let message):
            return "Server error: \(message)"
        case .connectionFailed:
            return "Connection failed"
        }
    }
}
