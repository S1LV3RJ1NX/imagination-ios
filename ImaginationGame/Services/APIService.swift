//
//  APIService.swift
//  ImaginationGame
//
//  Network layer for backend API communication
//  Supports both non-streaming (JSON) and streaming (SSE) endpoints
//

import Foundation
import Combine

final class APIService: @unchecked Sendable {
    
    // MARK: - Configuration
    
    static let shared = APIService()
    
    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    
    // Public getter for base URL (for HintsView and other direct API calls)
    var apiBaseURL: String {
        return baseURL
    }
    
    private init() {
        // Configure backend URL based on build configuration
        // TEMPORARY: Force production URL for testing (remove #if false to use localhost)
        #if DEBUG  // Change to "true" to test with localhost
        // Development: Use localhost when running in simulator/Xcode
        self.baseURL = "http://localhost:8000/api/v1"
        print("🔧 APIService: Using DEBUG backend - localhost:8000")
        #else
        // Production: Use deployed backend on TrueFoundry
        self.baseURL = "https://ml.tfy-eo.truefoundry.cloud/imagination-backend/api/v1"
        print("🚀 APIService: Using PRODUCTION backend - ml.tfy-eo.truefoundry.cloud")
        print("📡 Testing connection to: \(self.baseURL)/rooms")
        #endif
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        
        // Custom date decoder for Python datetime format (without timezone)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
    }
    
    // MARK: - Rooms API
    
    func fetchRooms() -> AnyPublisher<RoomsResponse, Error> {
        let url = URL(string: "\(baseURL)/rooms")!
        #if DEBUG
        print("📡 Fetching rooms from: \(url.absoluteString)")
        #endif
        
        return session.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                #if DEBUG
                print("✅ Received response from server")
                #endif
                guard let httpResponse = response as? HTTPURLResponse else {
                    #if DEBUG
                    print("❌ Invalid response type")
                    #endif
                    throw APIError.invalidResponse
                }
                #if DEBUG
                print("📊 Status code: \(httpResponse.statusCode)")
                #endif
                if !(200...299).contains(httpResponse.statusCode) {
                    #if DEBUG
                    print("❌ Error status code: \(httpResponse.statusCode)")
                    #endif
                    throw APIError.invalidResponse
                }
                return data
            }
            .decode(type: RoomsResponse.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Game Start
    
    func startGame(roomId: String? = nil, recoveryData: RecoveryData? = nil) -> AnyPublisher<StartGameResponse, Error> {
        let url = URL(string: "\(baseURL)/game/start")!
        #if DEBUG
        print("🎮 Starting game at: \(url.absoluteString)")
        if let roomId = roomId {
            print("🚪 Selected room: \(roomId)")
        }
        if recoveryData != nil {
            print("🔄 Sending recovery data (iOS-as-source-of-truth)")
        }
        #endif
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = StartGameRequest(roomId: roomId, recoveryData: recoveryData)
        request.httpBody = try? JSONEncoder().encode(body)
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    #if DEBUG
                    print("❌ Invalid response when starting game")
                    #endif
                    throw APIError.invalidResponse
                }
                #if DEBUG
                print("📊 Start game status: \(httpResponse.statusCode)")
                #endif
                guard (200...299).contains(httpResponse.statusCode) else {
                    #if DEBUG
                    print("❌ Game start failed with status: \(httpResponse.statusCode)")
                    #endif
                    throw APIError.invalidResponse
                }
                return data
            }
            .decode(type: StartGameResponse.self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Process Action (Non-Streaming)
    
    func processAction(sessionId: String, action: String) -> AnyPublisher<ActionResponse, Error> {
        let url = URL(string: "\(baseURL)/game/action")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ActionRequest(sessionId: sessionId, action: action)
        request.httpBody = try? JSONEncoder().encode(body)
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.invalidResponse
                }
                return data
            }
            .decode(type: ActionResponse.self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Process Action (Streaming SSE)
    
    /// Process action with true token-by-token streaming
    /// - Parameters:
    ///   - sessionId: Game session ID
    ///   - action: Player action text
    ///   - onChunk: Called for each narration chunk as it arrives
    ///   - onComplete: Called with final response when streaming completes
    ///   - onError: Called if streaming fails
    /// - Returns: SSEClient instance (keep reference to cancel if needed)
    @discardableResult
    func processActionStream(
        sessionId: String,
        action: String,
        roomId: String,
        onChunk: @escaping (String) -> Void,
        onComplete: @escaping (ActionResponse) -> Void,
        onError: @escaping (Error) -> Void
    ) -> SSEClient {
        let sseClient = SSEClient()
        
        sseClient.streamAction(
            baseURL: self.baseURL,
            sessionId: sessionId,
            action: action,
            roomId: roomId,
            onChunk: { chunk in
                // Stream each narration chunk
                onChunk(chunk)
            },
            onComplete: { data in
                // Parse final metadata into ActionResponse
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    let response = try self.decoder.decode(ActionResponse.self, from: jsonData)
                    onComplete(response)
                } catch {
                    #if DEBUG
                    print("❌ Failed to parse completion data: \(error)")
                    #endif
                    onError(error)
                }
            },
            onError: { error in
                onError(error)
            }
        )
        
        return sseClient
    }
    
