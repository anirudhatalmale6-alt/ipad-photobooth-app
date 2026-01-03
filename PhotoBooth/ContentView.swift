import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: PhotoBoothViewModel
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            switch viewModel.currentState {
            case .idle:
                StartView()
                
            case .preview:
                LivePreviewView()
                
            case .countdown:
                CountdownView()
                
            case .capturing:
                CapturingView()
                
            case .review:
                ReviewView()
                
            case .printing:
                PrintingView()
                
            case .error(let message):
                ErrorView(message: message)
            }
            
            // Settings button (top-right corner, subtle)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.3))
                            .padding(20)
                    }
                }
                Spacer()
            }
            
            // Connection status indicator
            VStack {
                HStack {
                    ConnectionStatusView()
                        .padding(20)
                    Spacer()
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            viewModel.initialize()
        }
    }
}

struct CapturingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(2)
                .tint(.white)
            Text("Capturing...")
                .font(.title)
                .foregroundColor(.white)
                .padding(.top, 20)
        }
    }
}

struct PrintingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(2)
                .tint(.white)
            Text("Printing your photo...")
                .font(.title)
                .foregroundColor(.white)
                .padding(.top, 20)
            Text("Please wait")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
}

struct ErrorView: View {
    let message: String
    @EnvironmentObject var viewModel: PhotoBoothViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Oops!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(message)
                .font(.title3)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                viewModel.reset()
            }) {
                Text("Try Again")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 60)
                    .padding(.vertical, 20)
                    .background(Color.white)
                    .cornerRadius(15)
            }
            .padding(.top, 20)
        }
    }
}

struct ConnectionStatusView: View {
    @EnvironmentObject var viewModel: PhotoBoothViewModel
    
    var body: some View {
        HStack(spacing: 15) {
            // Camera status
            HStack(spacing: 5) {
                Circle()
                    .fill(viewModel.cameraConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Image(systemName: "camera.fill")
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Printer status
            HStack(spacing: 5) {
                Circle()
                    .fill(viewModel.printerConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Image(systemName: "printer.fill")
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.5))
        .cornerRadius(10)
    }
}

#Preview {
    ContentView()
        .environmentObject(PhotoBoothViewModel())
}
