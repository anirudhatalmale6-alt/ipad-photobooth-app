import SwiftUI

struct ReviewView: View {
    @EnvironmentObject var viewModel: PhotoBoothViewModel
    @ObservedObject var settings = AppSettings.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Captured photo
                if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: geometry.size.width * 0.8, maxHeight: geometry.size.height * 0.7)
                        .shadow(color: .black.opacity(0.5), radius: 20)
                }
                
                // Top message
                VStack {
                    Text("Great shot!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    Spacer()
                }
                
                // Bottom controls
                VStack {
                    Spacer()
                    
                    HStack(spacing: 60) {
                        // Retake button
                        Button(action: {
                            viewModel.retakePhoto()
                        }) {
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 35))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Retake")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // Print button
                        Button(action: {
                            viewModel.printPhoto()
                        }) {
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.green, .mint]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 100, height: 100)
                                    
                                    Image(systemName: "printer.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Print")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.bottom, 60)
                }
                
                // Print info badge
                if settings.overlayEnabled && settings.selectedOverlayName != nil {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Label("Frame: \(settings.selectedOverlayName ?? "None")", systemImage: "square.on.square")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(8)
                                .padding()
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ReviewView()
        .environmentObject(PhotoBoothViewModel())
        .background(Color.black)
}
