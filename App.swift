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
    @State private var inputUrl: String = ""
    @State private var webViewStore = WebViewStore()
    @State private var showingShareSheet = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("搜索或输入网址", text: $inputUrl, onCommit: {
                        loadInput()
                    })
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    
                    if !inputUrl.isEmpty {
                        Button(action: {
                            inputUrl = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(uiColor: .systemBackground))

            if webViewStore.isLoading {
                ProgressView(value: webViewStore.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(height: 2)
            } else {
                Divider()
            }

            WebViewWrapper(store: webViewStore)
                .edgesIgnoringSafeArea(.horizontal)

            Divider()

            HStack {
                Button(action: { webViewStore.webView.goBack() }) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!webViewStore.canGoBack)

                Spacer()

                Button(action: { webViewStore.webView.goForward() }) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!webViewStore.canGoForward)

                Spacer()

                Button(action: { loadHome() }) {
                    Image(systemName: "house")
                }

                Spacer()

                Button(action: { webViewStore.webView.reload() }) {
                    Image(systemName: "arrow.clockwise")
                }

                Spacer()

                Button(action: { showingShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(webViewStore.currentUrl == nil)
            }
            .font(.system(size: 20, weight: .regular))
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Color(uiColor: .systemBackground))
        }
        .onAppear {
            loadHome()
        }
        .onChange(of: webViewStore.currentUrl) { newUrl in
            if let absolute = newUrl?.absoluteString {
                inputUrl = absolute
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = webViewStore.currentUrl {
                ShareSheet(activityItems: [url])
            }
        }
    }

    private func loadHome() {
        let homeUrl = "https://www.google.com"
        inputUrl = homeUrl
        if let url = URL(string: homeUrl) {
            webViewStore.webView.load(URLRequest(url: url))
        }
    }

    private func loadInput() {
        let trimmed = inputUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let targetUrl: URL?
        if isValidURL(trimmed) {
            if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
                targetUrl = URL(string: trimmed)
            } else {
                targetUrl = URL(string: "https://" + trimmed)
            }
        } else {
            let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
            targetUrl = URL(string: "https://www.google.com/search?q=\(encoded)")
        }

        if let url = URL(string: targetUrl?.absoluteString ?? "") {
            webViewStore.webView.load(URLRequest(url: url))
        }
    }

    private func isValidURL(_ urlString: String) -> Bool {
        if urlString.contains(" ") { return false }
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") { return true }
        let regex = "^[a-zA-Z0-9-]+(\\.[a-zA-Z0-9-]+)+.*$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: urlString)
    }
}

class WebViewStore: NSObject, ObservableObject, WKNavigationDelegate {
    let webView: WKWebView = WKWebView()
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    @Published var progress: Double = 0.0
    @Published var currentUrl: URL? = nil

    private var progressObservation: NSKeyValueObservation?
    private var loadingObservation: NSKeyValueObservation?

    override init() {
        super.init()
        webView.navigationDelegate = self
        
        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            DispatchQueue.main.async {
                self?.progress = webView.estimatedProgress
            }
        }
        
        loadingObservation = webView.observe(\.isLoading, options: [.new]) { [weak self] webView, _ in
            DispatchQueue.main.async {
                self?.isLoading = webView.isLoading
            }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        currentUrl = webView.url
    }
}

struct WebViewWrapper: UIViewRepresentable {
    @ObservedObject var store: WebViewStore

    func makeUIView(context: Context) -> WKWebView {
        return store.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
