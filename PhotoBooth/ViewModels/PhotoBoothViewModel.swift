import Foundation
import SwiftUI
import Combine

@MainActor
class PhotoBoothViewModel: ObservableObject {
    // State
    @Published var currentState: PhotoBoothState = .idle
    @Published var cameraConnected = false
    @Published var printerConnected = false
    @Published var capturedImage: UIImage?
    @Published var livePreviewImage: UIImage?
    @Published var countdownValue: Int = 3
    
    // Services
    private let cameraService = CameraService.shared
    private let printService = PrintService.shared
    private let connectionManager = ConnectionManager.shared
    private let overlayManager = OverlayManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var liveViewTimer: Timer?
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Monitor camera connection
        connectionManager.$cameraConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                self?.cameraConnected = connected
            }
            .store(in: &cancellables)
        
        // Monitor printer connection
        connectionManager.$printerConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                self?.printerConnected = connected
            }
            .store(in: &cancellables)
        
        // Monitor live view frames
        cameraService.$currentFrame
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                self?.livePreviewImage = image
            }
            .store(in: &cancellables)
    }
    
    func initialize() {
        connectionManager.startMonitoring()
    }
    
    func startSession() {
        guard cameraConnected else {
            currentState = .error("Camera not connected. Please check WiFi connection to Canon R100.")
            return
        }
        
        currentState = .preview
        cameraService.startLiveView()
    }
    
    func startCountdown() {
        currentState = .countdown
        countdownValue = AppSettings.shared.countdownSeconds
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            Task { @MainActor in
                if self.countdownValue > 1 {
                    self.countdownValue -= 1
                } else {
                    timer.invalidate()
                    self.capturePhoto()
                }
            }
        }
    }
    
    func capturePhoto() {
        currentState = .capturing
        cameraService.stopLiveView()
        
        Task {
            do {
                let image = try await cameraService.capturePhoto()
                self.capturedImage = image
                self.currentState = .review
            } catch {
                self.currentState = .error("Failed to capture photo: \(error.localizedDescription)")
            }
        }
    }
    
    func retakePhoto() {
        capturedImage = nil
        currentState = .preview
        cameraService.startLiveView()
    }
    
    func printPhoto() {
        guard let image = capturedImage else {
            currentState = .error("No photo to print")
            return
        }
        
        guard printerConnected else {
            currentState = .error("Printer not connected. Please check Epson PM-520 connection.")
            return
        }
        
        currentState = .printing
        
        Task {
            do {
                // Apply overlay if enabled
                let finalImage: UIImage
                if AppSettings.shared.overlayEnabled, let overlayName = AppSettings.shared.selectedOverlayName {
                    finalImage = overlayManager.applyOverlay(to: image, overlayName: overlayName) ?? image
                } else {
                    finalImage = image
                }
                
                try await printService.printImage(
                    finalImage,
                    copies: AppSettings.shared.numberOfCopies,
                    paperSize: AppSettings.shared.paperSize
                )
                
                // Success - reset to idle after brief delay
                try await Task.sleep(nanoseconds: 2_000_000_000)
                self.reset()
            } catch {
                self.currentState = .error("Print failed: \(error.localizedDescription)")
            }
        }
    }
    
    func reset() {
        capturedImage = nil
        livePreviewImage = nil
        currentState = .idle
        cameraService.stopLiveView()
    }
}
