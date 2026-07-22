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

final class TabItem: NSObject, WKNavigationDelegate {
    let id = UUID()
    let webView: WKWebView
    var title: String = "新标签页"
    var url: URL?
    var isLoading: Bool = false

    weak var delegate: TabItemDelegate?

    override init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        webView = WKWebView(frame: .zero, configuration: config)
        super.init()

        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.keyboardDismissMode = .interactive
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
        delegate?.tabDidUpdate(self)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        url = webView.url
        title = webView.title ?? url?.host ?? "新标签页"
        delegate?.tabDidUpdate(self)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        url = webView.url
        title = webView.title ?? url?.host ?? "新标签页"
        delegate?.tabDidUpdate(self)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        isLoading = false
        delegate?.tabDidFail(self, error: error)
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        isLoading = false
        delegate?.tabDidFail(self, error: error)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let requestUrl = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        let scheme = requestUrl.scheme?.lowercased() ?? ""

        if scheme == "http" || scheme == "https" || scheme == "about" || scheme == "data" || scheme == "blob" {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
            return
        }

        decisionHandler(.cancel)
        UIApplication.shared.open(requestUrl, options: [:], completionHandler: nil)
    }
}

protocol TabItemDelegate: AnyObject {
    func tabDidUpdate(_ tab: TabItem)
    func tabDidFail(_ tab: TabItem, error: Error)
}

final class BrowserViewController: UIViewController, UITextFieldDelegate, TabItemDelegate {
    private var tabs: [TabItem] = []
    private var activeTabIndex: Int = 0

    private var activeTab: TabItem {
        tabs[activeTabIndex]
    }

