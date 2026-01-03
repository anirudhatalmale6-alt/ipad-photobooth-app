import SwiftUI

struct CountdownView: View {
    @EnvironmentObject var viewModel: PhotoBoothViewModel
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Keep showing live preview in background
                if let previewImage = viewModel.livePreviewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
                
                // Dark overlay
                Color.black.opacity(0.4)
                
                // Countdown number
                Text("\(viewModel.countdownValue)")
                    .font(.system(size: 300, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 10)
                    .scaleEffect(scale)
                    .onChange(of: viewModel.countdownValue) { _ in
                        // Animate on each count change
                        withAnimation(.easeOut(duration: 0.1)) {
                            scale = 1.3
                        }
                        withAnimation(.easeIn(duration: 0.3).delay(0.1)) {
                            scale = 1.0
                        }
                    }
                
                // Flash effect when reaching 0
                if viewModel.countdownValue == 0 {
                    Color.white
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    CountdownView()
        .environmentObject(PhotoBoothViewModel())
}
