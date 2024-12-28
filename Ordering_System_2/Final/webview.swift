import SwiftUI
import WebKit

// 封裝 WKWebView 使其在 SwiftUI 中可用
struct WebView: View {
    var urlString: String
    
    var body: some View {
        // 使用 WKWebView 加載網頁
        WebViewRepresentable(urlString: urlString)
            .edgesIgnoringSafeArea(.all)  // 使 WebView 占滿整個螢幕
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    var urlString: String
    
    // 創建 WKWebView
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    // 加載網頁
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
}

struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        WebView(urlString: "https://docs.google.com/spreadsheets/d/1Ztje3NVohEgMVVzqZGPaNJBoxCp51Y6Qb7zzFXxFJuw/edit?resourcekey=&gid=1695548997#gid=1695548997")
    }
}