    private let topBar = UIView()
    private let addressContainer = UIView()
    private let addressField = UITextField()
    private let inlineRefreshButton = UIButton(type: .system)
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let webContainer = UIView()
    private let homeView = UIView()
    private let floatingBar = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))

    private let backButton = UIButton(type: .system)
    private let forwardButton = UIButton(type: .system)
    private let homeButton = UIButton(type: .system)
    private let tabsButton = UIButton(type: .system)
    private let tabsBadgeLabel = UILabel()
    private let moreButton = UIButton(type: .system)

    private var progressObservation: NSKeyValueObservation?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .darkContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureInterface()
        createNewTab(loadURL: nil)
    }

    deinit {
        progressObservation?.invalidate()
    }

    private func configureInterface() {
        view.backgroundColor = .systemBackground

        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.backgroundColor = .systemBackground

        addressContainer.translatesAutoresizingMaskIntoConstraints = false
        addressContainer.backgroundColor = .tertiarySystemFill
        addressContainer.layer.cornerRadius = 14
        addressContainer.clipsToBounds = true

        addressField.translatesAutoresizingMaskIntoConstraints = false
        addressField.delegate = self
        addressField.placeholder = "搜索或输入网址"
        addressField.font = .systemFont(ofSize: 15, weight: .regular)
        addressField.textColor = .label
        addressField.keyboardType = .webSearch
        addressField.returnKeyType = .go
        addressField.autocapitalizationType = .none
        addressField.autocorrectionType = .no
        addressField.clearButtonMode = .whileEditing
        addressField.textContentType = .URL

        inlineRefreshButton.translatesAutoresizingMaskIntoConstraints = false
        inlineRefreshButton.tintColor = .secondaryLabel
        inlineRefreshButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        inlineRefreshButton.addTarget(self, action: #selector(handleRefreshTap), for: .touchUpInside)

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = .clear
        progressView.alpha = 0

        webContainer.translatesAutoresizingMaskIntoConstraints = false
        webContainer.backgroundColor = .systemBackground

        homeView.translatesAutoresizingMaskIntoConstraints = false
        homeView.backgroundColor = .systemBackground

        floatingBar.translatesAutoresizingMaskIntoConstraints = false
        floatingBar.layer.cornerRadius = 27
        floatingBar.clipsToBounds = true
        floatingBar.layer.shadowColor = UIColor.black.cgColor
        floatingBar.layer.shadowOpacity = 0.14
        floatingBar.layer.shadowRadius = 18
        floatingBar.layer.shadowOffset = CGSize(width: 0, height: 6)

        configureHomeView()
        configureFloatingButtons()

        addressContainer.addSubview(addressField)
        addressContainer.addSubview(inlineRefreshButton)
        topBar.addSubview(addressContainer)

        view.addSubview(topBar)
        view.addSubview(progressView)
        view.addSubview(webContainer)
        view.addSubview(homeView)
        view.addSubview(floatingBar)

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 50),

            addressContainer.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            addressContainer.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16),
            addressContainer.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            addressContainer.heightAnchor.constraint(equalToConstant: 38),

            addressField.leadingAnchor.constraint(equalTo: addressContainer.leadingAnchor, constant: 14),
            addressField.trailingAnchor.constraint(equalTo: inlineRefreshButton.leadingAnchor, constant: -4),
            addressField.topAnchor.constraint(equalTo: addressContainer.topAnchor),
            addressField.bottomAnchor.constraint(equalTo: addressContainer.bottomAnchor),

            inlineRefreshButton.trailingAnchor.constraint(equalTo: addressContainer.trailingAnchor, constant: -6),
            inlineRefreshButton.centerYAnchor.constraint(equalTo: addressContainer.centerYAnchor),
            inlineRefreshButton.widthAnchor.constraint(equalToConstant: 28),
            inlineRefreshButton.heightAnchor.constraint(equalToConstant: 28),

            progressView.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            progressView.heightAnchor.constraint(equalToConstant: 2),

            floatingBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            floatingBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            floatingBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            floatingBar.heightAnchor.constraint(equalToConstant: 54),

            webContainer.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            homeView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            homeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            homeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            homeView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureFloatingButtons() {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 0

        configurePillButton(backButton, icon: "chevron.backward", action: #selector(goBack))
        configurePillButton(forwardButton, icon: "chevron.forward", action: #selector(goForward))
        configurePillButton(homeButton, icon: "house.fill", action: #selector(goHome))
        configurePillButton(tabsButton, icon: "square.on.square", action: #selector(showTabsManager))
        configurePillButton(moreButton, icon: "ellipsis", action: #selector(showMoreMenu))

        tabsBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        tabsBadgeLabel.font = .systemFont(ofSize: 10, weight: .bold)
        tabsBadgeLabel.textColor = .systemBlue
        tabsBadgeLabel.textAlignment = .center
        tabsButton.addSubview(tabsBadgeLabel)

        NSLayoutConstraint.activate([
            tabsBadgeLabel.centerXAnchor.constraint(equalTo: tabsButton.centerXAnchor),
            tabsBadgeLabel.centerYAnchor.constraint(equalTo: tabsButton.centerYAnchor, constant: 1)
        ])

        stack.addArrangedSubview(backButton)
        stack.addArrangedSubview(forwardButton)
        stack.addArrangedSubview(homeButton)
        stack.addArrangedSubview(tabsButton)
        stack.addArrangedSubview(moreButton)

        floatingBar.contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: floatingBar.contentView.topAnchor, constant: 2),
            stack.leadingAnchor.constraint(equalTo: floatingBar.contentView.leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: floatingBar.contentView.trailingAnchor, constant: -6),
            stack.bottomAnchor.constraint(equalTo: floatingBar.contentView.bottomAnchor, constant: -2)
        ])
    }

    private func configurePillButton(_ button: UIButton, icon: String, action: Selector) {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: icon)
        config.baseForegroundColor = .label
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)

        button.configuration = config
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
        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = .label

        let googleButton = makeShortcut(title: "Google", icon: "magnifyingglass", tag: 1)
        let baiduButton = makeShortcut(title: "百度", icon: "pawprint.fill", tag: 2)
        let githubButton = makeShortcut(title: "GitHub", icon: "chevron.left.forwardslash.chevron.right", tag: 3)

        let stack = UIStackView(arrangedSubviews: [googleButton, baiduButton, githubButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 12

        homeView.addSubview(logoContainer)
        logoContainer.addSubview(logoImage)
        homeView.addSubview(titleLabel)
        homeView.addSubview(stack)

        NSLayoutConstraint.activate([
            logoContainer.topAnchor.constraint(equalTo: homeView.topAnchor, constant: 100),
            logoContainer.centerXAnchor.constraint(equalTo: homeView.centerXAnchor),
            logoContainer.widthAnchor.constraint(equalToConstant: 48),
            logoContainer.heightAnchor.constraint(equalToConstant: 48),

            logoImage.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            logoImage.centerYAnchor.constraint(equalTo: logoContainer.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: logoContainer.bottomAnchor, constant: 14),
            titleLabel.centerXAnchor.constraint(equalTo: homeView.centerXAnchor),

            stack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            stack.leadingAnchor.constraint(equalTo: homeView.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: homeView.trailingAnchor, constant: -28),
            stack.heightAnchor.constraint(equalToConstant: 80)
        ])
    }

    private func makeShortcut(title: String, icon: String, tag: Int) -> UIButton {
        var config = UIButton.Configuration.tinted()
        config.title = title
        config.image = UIImage(systemName: icon)
        config.imagePlacement = .top
        config.imagePadding = 6
        config.baseForegroundColor = .systemBlue
        config.baseBackgroundColor = .systemBlue
        config.cornerStyle = .large

        let button = UIButton(type: .system)
        button.tag = tag
        button.configuration = config
        button.addTarget(self, action: #selector(openShortcut(_:)), for: .touchUpInside)

        return button
    }

    private func createNewTab(loadURL url: URL?) {
        let newTab = TabItem()
        newTab.delegate = self
        tabs.append(newTab)
        switchTab(to: tabs.count - 1)

        if let url = url {
            load(url: url)
        }
    }

    private func switchTab(to index: Int) {
        guard index >= 0 && index < tabs.count else { return }

        activeTab.webView.removeFromSuperview()
        activeTabIndex = index

        let current = activeTab
        current.webView.translatesAutoresizingMaskIntoConstraints = false
        webContainer.addSubview(current.webView)

        NSLayoutConstraint.activate([
            current.webView.topAnchor.constraint(equalTo: webContainer.topAnchor),
            current.webView.leadingAnchor.constraint(equalTo: webContainer.leadingAnchor),
            current.webView.trailingAnchor.constraint(equalTo: webContainer.trailingAnchor),
            current.webView.bottomAnchor.constraint(equalTo: webContainer.bottomAnchor)
        ])

        bindProgressObservation(for: current.webView)

        if let currentURL = current.url {
            showBrowserUI()
            addressField.text = currentURL.absoluteString
        } else {
            showHomeUI()
        }

        updateUIState()
    }

    private func closeTab(at index: Int) {
        guard index >= 0 && index < tabs.count else { return }

        let targetTab = tabs[index]
        targetTab.webView.removeFromSuperview()
        tabs.remove(at: index)

        if tabs.isEmpty {
            createNewTab(loadURL: nil)
        } else {
            let nextIndex = min(index, tabs.count - 1)
            switchTab(to: nextIndex)
        }
    }

    private func bindProgressObservation(for webView: WKWebView) {
        progressObservation?.invalidate()
        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if webView.isLoading {
                    self.progressView.alpha = 1
                    self.progressView.setProgress(Float(webView.estimatedProgress), animated: true)
                }
            }
        }
    }

    private func load(url: URL) {
        showBrowserUI()
        addressField.text = url.absoluteString
        activeTab.webView.load(URLRequest(url: url))
    }

    private func showHomeUI() {
        homeView.alpha = 1
        webContainer.alpha = 0
        addressField.text = ""
        addressField.resignFirstResponder()
        progressView.alpha = 0
        updateUIState()
    }

    private func showBrowserUI() {
        homeView.alpha = 0
        webContainer.alpha = 1
        updateUIState()
    }

    private func updateUIState() {
        let isHome = homeView.alpha == 1
        backButton.isEnabled = !isHome && activeTab.webView.canGoBack
        forwardButton.isEnabled = !isHome && activeTab.webView.canGoForward
        moreButton.isEnabled = !isHome

        let refreshIcon = activeTab.isLoading ? "xmark" : "arrow.clockwise"
        inlineRefreshButton.setImage(UIImage(systemName: refreshIcon), for: .normal)

        tabsBadgeLabel.text = "\(tabs.count)"
    }

    private func destinationURL(from input: String) -> URL? {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }

        if value.hasPrefix("http://") || value.hasPrefix("https://") {
            return URL(string: value)
        }

        if value.contains(".") && !value.contains(" ") {
            return URL(string: "https://\(value)")
        }

        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: value)]
        return components?.url
    }

    func tabDidUpdate(_ tab: TabItem) {
        guard tab == activeTab else { return }
        if let url = tab.url {
            addressField.text = url.absoluteString
        }
        updateUIState()

        if !tab.isLoading {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                UIView.animate(withDuration: 0.2) {
                    self?.progressView.alpha = 0
                }
            }
        }
    }

    func tabDidFail(_ tab: TabItem, error: Error) {
        guard tab == activeTab else { return }
        updateUIState()

        let nsError = error as NSError
        guard nsError.code != NSURLErrorCancelled else { return }

        let alert = UIAlertController(title: "无法访问页面", message: nsError.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text, let url = destinationURL(from: text) else { return true }
        textField.resignFirstResponder()
        load(url: url)
        return true
    }

    @objc private func handleRefreshTap() {
        if homeView.alpha == 1 { return }

        if activeTab.isLoading {
            activeTab.webView.stopLoading()
        } else {
            activeTab.webView.reload()
        }
        updateUIState()
    }

    @objc private func goBack() {
        activeTab.webView.goBack()
    }

    @objc private func goForward() {
        activeTab.webView.goForward()
    }

    @objc private func goHome() {
        showHomeUI()
    }

    @objc private func showTabsManager() {
        let manager = TabManagerViewController(tabs: tabs, activeIndex: activeTabIndex)
        manager.onSelectTab = { [weak self] index in
            self?.switchTab(to: index)
        }
        manager.onCloseTab = { [weak self] index in
            self?.closeTab(at: index)
        }
        manager.onNewTab = { [weak self] in
            self?.createNewTab(loadURL: nil)
        }

        let nav = UINavigationController(rootViewController: manager)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    @objc private func openShortcut(_ sender: UIButton) {
        let urlString: String
        switch sender.tag {
        case 1: urlString = "https://www.google.com"
        case 2: urlString = "https://www.baidu.com"
        case 3: urlString = "https://github.com"
        default: return
        }

        if let url = URL(string: urlString) {
            load(url: url)
        }
    }

    @objc private func showMoreMenu() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if let url = activeTab.url {
            alert.addAction(UIAlertAction(title: "复制链接", style: .default) { _ in
                UIPasteboard.general.url = url
            })

            alert.addAction(UIAlertAction(title: "在 Safari 打开", style: .default) { _ in
                UIApplication.shared.open(url)
            })
        }

        alert.addAction(UIAlertAction(title: "清除缓存", style: .destructive) { [weak self] _ in
            WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast) {
                self?.activeTab.webView.reload()
            }
        })

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
}

