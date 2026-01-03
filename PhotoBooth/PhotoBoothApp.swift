import SwiftUI

@main
struct PhotoBoothApp: App {
    @StateObject private var viewModel = PhotoBoothViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
        }
    }
}
