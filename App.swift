import SwiftUI
import WebKit

@main
struct SimpleBrowserApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var urlString: String = "https://www.google.com"
    @State private var webViewStore = WebViewStore()
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("输入网址", text: $urlString, onCommit: loadUrl)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)

                Button("Go") {
                    loadUrl()
                }
                .padding(.horizontal, 8)
            }
            .padding()

            WebViewWrapper(store: webViewStore)

            HStack {
                Button(action: {
                    webViewStore.webView.goBack()
                }) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!webViewStore.canGoBack)

                Spacer()

                Button(action: {
                    webViewStore.webView.goForward()
                }) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!webViewStore.canGoForward)

                Spacer()

                Button(action: {
                    webViewStore.webView.reload()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .padding()
            .font(.title2)
        }
        .onAppear {
            loadUrl()
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("无法加载页面"),
                message: Text(errorMessage ?? "发生未知错误"),
                dismissButton: .default(Text("确定"))
            )
        }
        .onReceive(webViewStore.$error) { err in
            if let err = err {
                self.errorMessage = err.localizedDescription
                self.showErrorAlert = true
            }
        }
    }

    private func loadUrl() {
        var formatted = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !formatted.hasPrefix("http://") && !formatted.hasPrefix("https://") {
            formatted = "https://" + formatted
        }
        if let url = URL(string: formatted) {
            webViewStore.webView.load(URLRequest(url: url))
        } else {
            errorMessage = "输入的 URL 格式无效"
            showErrorAlert = true
        }
    }
}

class WebViewStore: NSObject, ObservableObject, WKNavigationDelegate {
    let webView: WKWebView = WKWebView()
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var error: Error? = nil

    override init() {
        super.init()
        webView.navigationDelegate = self
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.error = error
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.error = error
    }
}

struct WebViewWrapper: UIViewRepresentable {
    @ObservedObject var store: WebViewStore

    func makeUIView(context: Context) -> WKWebView {
        return store.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
