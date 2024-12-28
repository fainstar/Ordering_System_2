import SwiftUI
import FirebaseCore  // 引入 FirebaseCore

@main
struct Ordering_System_2App: App {
    
    init() {
        // 在初始化時配置 Firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
