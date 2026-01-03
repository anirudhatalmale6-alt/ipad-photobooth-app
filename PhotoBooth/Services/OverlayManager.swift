import Foundation
import UIKit

class OverlayManager: ObservableObject {
    static let shared = OverlayManager()
    
    @Published var availableOverlays: [OverlayInfo] = []
    
    private let overlayDirectory: URL
    
    struct OverlayInfo: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let fileName: String
        let thumbnail: UIImage?
    }
    
    private init() {
        // Store overlays in Documents directory
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        overlayDirectory = docs.appendingPathComponent("Overlays", isDirectory: true)
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: overlayDirectory, withIntermediateDirectories: true)
        
        loadAvailableOverlays()
    }
    
    // MARK: - Overlay Management
    
    func loadAvailableOverlays() {
        var overlays: [OverlayInfo] = []
        
        // Add built-in "None" option
        overlays.append(OverlayInfo(name: "None", fileName: "", thumbnail: nil))
        
        // Scan overlay directory
        if let files = try? FileManager.default.contentsOfDirectory(at: overlayDirectory, includingPropertiesForKeys: nil) {
            for file in files {
                if file.pathExtension.lowercased() == "png" {
                    if let image = UIImage(contentsOfFile: file.path) {
                        let name = file.deletingPathExtension().lastPathComponent
                        let thumbnail = createThumbnail(from: image, size: CGSize(width: 100, height: 67))
                        overlays.append(OverlayInfo(name: name, fileName: file.lastPathComponent, thumbnail: thumbnail))
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            self.availableOverlays = overlays
        }
    }
    
    func importOverlay(from url: URL) throws {
        let destination = overlayDirectory.appendingPathComponent(url.lastPathComponent)
        
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        
        try FileManager.default.copyItem(at: url, to: destination)
        loadAvailableOverlays()
    }
    
    func deleteOverlay(named name: String) throws {
        if let overlay = availableOverlays.first(where: { $0.name == name }), !overlay.fileName.isEmpty {
            let path = overlayDirectory.appendingPathComponent(overlay.fileName)
            try FileManager.default.removeItem(at: path)
            loadAvailableOverlays()
        }
    }
    
    // MARK: - Apply Overlay
    
    func applyOverlay(to photo: UIImage, overlayName: String) -> UIImage? {
        guard let overlay = availableOverlays.first(where: { $0.name == overlayName }),
              !overlay.fileName.isEmpty else {
            return photo // No overlay to apply
        }
        
        let overlayPath = overlayDirectory.appendingPathComponent(overlay.fileName)
        guard let overlayImage = UIImage(contentsOfFile: overlayPath.path) else {
            return photo
        }
        
        return compositeImages(base: photo, overlay: overlayImage)
    }
    
    private func compositeImages(base: UIImage, overlay: UIImage) -> UIImage? {
        let size = base.size
        
        UIGraphicsBeginImageContextWithOptions(size, false, base.scale)
        defer { UIGraphicsEndImageContext() }
        
        // Draw base photo
        base.draw(in: CGRect(origin: .zero, size: size))
        
        // Draw overlay on top (scaled to fit)
        overlay.draw(in: CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // MARK: - Helpers
    
    private func createThumbnail(from image: UIImage, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // MARK: - Sample Overlays
    
    func createSampleOverlays() {
        // Create a simple frame overlay for demo purposes
        let frameSize = CGSize(width: 1800, height: 1200) // 4x6 at 300dpi
        
        UIGraphicsBeginImageContextWithOptions(frameSize, false, 1)
        defer { UIGraphicsEndImageContext() }
        
        // Transparent background
        UIColor.clear.setFill()
        UIRectFill(CGRect(origin: .zero, size: frameSize))
        
        // Draw border
        let borderPath = UIBezierPath(rect: CGRect(x: 20, y: 20, width: frameSize.width - 40, height: frameSize.height - 40))
        UIColor.white.setStroke()
        borderPath.lineWidth = 20
        borderPath.stroke()
        
        if let frameImage = UIGraphicsGetImageFromCurrentImageContext(),
           let pngData = frameImage.pngData() {
            let destination = overlayDirectory.appendingPathComponent("Simple Frame.png")
            try? pngData.write(to: destination)
        }
        
        loadAvailableOverlays()
    }
}
