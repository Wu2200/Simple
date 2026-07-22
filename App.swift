import UIKit
import WebKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = BrowserViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

final class BrowserViewController: UIViewController, WKNavigationDelegate, UITextFieldDelegate {
    private let webView: WKWebView
    private let topBar = UIView()
    private let addressContainer = UIView()
    private let addressField = UITextField()
    private let refreshButton = UIButton(type: .system)
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let homeView = UIView()
    private let bottomBar = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    private let backButton = UIButton(type: .system)
    private let forwardButton = UIButton(type: .system)
    private let homeButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private let moreButton = UIButton(type: .system)
    private let noticeLabel = UILabel()

    private var progressObservation: NSKeyValueObservation?
    private var loadingObservation: NSKeyValueObservation?
    private var isShowingHome = true

    init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        webView = WKWebView(frame: .zero, configuration: configuration)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .darkContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureInterface()
        configureWebView()
        configureObservers()
        showHome(animated: false)
    }

    deinit {
        progressObservation?.invalidate()
        loadingObservation?.invalidate()
    }

    private func configureInterface() {
        view.backgroundColor = .systemBackground

        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.backgroundColor = .systemBackground

        addressContainer.translatesAutoresizingMaskIntoConstraints = false
        addressContainer.backgroundColor = .secondarySystemBackground
        addressContainer.layer.cornerRadius = 12
        addressContainer.clipsToBounds = true

        addressField.translatesAutoresizingMaskIntoConstraints = false
        addressField.delegate = self
        addressField.placeholder = "搜索或输入网址"
        addressField.font = .systemFont(ofSize: 16)
        addressField.textColor = .label
        addressField.keyboardType = .webSearch
        addressField.returnKeyType = .go
        addressField.autocapitalizationType = .none
        addressField.autocorrectionType = .no
        addressField.clearButtonMode = .whileEditing
        addressField.textContentType = .URL

        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = .secondaryLabel
        searchIcon.contentMode = .center
        searchIcon.frame = CGRect(x: 0, y: 0, width: 38, height: 38)
        addressField.leftView = searchIcon
        addressField.leftViewMode = .always

        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.tintColor = .systemBlue
        refreshButton.backgroundColor = .secondarySystemBackground
        refreshButton.layer.cornerRadius = 20
        refreshButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        refreshButton.addTarget(self, action: #selector(reloadOrStop), for: .touchUpInside)

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = .clear
        progressView.alpha = 0

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.backgroundColor = .systemBackground
        webView.isOpaque = false

        homeView.translatesAutoresizingMaskIntoConstraints = false
        homeView.backgroundColor = .systemBackground

        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.layer.cornerRadius = 22
        bottomBar.clipsToBounds = true
        bottomBar.layer.shadowColor = UIColor.black.cgColor
        bottomBar.layer.shadowOpacity = 0.12
        bottomBar.layer.shadowRadius = 16
        bottomBar.layer.shadowOffset = CGSize(width: 0, height: 6)

        noticeLabel.translatesAutoresizingMaskIntoConstraints = false
        noticeLabel.textAlignment = .center
        noticeLabel.font = .systemFont(ofSize: 13, weight: .medium)
        noticeLabel.textColor = .white
        noticeLabel.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        noticeLabel.layer.cornerRadius = 12
        noticeLabel.clipsToBounds = true
        noticeLabel.alpha = 0

        configureBottomButtons()
        configureHomeView()

        topBar.addSubview(addressContainer)
        topBar.addSubview(refreshButton)
        addressContainer.addSubview(addressField)

        view.addSubview(topBar)
        view.addSubview(progressView)
        view.addSubview(webView)
        view.addSubview(homeView)
        view.addSubview(bottomBar)
        view.addSubview(noticeLabel)

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 60),

            addressContainer.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            addressContainer.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            addressContainer.heightAnchor.constraint(equalToConstant: 40),

            refreshButton.leadingAnchor.constraint(equalTo: addressContainer.trailingAnchor, constant: 10),
            refreshButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16),
            refreshButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            refreshButton.widthAnchor.constraint(equalToConstant: 40),
            refreshButton.heightAnchor.constraint(equalToConstant: 40),

            addressField.leadingAnchor.constraint(equalTo: addressContainer.leadingAnchor, constant: 2),
            addressField.trailingAnchor.constraint(equalTo: addressContainer.trailingAnchor, constant: -8),
            addressField.topAnchor.constraint(equalTo: addressContainer.topAnchor),
            addressField.bottomAnchor.constraint(equalTo: addressContainer.bottomAnchor),

            progressView.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            progressView.heightAnchor.constraint(equalToConstant: 2),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            bottomBar.heightAnchor.constraint(equalToConstant: 54),

            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 4),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -12),

            homeView.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 4),
            homeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            homeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            homeView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -12),

            noticeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noticeLabel.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -14),
            noticeLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -48),
            noticeLabel.heightAnchor.constraint(equalToConstant: 36)
        ])

        addressContainer.trailingAnchor.constraint(equalTo: refreshButton.leadingAnchor, constant: -10).isActive = true
    }

    private func configureBottomButtons() {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 0

        configureBarButton(backButton, imageName: "chevron.backward", action: #selector(goBack))
        configureBarButton(forwardButton, imageName: "chevron.forward", action: #selector(goForward))
        configureBarButton(homeButton, imageName: "house.fill", action: #selector(showHomeFromButton))
        configureBarButton(shareButton, imageName: "square.and.arrow.up", action: #selector(sharePage))
        configureBarButton(moreButton, imageName: "ellipsis", action: #selector(showMoreMenu))

        stackView.addArrangedSubview(backButton)
        stackView.addArrangedSubview(forwardButton)
        stackView.addArrangedSubview(homeButton)
        stackView.addArrangedSubview(shareButton)
        stackView.addArrangedSubview(moreButton)

        bottomBar.contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: bottomBar.contentView.topAnchor, constant: 3),
            stackView.leadingAnchor.constraint(equalTo: bottomBar.contentView.leadingAnchor, constant: 6),
            stackView.trailingAnchor.constraint(equalTo: bottomBar.contentView.trailingAnchor, constant: -6),
            stackView.bottomAnchor.constraint(equalTo: bottomBar.contentView.bottomAnchor, constant: -3)
        ])
    }

    private func configureBarButton(_ button: UIButton, imageName: String, action: Selector) {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: imageName)
        configuration.baseForegroundColor = .systemBlue
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 19, weight: .medium)

        button.configuration = configuration
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func configureHomeView() {
        let logoContainer = UIView()
        logoContainer.translatesAutoresizingMaskIntoConstraints = false
        logoContainer.backgroundColor = .systemBlue
        logoContainer.layer.cornerRadius = 24

        let logoImage = UIImageView(image: UIImage(systemName: "safari.fill"))
        logoImage.translatesAutoresizingMaskIntoConstraints = false
        logoImage.tintColor = .white
        logoImage.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 26, weight: .medium)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "简阅"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "搜索，或在顶部输入网址"
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = .secondaryLabel

        let googleButton = makeShortcutButton(title: "Google", imageName: "magnifyingglass", tag: 1)
        let baiduButton = makeShortcutButton(title: "百度", imageName: "pawprint.fill", tag: 2)
        let githubButton = makeShortcutButton(title: "GitHub", imageName: "chevron.left.forwardslash.chevron.right", tag: 3)
        let stackView = UIStackView(arrangedSubviews: [googleButton, baiduButton, githubButton])

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 12

        homeView.addSubview(logoContainer)
        logoContainer.addSubview(logoImage)
        homeView.addSubview(titleLabel)
        homeView.addSubview(subtitleLabel)
        homeView.addSubview(stackView)

        NSLayoutConstraint.activate([
            logoContainer.topAnchor.constraint(equalTo: homeView.topAnchor, constant: 88),
            logoContainer.centerXAnchor.constraint(equalTo: homeView.centerXAnchor),
            logoContainer.widthAnchor.constraint(equalToConstant: 48),
            logoContainer.heightAnchor.constraint(equalToConstant: 48),

            logoImage.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            logoImage.centerYAnchor.constraint(equalTo: logoContainer.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: logoContainer.bottomAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: homeView.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: homeView.centerXAnchor),

            stackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 38),
            stackView.leadingAnchor.constraint(equalTo: homeView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: homeView.trailingAnchor, constant: -24),
            stackView.heightAnchor.constraint(equalToConstant: 86)
        ])
    }

    private func makeShortcutButton(title: String, imageName: String, tag: Int) -> UIButton {
        var configuration = UIButton.Configuration.tinted()
        configuration.title = title
        configuration.image = UIImage(systemName: imageName)
        configuration.imagePlacement = .top
        configuration.imagePadding = 8
        configuration.baseForegroundColor = .systemBlue
        configuration.baseBackgroundColor = .systemBlue
        configuration.cornerStyle = .large
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = .systemFont(ofSize: 13, weight: .medium)
            return attributes
        }

        let button = UIButton(type: .system)
        button.tag = tag
        button.configuration = configuration
        button.addTarget(self, action: #selector(openShortcut(_:)), for: .touchUpInside)

        return button
    }

    private func configureWebView() {
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.keyboardDismissMode = .interactive
        webView.scrollView.contentInsetAdjustmentBehavior = .never
    }

    private func configureObservers() {
        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            DispatchQueue.main.async {
                guard let self else {
                    return
                }

                if webView.isLoading {
                    self.progressView.alpha = 1
                    self.progressView.setProgress(Float(webView.estimatedProgress), animated: true)
                }
            }
        }

        loadingObservation = webView.observe(\.isLoading, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.updateNavigationState()
            }
        }
    }

    private func showHome(animated: Bool) {
        isShowingHome = true
        addressField.text = ""
        addressField.resignFirstResponder()

        let changes = {
            self.homeView.alpha = 1
            self.webView.alpha = 0
            self.refreshButton.isEnabled = false
            self.progressView.alpha = 0
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: changes)
        } else {
            changes()
        }

        updateNavigationState()
    }

    private func showBrowser() {
        isShowingHome = false

        UIView.animate(withDuration: 0.18) {
            self.homeView.alpha = 0
            self.webView.alpha = 1
            self.refreshButton.isEnabled = true
        }

        updateNavigationState()
    }

    private func load(url: URL) {
        showBrowser()
        addressField.text = url.absoluteString
        webView.load(URLRequest(url: url))
    }

    private func destinationURL(from input: String) -> URL? {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !value.isEmpty else {
            return nil
        }

        if value.hasPrefix("http://") || value.hasPrefix("https://") {
            return URL(string: value)
        }

        if looksLikeAddress(value) {
            return URL(string: "https://\(value)")
        }

        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: value)]
        return components?.url
    }

    private func looksLikeAddress(_ value: String) -> Bool {
        if value.localizedCaseInsensitiveCompare("localhost") == .orderedSame {
            return true
        }

        return value.contains(".") || value.contains(":")
    }

    private func updateNavigationState() {
        backButton.isEnabled = !isShowingHome && webView.canGoBack
        forwardButton.isEnabled = !isShowingHome && webView.canGoForward
        shareButton.isEnabled = !isShowingHome && webView.url != nil
        moreButton.isEnabled = !isShowingHome

        let imageName = webView.isLoading ? "xmark" : "arrow.clockwise"
        refreshButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    private func showNotice(_ text: String) {
        noticeLabel.text = "  \(text)  "

        UIView.animate(withDuration: 0.18) {
            self.noticeLabel.alpha = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) { [weak self] in
            UIView.animate(withDuration: 0.2) {
                self?.noticeLabel.alpha = 0
            }
        }
    }

    private func showLoadError(_ error: Error) {
        let errorCode = (error as NSError).code

        guard errorCode != NSURLErrorCancelled else {
            return
        }

        let alert = UIAlertController(
            title: "页面无法打开",
            message: (error as NSError).localizedDescription,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "重试", style: .default) { [weak self] _ in
            self?.webView.reload()
        })

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func fallbackURL(from intentURL: URL) -> URL? {
        let value = intentURL.absoluteString

        guard let range = value.range(of: "S.browser_fallback_url=") else {
            return nil
        }

        let start = range.upperBound
        let remainder = String(value[start...])
        let encoded = remainder.components(separatedBy: ";").first ?? remainder
        let decoded = encoded.removingPercentEncoding ?? encoded

        return URL(string: decoded)
    }

    private func handleExternalURL(_ url: URL) {
        if url.scheme?.lowercased() == "intent", let fallbackURL = fallbackURL(from: url) {
            load(url: fallbackURL)
            return
        }

        UIApplication.shared.open(url, options: [:]) { [weak self] success in
            if !success {
                self?.showNotice("该链接需要其他应用打开")
            }
        }
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if isShowingHome {
            textField.text = ""
        }

        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let input = textField.text, let url = destinationURL(from: input) else {
            return true
        }

        textField.resignFirstResponder()
        load(url: url)

        return true
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        showBrowser()
        updateNavigationState()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let url = webView.url {
            addressField.text = url.absoluteString
        }

        updateNavigationState()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url {
            addressField.text = url.absoluteString
        }

        updateNavigationState()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self, !self.webView.isLoading else {
                return
            }

            UIView.animate(withDuration: 0.2) {
                self.progressView.alpha = 0
            }
        }
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        updateNavigationState()
        showLoadError(error)
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        updateNavigationState()
        showLoadError(error)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        let scheme = url.scheme?.lowercased() ?? ""

        if scheme == "http" || scheme == "https" || scheme == "about" || scheme == "data" || scheme == "blob" {
            if navigationAction.targetFrame == nil {
                webView.load(URLRequest(url: url))
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
            return
        }

        decisionHandler(.cancel)
        handleExternalURL(url)
    }

    @objc private func reloadOrStop() {
        guard !isShowingHome else {
            return
        }

        if webView.isLoading {
            webView.stopLoading()
        } else {
            webView.reload()
        }

        updateNavigationState()
    }

    @objc private func goBack() {
        webView.goBack()
    }

    @objc private func goForward() {
        webView.goForward()
    }

    @objc private func showHomeFromButton() {
        showHome(animated: true)
    }

    @objc private func sharePage() {
        guard let url = webView.url else {
            return
        }

        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(controller, animated: true)
    }

    @objc private func openShortcut(_ sender: UIButton) {
        let url: URL?

        switch sender.tag {
        case 1:
            url = URL(string: "https://www.google.com")
        case 2:
            url = URL(string: "https://www.baidu.com")
        case 3:
            url = URL(string: "https://github.com")
        default:
            url = nil
        }

        if let url {
            load(url: url)
        }
    }

    @objc private func showMoreMenu() {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if let url = webView.url {
            controller.addAction(UIAlertAction(title: "复制当前链接", style: .default) { _ in
                UIPasteboard.general.url = url
            })

            controller.addAction(UIAlertAction(title: "在 Safari 中打开", style: .default) { _ in
                UIApplication.shared.open(url)
            })
        }

        controller.addAction(UIAlertAction(title: "清除浏览数据", style: .destructive) { [weak self] _ in
            self?.clearBrowsingData()
        })

        controller.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(controller, animated: true)
    }

    private func clearBrowsingData() {
        WKWebsiteDataStore.default().removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: .distantPast
        ) { [weak self] in
            self?.showNotice("浏览数据已清除")
        }
    }
}
