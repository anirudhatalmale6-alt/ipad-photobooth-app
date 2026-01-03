import Foundation
import UIKit
import Combine

class CameraService: ObservableObject {
    static let shared = CameraService()
    
    @Published var currentFrame: UIImage?
    @Published var isConnected = false
    @Published var isLiveViewActive = false
    
    private let ccapi = CCAPIClient.shared
    private var liveViewTask: Task<Void, Never>?
    
    private init() {}
    
    // MARK: - Connection
    
    func checkConnection() async -> Bool {
        let connected = await ccapi.checkConnection()
        await MainActor.run {
            self.isConnected = connected
        }
        return connected
    }
    
    // MARK: - Live View
    
    func startLiveView() {
        guard !isLiveViewActive else { return }
        
        liveViewTask = Task {
            do {
                try await ccapi.startLiveView()
                await MainActor.run {
                    self.isLiveViewActive = true
                }
                
                // Continuously fetch frames
                while !Task.isCancelled && isLiveViewActive {
                    do {
                        let frame = try await ccapi.getLiveViewFrame()
                        await MainActor.run {
                            self.currentFrame = frame
                        }
                    } catch {
                        // Brief pause before retry on error
                        try? await Task.sleep(nanoseconds: 100_000_000)
                    }
                    
                    // Target ~15 fps
                    try? await Task.sleep(nanoseconds: 66_000_000)
                }
            } catch {
                print("CameraService: Failed to start live view - \(error)")
                await MainActor.run {
                    self.isLiveViewActive = false
                }
            }
        }
    }
    
    func stopLiveView() {
        isLiveViewActive = false
        liveViewTask?.cancel()
        liveViewTask = nil
        
        Task {
            try? await ccapi.stopLiveView()
        }
    }
    
    // MARK: - Capture
    
    func capturePhoto() async throws -> UIImage {
        // Stop live view before capture
        stopLiveView()
        try await Task.sleep(nanoseconds: 500_000_000)
        
        return try await ccapi.capturePhoto()
    }
}
