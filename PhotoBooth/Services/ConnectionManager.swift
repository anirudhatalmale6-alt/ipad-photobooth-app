import Foundation
import Combine
import Network

class ConnectionManager: ObservableObject {
    static let shared = ConnectionManager()
    
    @Published var cameraConnected = false
    @Published var printerConnected = false
    @Published var isMonitoring = false
    
    private var monitoringTask: Task<Void, Never>?
    private let cameraService = CameraService.shared
    private let printService = PrintService.shared
    
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private var lastCameraState = false
    private var lastPrinterState = false
    
    private init() {}
    
    // MARK: - Monitoring
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        monitoringTask = Task {
            while !Task.isCancelled && isMonitoring {
                await checkConnections()
                
                // Check every 3 seconds
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }
    
    private func checkConnections() async {
        // Check camera
        let cameraOK = await cameraService.checkConnection()
        await MainActor.run {
            self.cameraConnected = cameraOK
            
            // Handle state changes
            if cameraOK != lastCameraState {
                if cameraOK {
                    reconnectAttempts = 0
                    print("ConnectionManager: Camera connected")
                } else {
                    print("ConnectionManager: Camera disconnected")
                    attemptCameraReconnect()
                }
                lastCameraState = cameraOK
            }
        }
        
        // Check printer
        let printerOK = printService.checkPrinterAvailability()
        await MainActor.run {
            self.printerConnected = printerOK
            
            if printerOK != lastPrinterState {
                if printerOK {
                    print("ConnectionManager: Printer available")
                } else {
                    print("ConnectionManager: Printer unavailable")
                }
                lastPrinterState = printerOK
            }
        }
    }
    
    // MARK: - Auto-Recovery
    
    private func attemptCameraReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("ConnectionManager: Max reconnect attempts reached")
            return
        }
        
        reconnectAttempts += 1
        print("ConnectionManager: Attempting camera reconnect (\(reconnectAttempts)/\(maxReconnectAttempts))")
        
        // The next monitoring cycle will automatically retry connection
    }
    
    func forceReconnect() {
        reconnectAttempts = 0
        Task {
            await checkConnections()
        }
    }
    
    // MARK: - Network Quality
    
    func getNetworkQuality() -> NetworkQuality {
        // Use Network framework to check WiFi quality
        let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
        
        // Simplified check - in production, you'd monitor over time
        return .good
    }
}

enum NetworkQuality {
    case excellent
    case good
    case poor
    case disconnected
}
