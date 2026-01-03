import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var overlayManager = OverlayManager.shared
    @ObservedObject var connectionManager = ConnectionManager.shared
    
    @State private var showPINEntry = true
    @State private var enteredPIN = ""
    @State private var pinError = false
    @State private var showOverlayImporter = false
    
    var body: some View {
        if showPINEntry {
            PINEntryView(
                enteredPIN: $enteredPIN,
                pinError: $pinError,
                onSubmit: {
                    if enteredPIN == settings.operatorPIN {
                        showPINEntry = false
                        pinError = false
                    } else {
                        pinError = true
                        enteredPIN = ""
                    }
                },
                onCancel: {
                    dismiss()
                }
            )
        } else {
            NavigationView {
                Form {
                    // Connection Status Section
                    Section("Connection Status") {
                        HStack {
                            Label("Camera (Canon R100)", systemImage: "camera.fill")
                            Spacer()
                            Circle()
                                .fill(connectionManager.cameraConnected ? Color.green : Color.red)
                                .frame(width: 12, height: 12)
                            Text(connectionManager.cameraConnected ? "Connected" : "Disconnected")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("Printer (Epson PM-520)", systemImage: "printer.fill")
                            Spacer()
                            Circle()
                                .fill(connectionManager.printerConnected ? Color.green : Color.red)
                                .frame(width: 12, height: 12)
                            Text(connectionManager.printerConnected ? "Available" : "Unavailable")
                                .foregroundColor(.secondary)
                        }
                        
                        Button("Refresh Connections") {
                            connectionManager.forceReconnect()
                        }
                    }
                    
                    // Camera Settings
                    Section("Camera Settings") {
                        HStack {
                            Text("Camera IP Address")
                            Spacer()
                            TextField("192.168.1.1", text: $settings.cameraIPAddress)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                                .keyboardType(.decimalPad)
                        }
                        
                        Stepper("Countdown: \(settings.countdownSeconds) seconds", value: $settings.countdownSeconds, in: 1...10)
                    }
                    
                    // Print Settings
                    Section("Print Settings") {
                        Stepper("Copies: \(settings.numberOfCopies)", value: $settings.numberOfCopies, in: 1...5)
                        
                        Picker("Paper Size", selection: $settings.paperSize) {
                            ForEach(PaperSize.allCases, id: \.self) { size in
                                Text(size.displayName).tag(size)
                            }
                        }
                        
                        Toggle("Auto-print after capture", isOn: $settings.autoPrintEnabled)
                    }
                    
                    // Overlay/Frame Settings
                    Section("Overlay/Frame") {
                        Toggle("Enable Overlay", isOn: $settings.overlayEnabled)
                        
                        if settings.overlayEnabled {
                            Picker("Select Frame", selection: $settings.selectedOverlayName) {
                                ForEach(overlayManager.availableOverlays) { overlay in
                                    HStack {
                                        if let thumbnail = overlay.thumbnail {
                                            Image(uiImage: thumbnail)
                                                .resizable()
                                                .frame(width: 50, height: 33)
                                                .cornerRadius(4)
                                        }
                                        Text(overlay.name)
                                    }
                                    .tag(overlay.name as String?)
                                }
                            }
                            
                            Button("Import Overlay...") {
                                showOverlayImporter = true
                            }
                            
                            Button("Create Sample Frames") {
                                overlayManager.createSampleOverlays()
                            }
                        }
                    }
                    
                    // Security
                    Section("Security") {
                        HStack {
                            Text("Operator PIN")
                            Spacer()
                            SecureField("PIN", text: $settings.operatorPIN)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                                .keyboardType(.numberPad)
                        }
                    }
                    
                    // About
                    Section("About") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Hardware")
                            Spacer()
                            Text("Canon R100 + Epson PM-520")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
            .navigationViewStyle(.stack)
            .fileImporter(
                isPresented: $showOverlayImporter,
                allowedContentTypes: [.png],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    try? overlayManager.importOverlay(from: url)
                }
            }
        }
    }
}

struct PINEntryView: View {
    @Binding var enteredPIN: String
    @Binding var pinError: Bool
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    private let pinLength = 4
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Enter Operator PIN")
                .font(.title)
                .fontWeight(.bold)
            
            // PIN dots display
            HStack(spacing: 20) {
                ForEach(0..<pinLength, id: \.self) { index in
                    Circle()
                        .fill(index < enteredPIN.count ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                }
            }
            .padding()
            
            if pinError {
                Text("Incorrect PIN")
                    .foregroundColor(.red)
            }
            
            // Number pad
            VStack(spacing: 15) {
                ForEach(0..<3) { row in
                    HStack(spacing: 25) {
                        ForEach(1...3, id: \.self) { col in
                            let number = row * 3 + col
                            NumberButton(number: "\(number)") {
                                addDigit("\(number)")
                            }
                        }
                    }
                }
                
                HStack(spacing: 25) {
                    NumberButton(number: "C", isSpecial: true) {
                        enteredPIN = ""
                        pinError = false
                    }
                    
                    NumberButton(number: "0") {
                        addDigit("0")
                    }
                    
                    NumberButton(number: "⌫", isSpecial: true) {
                        if !enteredPIN.isEmpty {
                            enteredPIN.removeLast()
                        }
                    }
                }
            }
            
            Button("Cancel") {
                onCancel()
            }
            .foregroundColor(.gray)
            .padding(.top, 20)
        }
        .padding(40)
        .background(Color(.systemBackground))
    }
    
    private func addDigit(_ digit: String) {
        guard enteredPIN.count < pinLength else { return }
        
        pinError = false
        enteredPIN += digit
        
        if enteredPIN.count == pinLength {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onSubmit()
            }
        }
    }
}

struct NumberButton: View {
    let number: String
    var isSpecial: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.title)
                .fontWeight(.medium)
                .frame(width: 70, height: 70)
                .background(isSpecial ? Color.gray.opacity(0.2) : Color.blue.opacity(0.1))
                .foregroundColor(isSpecial ? .gray : .primary)
                .cornerRadius(35)
        }
    }
}

#Preview {
    SettingsView()
}
