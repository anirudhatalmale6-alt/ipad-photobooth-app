import SwiftUI

struct LivePreviewView: View {
    @EnvironmentObject var viewModel: PhotoBoothViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Live preview from camera
                if let previewImage = viewModel.livePreviewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    // Placeholder while waiting for camera
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(2)
                            .tint(.white)
                        Text("Connecting to camera...")
                            .foregroundColor(.white)
                    }
                }
                
                // Overlay frame guide
                Rectangle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .padding(40)
                
                // Bottom control bar
                VStack {
                    Spacer()
                    
                    HStack(spacing: 40) {
                        // Cancel button
                        Button(action: {
                            viewModel.reset()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 40))
                                Text("Cancel")
                                    .font(.caption)
                            }
                            .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // Capture button
                        Button(action: {
                            viewModel.startCountdown()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 100, height: 100)
                            }
                        }
                        
                        Spacer()
                        
                        // Placeholder for symmetry
                        VStack(spacing: 8) {
                            Image(systemName: "circle")
                                .font(.system(size: 40))
                            Text(" ")
                                .font(.caption)
                        }
                        .opacity(0)
                    }
                    .padding(.horizontal, 60)
                    .padding(.bottom, 40)
                }
                
                // Top hint
                VStack {
                    Text("Position yourself and tap the button!")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .padding(.top, 40)
                    
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    LivePreviewView()
        .environmentObject(PhotoBoothViewModel())
        .background(Color.black)
}