    // MARK: - Get Game State
    
    func getState(sessionId: String) -> AnyPublisher<GameState, Error> {
        let url = URL(string: "\(baseURL)/game/state/\(sessionId)")!
        
        return session.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.invalidResponse
                }
                return data
            }
            .decode(type: GameState.self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Journal API
    
    func getJournalChapters(sessionId: String?) -> AnyPublisher<JournalListResponse, Error> {
        let urlString: String
        if let sessionId = sessionId {
            urlString = "\(baseURL)/game/journal?session_id=\(sessionId)"
        } else {
            urlString = "\(baseURL)/game/journal"
        }
        let url = URL(string: urlString)!
        #if DEBUG
        print("📖 Fetching journal chapters from: \(url.absoluteString)")
        #endif
        
        return session.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                // Handle 404 as session expired
                if httpResponse.statusCode == 404 {
                    throw APIError.sessionExpired
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.invalidResponse
                }
                
                return data
            }
            .decode(type: JournalListResponse.self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func getChapter(sessionId: String, chapterId: String) -> AnyPublisher<ChapterResponse, Error> {
        let url = URL(string: "\(baseURL)/game/journal/\(chapterId)?session_id=\(sessionId)")!
        #if DEBUG
        print("📄 Fetching chapter \(chapterId) from: \(url.absoluteString)")
        #endif
        
        return session.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                // Handle 404 as session expired
                if httpResponse.statusCode == 404 {
                    throw APIError.sessionExpired
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.invalidResponse
                }
                
                return data
            }
            .decode(type: ChapterResponse.self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Wizard API
    
    func getWizardReveal(sessionId: String) -> AnyPublisher<WizardRevealResponse, Error> {
        let url = URL(string: "\(baseURL)/game/wizard/reveal?session_id=\(sessionId)")!
        #if DEBUG
        print("🧙 Fetching wizard reveal from: \(url.absoluteString)")
        #endif
        
        return session.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.invalidResponse
                }
                return data
            }
            .decode(type: WizardRevealResponse.self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func shareProfile(sessionId: String) -> AnyPublisher<ShareProfileResponse, Error> {
        let url = URL(string: "\(baseURL)/game/profile/share")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ShareProfileRequest(sessionId: sessionId)
        request.httpBody = try? JSONEncoder().encode(body)
        
        #if DEBUG
        print("🖼️ Requesting profile share image")
        #endif
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.invalidResponse
                }
                return data
            }
            .decode(type: ShareProfileResponse.self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Errors
    
    enum APIError: LocalizedError {
        case invalidResponse
        case networkError
        case decodingError
        case sessionExpired
        
        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from server"
            case .networkError:
                return "Network connection failed"
            case .decodingError:
                return "Failed to decode response"
            case .sessionExpired:
                return "Your session has expired. Please start a new journey."
            }
        }
    }
}
