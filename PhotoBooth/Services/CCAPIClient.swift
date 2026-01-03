import Foundation
import UIKit

/// Canon Camera Connect API (CCAPI) client for R100
/// Handles WiFi communication with the camera
class CCAPIClient {
    static let shared = CCAPIClient()
    
    private var baseURL: String {
        "http://\(AppSettings.shared.cameraIPAddress):8080/ccapi/ver100"
    }
    
    private let session: URLSession
    private var isLiveViewActive = false
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Connection Check
    
    func checkConnection() async -> Bool {
        guard let url = URL(string: "\(baseURL)/deviceinformation") else {
            return false
        }
        
        do {
            let (_, response) = try await session.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            print("CCAPI: Connection check failed - \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Device Information
    
    struct DeviceInfo: Codable {
        let manufacturer: String?
        let productname: String?
        let serialnumber: String?
        let firmwareversion: String?
    }
    
    func getDeviceInfo() async throws -> DeviceInfo {
        guard let url = URL(string: "\(baseURL)/deviceinformation") else {
            throw CCAPIError.invalidURL
        }
        
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(DeviceInfo.self, from: data)
    }
    
    // MARK: - Live View
    
    func startLiveView() async throws {
        guard let url = URL(string: "\(baseURL)/shooting/liveview") else {
            throw CCAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["liveviewsize": "medium"])
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CCAPIError.liveViewFailed
        }
        
        isLiveViewActive = true
    }
    
    func stopLiveView() async throws {
        guard let url = URL(string: "\(baseURL)/shooting/liveview") else {
            throw CCAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, _) = try await session.data(for: request)
        isLiveViewActive = false
    }
    
    func getLiveViewFrame() async throws -> UIImage {
        guard let url = URL(string: "\(baseURL)/shooting/liveview/flip") else {
            throw CCAPIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CCAPIError.liveViewFailed
        }
        
        guard let image = UIImage(data: data) else {
            throw CCAPIError.invalidImageData
        }
        
        return image
    }
    
    // MARK: - Capture
    
    func capturePhoto() async throws -> UIImage {
        // Trigger shutter
        guard let shutterURL = URL(string: "\(baseURL)/shooting/control/shutterbutton") else {
            throw CCAPIError.invalidURL
        }
        
        var request = URLRequest(url: shutterURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["af": true])
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CCAPIError.captureFailed
        }
        
        // Wait for capture to complete
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Get the latest image from storage
        return try await getLatestImage()
    }
    
    private func getLatestImage() async throws -> UIImage {
        // Get storage info
        guard let storageURL = URL(string: "\(baseURL)/contents/sd/100CANON") else {
            throw CCAPIError.invalidURL
        }
        
        let (data, _) = try await session.data(from: storageURL)
        
        struct ContentList: Codable {
            let path: [String]?
        }
        
        let contents = try JSONDecoder().decode(ContentList.self, from: data)
        
        guard let paths = contents.path, let lastPath = paths.last else {
            throw CCAPIError.noImageFound
        }
        
        // Download the image
        guard let imageURL = URL(string: "\(baseURL)/contents/sd/100CANON/\(lastPath)") else {
            throw CCAPIError.invalidURL
        }
        
        let (imageData, _) = try await session.data(from: imageURL)
        
        guard let image = UIImage(data: imageData) else {
            throw CCAPIError.invalidImageData
        }
        
        return image
    }
    
    // MARK: - Camera Settings
    
    func setShootingMode(_ mode: String) async throws {
        guard let url = URL(string: "\(baseURL)/shooting/settings/shootingmode") else {
            throw CCAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["value": mode])
        
        let (_, _) = try await session.data(for: request)
    }
}

enum CCAPIError: LocalizedError {
    case invalidURL
    case connectionFailed
    case liveViewFailed
    case captureFailed
    case invalidImageData
    case noImageFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid camera URL"
        case .connectionFailed:
            return "Failed to connect to camera"
        case .liveViewFailed:
            return "Live view failed"
        case .captureFailed:
            return "Failed to capture photo"
        case .invalidImageData:
            return "Invalid image data received"
        case .noImageFound:
            return "No image found on camera"
        }
    }
}
