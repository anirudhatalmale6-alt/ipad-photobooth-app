import SwiftUI

struct StartView: View {
    @EnvironmentObject var viewModel: PhotoBoothViewModel
    @State private var isPulsing = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Title
            VStack(spacing: 10) {
                Text("Photo Booth")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Tap to begin")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Big Start Button
            Button(action: {
                viewModel.startSession()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 200)
                        .shadow(color: .blue.opacity(0.5), radius: isPulsing ? 30 : 20)
                    
                    VStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 50))
                        Text("START")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                }
            }
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
            
            Spacer()
            
            // Instructions
            HStack(spacing: 40) {
                InstructionItem(icon: "hand.tap.fill", text: "Tap Start")
                InstructionItem(icon: "face.smiling.fill", text: "Strike a Pose")
                InstructionItem(icon: "printer.fill", text: "Get Your Print")
            }
            .padding(.bottom, 50)
        }
    }
}

struct InstructionItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.white.opacity(0.7))
            Text(text)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    StartView()
        .environmentObject(PhotoBoothViewModel())
        .background(Color.black)
}
