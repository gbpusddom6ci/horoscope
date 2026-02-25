import SwiftUI
import Firebase

struct ContentView: View {
    @State private var isFirebaseConfigured = false
    @State private var hasError = false

    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.2)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Mystic App Test")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .bold()

                if isFirebaseConfigured {
                    Text("✅ Firebase Bağlantısı Başarılı")
                        .foregroundColor(.green)

                    Button("Uygulamaya Git") {
                        // Normally this would transition to AppRouter
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                } else if hasError {
                    Text("❌ Firebase Başlatılamadı")
                        .foregroundColor(.red)
                    Text("GoogleService-Info.plist dosyası projede eksik olabilir!")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ProgressView()
                        .tint(.white)
                    Text("Firebase kontrol ediliyor...")
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            checkFirebase()
        }
    }

    private func checkFirebase() {
        // Simple check to see if Firebase App is initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if FirebaseApp.app() != nil {
                self.isFirebaseConfigured = true
            } else {
                self.hasError = true
            }
        }
    }
}

#Preview {
    ContentView()
}
