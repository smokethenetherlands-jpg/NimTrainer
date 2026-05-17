import SwiftUI

extension Color {
    static let nimBackground = Color(red: 0.07, green: 0.07, blue: 0.12)
    static let nimCard       = Color(red: 0.13, green: 0.13, blue: 0.20)
    static let nimCardDark   = Color(red: 0.10, green: 0.10, blue: 0.16)
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            SetupView()
        }
        .preferredColorScheme(.dark)
    }
}
