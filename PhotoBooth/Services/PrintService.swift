import Foundation
import UIKit

class PrintService: ObservableObject {
    static let shared = PrintService()
    
    @Published var isPrinting = false
    @Published var printerAvailable = false
    
    private var printQueue: [PrintJob] = []
    private var isProcessingQueue = false
    
    private init() {}
    
    struct PrintJob {
        let image: UIImage
        let copies: Int
        let paperSize: PaperSize
        let completion: (Result<Void, Error>) -> Void
    }
    
    // MARK: - Printer Discovery
    
    func checkPrinterAvailability() -> Bool {
        let printInfo = UIPrintInteractionController.shared
        return UIPrintInteractionController.canPrint(Data()) && 
               UIPrintInteractionController.isPrintingAvailable
    }
    
    func findEpsonPrinter() async -> UIPrinter? {
        return await withCheckedContinuation { continuation in
            let printerPicker = UIPrinterPickerController(initiallySelectedPrinter: nil)
            // In a real scenario, we'd use Bonjour to find the Epson PM-520
            // For now, we rely on AirPrint automatic discovery
            continuation.resume(returning: nil)
        }
    }
    
    // MARK: - Printing
    
    func printImage(_ image: UIImage, copies: Int, paperSize: PaperSize) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let job = PrintJob(
                image: image,
                copies: copies,
                paperSize: paperSize
            ) { result in
                continuation.resume(with: result)
            }
            
            printQueue.append(job)
            processQueue()
        }
    }
    
    private func processQueue() {
        guard !isProcessingQueue, !printQueue.isEmpty else { return }
        
        isProcessingQueue = true
        let job = printQueue.removeFirst()
        
        DispatchQueue.main.async { [weak self] in
            self?.isPrinting = true
            self?.executePrintJob(job)
        }
    }
    
    private func executePrintJob(_ job: PrintJob) {
        let printController = UIPrintInteractionController.shared
        
        // Configure print info
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = "PhotoBooth Photo"
        printInfo.outputType = .photo
        printInfo.orientation = job.image.size.width > job.image.size.height ? .landscape : .portrait
        
        printController.printInfo = printInfo
        printController.printingItem = job.image
        
        // Set number of copies
        // Note: UIPrintInteractionController doesn't directly support copies
        // We handle this by submitting multiple jobs if needed
        
        // Configure paper size via print formatter
        let formatter = UISimpleTextPrintFormatter(text: "")
        formatter.perPageContentInsets = .zero
        
        // For Epson PM-520, we use the best-fit approach
        // The printer will handle 4x6 or 5x7 paper automatically
        
        printController.present(animated: true) { [weak self] controller, completed, error in
            DispatchQueue.main.async {
                self?.isPrinting = false
                self?.isProcessingQueue = false
                
                if let error = error {
                    job.completion(.failure(error))
                } else if completed {
                    // Handle additional copies
                    if job.copies > 1 {
                        var remainingCopies = job.copies - 1
                        self?.queueAdditionalCopies(job: job, remaining: remainingCopies)
                    }
                    job.completion(.success(()))
                } else {
                    job.completion(.failure(PrintError.cancelled))
                }
                
                // Process next job in queue
                self?.processQueue()
            }
        }
    }
    
    private func queueAdditionalCopies(job: PrintJob, remaining: Int) {
        guard remaining > 0 else { return }
        
        // Queue remaining copies
        for _ in 0..<remaining {
            let copyJob = PrintJob(
                image: job.image,
                copies: 1,
                paperSize: job.paperSize
            ) { _ in }
            printQueue.append(copyJob)
        }
    }
    
    // MARK: - Silent Printing (without dialog)
    
    func printImageSilently(_ image: UIImage, printer: UIPrinter, copies: Int, paperSize: PaperSize) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let printController = UIPrintInteractionController.shared
                
                let printInfo = UIPrintInfo(dictionary: nil)
                printInfo.jobName = "PhotoBooth Photo"
                printInfo.outputType = .photo
                printInfo.orientation = image.size.width > image.size.height ? .landscape : .portrait
                
                printController.printInfo = printInfo
                printController.printingItem = image
                
                printController.print(to: printer, completionHandler: { controller, completed, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if completed {
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: PrintError.cancelled)
                    }
                })
            }
        }
    }
}

enum PrintError: LocalizedError {
    case cancelled
    case printerNotFound
    case printFailed
    
    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Print was cancelled"
        case .printerNotFound:
            return "Printer not found"
        case .printFailed:
            return "Print failed"
        }
    }
}
