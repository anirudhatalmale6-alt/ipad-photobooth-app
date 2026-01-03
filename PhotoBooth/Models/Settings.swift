import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    // Operator PIN
    @Published var operatorPIN: String {
        didSet { UserDefaults.standard.set(operatorPIN, forKey: "operatorPIN") }
    }
    
    // Print settings
    @Published var numberOfCopies: Int {
        didSet { UserDefaults.standard.set(numberOfCopies, forKey: "numberOfCopies") }
    }
    
    @Published var paperSize: PaperSize {
        didSet { UserDefaults.standard.set(paperSize.rawValue, forKey: "paperSize") }
    }
    
    // Overlay/Frame settings
    @Published var overlayEnabled: Bool {
        didSet { UserDefaults.standard.set(overlayEnabled, forKey: "overlayEnabled") }
    }
    
    @Published var selectedOverlayName: String? {
        didSet { UserDefaults.standard.set(selectedOverlayName, forKey: "selectedOverlayName") }
    }
    
    // Camera settings
    @Published var cameraIPAddress: String {
        didSet { UserDefaults.standard.set(cameraIPAddress, forKey: "cameraIPAddress") }
    }
    
    @Published var countdownSeconds: Int {
        didSet { UserDefaults.standard.set(countdownSeconds, forKey: "countdownSeconds") }
    }
    
    // Auto-print settings
    @Published var autoPrintEnabled: Bool {
        didSet { UserDefaults.standard.set(autoPrintEnabled, forKey: "autoPrintEnabled") }
    }
    
    init() {
        self.operatorPIN = UserDefaults.standard.string(forKey: "operatorPIN") ?? "1234"
        self.numberOfCopies = UserDefaults.standard.integer(forKey: "numberOfCopies")
        if self.numberOfCopies == 0 { self.numberOfCopies = 1 }
        
        let paperSizeRaw = UserDefaults.standard.string(forKey: "paperSize") ?? PaperSize.fourBySix.rawValue
        self.paperSize = PaperSize(rawValue: paperSizeRaw) ?? .fourBySix
        
        self.overlayEnabled = UserDefaults.standard.bool(forKey: "overlayEnabled")
        self.selectedOverlayName = UserDefaults.standard.string(forKey: "selectedOverlayName")
        
        self.cameraIPAddress = UserDefaults.standard.string(forKey: "cameraIPAddress") ?? "192.168.1.1"
        
        self.countdownSeconds = UserDefaults.standard.integer(forKey: "countdownSeconds")
        if self.countdownSeconds == 0 { self.countdownSeconds = 3 }
        
        self.autoPrintEnabled = UserDefaults.standard.object(forKey: "autoPrintEnabled") as? Bool ?? false
    }
}

enum PaperSize: String, CaseIterable {
    case fourBySix = "4x6"
    case fiveBySeven = "5x7"
    
    var displayName: String {
        switch self {
        case .fourBySix: return "4×6 inches"
        case .fiveBySeven: return "5×7 inches"
        }
    }
    
    var sizeInPoints: CGSize {
        switch self {
        case .fourBySix: return CGSize(width: 4 * 72, height: 6 * 72)
        case .fiveBySeven: return CGSize(width: 5 * 72, height: 7 * 72)
        }
    }
}

enum PhotoBoothState: Equatable {
    case idle
    case preview
    case countdown
    case capturing
    case review
    case printing
    case error(String)
    
    static func == (lhs: PhotoBoothState, rhs: PhotoBoothState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.preview, .preview),
             (.countdown, .countdown),
             (.capturing, .capturing),
             (.review, .review),
             (.printing, .printing):
            return true
        case (.error(let lhsMsg), .error(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}