final class TabManagerViewController: UITableViewController {
    private var tabs: [TabItem]
    private var activeIndex: Int

    var onSelectTab: ((Int) -> Void)?
    var onCloseTab: ((Int) -> Void)?
    var onNewTab: (() -> Void)?

    init(tabs: [TabItem], activeIndex: Int) {
        self.tabs = tabs
        self.activeIndex = activeIndex
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "标签页"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TabCell")

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(handleNewTab)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "完成",
            style: .done,
            target: self,
            action: #selector(handleDone)
        )
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tabs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TabCell", for: indexPath)
        let tab = tabs[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = tab.title
        content.secondaryText = tab.url?.absoluteString ?? "主页"
        content.image = UIImage(systemName: indexPath.row == activeIndex ? "checkmark.circle.fill" : "globe")
        cell.contentConfiguration = content

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onSelectTab?(indexPath.row)
        dismiss(animated: true)
    }

    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            let targetIndex = indexPath.row
            tabs.remove(at: targetIndex)

            if activeIndex == targetIndex {
                activeIndex = max(0, targetIndex - 1)
            } else if activeIndex > targetIndex {
                activeIndex -= 1
            }

            tableView.deleteRows(at: [indexPath], with: .automatic)
            onCloseTab?(targetIndex)

            if tabs.isEmpty {
                dismiss(animated: true)
            }
        }
    }

    @objc private func handleNewTab() {
        dismiss(animated: true) { [weak self] in
            self?.onNewTab?()
        }
    }

    @objc private func handleDone() {
        dismiss(animated: true)
    }
}
