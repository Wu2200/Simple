import UIKit
import WebKit

final class WebsiteDataManagerViewController: UITableViewController {
    private var records: [WKWebsiteDataRecord] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "管理网站数据"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DataRecordCell")

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "关闭", style: .plain, target: self, action: #selector(handleDone))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "清理缓存", style: .plain, target: self, action: #selector(handleCleanAllCaches))
        loadData()
    }

    private func loadData() {
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: types) { [weak self] records in
            DispatchQueue.main.async {
                self?.records = records.sorted { $0.displayName < $1.displayName }
                self?.tableView.reloadData()
            }
        }
    }

    @objc private func handleDone() {
        dismiss(animated: true)
    }

    @objc private func handleCleanAllCaches() {
        let alert = UIAlertController(title: "清理所有临时缓存", message: "将清理网页缓存文件，受保护网站的登录与本地数据将被保留。", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "清理缓存", style: .destructive) { [weak self] _ in
            WebsiteCleaner.shared.cleanCacheOnly {
                self?.loadData()
            }
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "DataRecordCell")
        let record = records[indexPath.row]
        let isLocked = CookieLockStore.shared.isLocked(domain: record.displayName)

        var content = cell.defaultContentConfiguration()
        content.text = record.displayName + (isLocked ? " 🔒" : "")
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < records.count else { return }
        let record = records[indexPath.row]

        let detailVC = DomainDataDetailViewController(record: record) { [weak self] in
            self?.loadData()
        }
        navigationController?.pushViewController(detailVC, animated: true)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let record = records[indexPath.row]
            let isLocked = CookieLockStore.shared.isLocked(domain: record.displayName)

            if isLocked {
                let alert = UIAlertController(title: "受保护网站", message: "\(record.displayName) 开启了数据保护，是否仅清理该网站缓存？", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "仅清理缓存", style: .default) { [weak self] _ in
                    WebsiteCleaner.shared.cleanSingleDomain(record: record, cacheOnly: true) {
                        self?.loadData()
                    }
                })
                alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                present(alert, animated: true)
                return
            }

            WebsiteCleaner.shared.cleanSingleDomain(record: record, cacheOnly: false) { [weak self] in
                self?.loadData()
            }
        }
    }
}

final class DomainDataDetailViewController: UITableViewController {
    private var record: WKWebsiteDataRecord
    private var isProtected: Bool
    var onDataChanged: (() -> Void)?

    init(record: WKWebsiteDataRecord, onDataChanged: (() -> Void)?) {
        self.record = record
        self.isProtected = CookieLockStore.shared.isLocked(domain: record.displayName)
        self.onDataChanged = onDataChanged
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = record.displayName
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DetailCell")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 1 }
        return 2
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { return "数据保护" }
        return "数据管理操作"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "DetailCell")

        if indexPath.section == 0 {
            cell.textLabel?.text = "保护登录与本地数据"
            let toggle = UISwitch()
            toggle.isOn = isProtected
            toggle.addTarget(self, action: #selector(handleProtectionToggle(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        } else {
            if indexPath.row == 0 {
                cell.textLabel?.text = "清理该网站临时缓存"
                cell.textLabel?.textColor = .systemBlue
                cell.textLabel?.textAlignment = .center
            } else {
                cell.textLabel?.text = isProtected ? "解除保护并完全重置网站" : "完全重置该网站"
                cell.textLabel?.textColor = .systemRed
                cell.textLabel?.textAlignment = .center
            }
        }

        return cell
    }

    @objc private func handleProtectionToggle(_ sender: UISwitch) {
        CookieLockStore.shared.toggleLock(domain: record.displayName)
        isProtected = sender.isOn
        tableView.reloadData()
        onDataChanged?()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 1 {
            if indexPath.row == 0 {
                WebsiteCleaner.shared.cleanSingleDomain(record: record, cacheOnly: true) { [weak self] in
                    self?.onDataChanged?()
                    self?.navigationController?.popViewController(animated: true)
                }
            } else {
                let title = isProtected ? "确定解除保护并删除吗？" : "确定重置该网站吗？"
                let alert = UIAlertController(title: title, message: "将清除 \(record.displayName) 的所有 Cookies、缓存与本地数据库。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "重置删除", style: .destructive) { [weak self] _ in
                    guard let self = self else { return }
                    if self.isProtected {
                        CookieLockStore.shared.toggleLock(domain: self.record.displayName)
                    }
                    WebsiteCleaner.shared.cleanSingleDomain(record: self.record, cacheOnly: false) {
                        self.onDataChanged?()
                        self.navigationController?.popViewController(animated: true)
                    }
                })
                alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                present(alert, animated: true)
            }
        }
    }
}

final class DomainSettingsViewController: UITableViewController {
    private let domain: String
    var onSettingsChanged: (() -> Void)?
    var onExtractText: (() -> Void)?

    init(domain: String, onSettingsChanged: (() -> Void)?) {
        self.domain = domain
        self.onSettingsChanged = onSettingsChanged
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = domain
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(handleDone))
    }

    @objc private func handleDone() {
        dismiss(animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 3 : 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)

        if indexPath.section == 0 {
            let switchView = UISwitch()
            switchView.tag = indexPath.row

            if indexPath.row == 0 {
                cell.textLabel?.text = "视频悬窗"
                switchView.isOn = DomainSettingsStore.shared.getBool(domain: domain, setting: "videoPopout", defaultVal: false)
                switchView.isEnabled = false
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "广告过滤"
                switchView.isOn = DomainSettingsStore.shared.getBool(domain: domain, setting: "adBlock", defaultVal: false)
                switchView.isEnabled = false
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "用户脚本"
                switchView.isOn = DomainSettingsStore.shared.getBool(domain: domain, setting: "userScripts", defaultVal: true)
                switchView.addTarget(self, action: #selector(handleSwitchChanged(_:)), for: .valueChanged)
            }
            cell.accessoryView = switchView
        } else {
            cell.textLabel?.text = "获取网页所有文字"
            cell.textLabel?.textColor = .systemBlue
            cell.textLabel?.textAlignment = .center
        }

        return cell
    }

    @objc private func handleSwitchChanged(_ sender: UISwitch) {
        if sender.tag == 2 {
            DomainSettingsStore.shared.setBool(domain: domain, setting: "userScripts", value: sender.isOn)
            onSettingsChanged?()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            dismiss(animated: true) { [weak self] in
                self?.onExtractText?()
            }
        }
    }
}

final class UserAgentManagerViewController: UITableViewController {
    private var items: [UserAgentItem] = []
    private var selectedId: String = ""
    var onUASelected: ((String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "浏览器标识"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UACell")

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(handleAddCustomUA)
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "完成",
            style: .done,
            target: self,
            action: #selector(handleDone)
        )

        loadData()
    }

    private func loadData() {
        items = UserAgentStore.shared.loadAllItems()
        selectedId = UserAgentStore.shared.getSelectedId()
        tableView.reloadData()
    }

    @objc private func handleDone() {
        dismiss(animated: true)
    }

    @objc private func handleAddCustomUA() {
        let alert = UIAlertController(title: "添加自定义标识", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "标识名称" }
        alert.addTextField { tf in tf.placeholder = "User-Agent 字符串" }

        alert.addAction(UIAlertAction(title: "添加", style: .default) { [weak self] _ in
            guard let name = alert.textFields?[0].text?.trimmingCharacters(in: .whitespaces), !name.isEmpty,
                  let ua = alert.textFields?[1].text?.trimmingCharacters(in: .whitespaces), !ua.isEmpty else { return }

            UserAgentStore.shared.addCustomItem(name: name, uaString: ua)
            self?.loadData()
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func showEditUAAlert(item: UserAgentItem) {
        let alert = UIAlertController(title: "编辑标识", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "标识名称"
            tf.text = item.name
        }
        alert.addTextField { tf in
            tf.placeholder = "User-Agent 字符串"
            tf.text = item.uaString
        }

        alert.addAction(UIAlertAction(title: "保存", style: .default) { [weak self] _ in
            guard let name = alert.textFields?[0].text?.trimmingCharacters(in: .whitespaces), !name.isEmpty,
                  let ua = alert.textFields?[1].text?.trimmingCharacters(in: .whitespaces), !ua.isEmpty else { return }

            if item.isCustom {
                UserAgentStore.shared.updateCustomItem(id: item.id, name: name, uaString: ua)
            } else {
                UserAgentStore.shared.addCustomItem(name: name, uaString: ua)
            }
            self?.loadData()
            let currentUA = UserAgentStore.shared.getSelectedUA()
            self?.onUASelected?(currentUA)
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UACell", for: indexPath)
        let item = items[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = item.name
        cell.contentConfiguration = content

        cell.accessoryType = item.id == selectedId ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        selectedId = item.id
        UserAgentStore.shared.setSelectedId(item.id)
        tableView.reloadData()

        onUASelected?(item.uaString)
        dismiss(animated: true)
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = items[indexPath.row]

        let editAction = UIContextualAction(style: .normal, title: "编辑") { [weak self] _, _, completion in
            self?.showEditUAAlert(item: item)
            completion(true)
        }
        editAction.backgroundColor = .systemBlue

        if item.isCustom {
            let deleteAction = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
                UserAgentStore.shared.deleteCustomItem(id: item.id)
                self?.loadData()
                let currentUA = UserAgentStore.shared.getSelectedUA()
                self?.onUASelected?(currentUA)
                completion(true)
            }
            return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        } else {
            return UISwipeActionsConfiguration(actions: [editAction])
        }
    }
}

final class UserScriptEditorViewController: UIViewController {
    private var script: UserScript?
    var onSave: ((UserScript) -> Void)?

    private let nameField = UITextField()
    private let matchField = UITextField()
    private let textView = UITextView()

    init(script: UserScript?) {
        self.script = script
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = script == nil ? "新建油猴脚本" : "编辑脚本"
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "保存",
            style: .done,
            target: self,
            action: #selector(handleSave)
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "取消",
            style: .plain,
            target: self,
            action: #selector(handleCancel)
        )

        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.borderStyle = .roundedRect
        nameField.placeholder = "脚本名称"
        nameField.text = script?.name ?? ""

        matchField.translatesAutoresizingMaskIntoConstraints = false
        matchField.borderStyle = .roundedRect
        matchField.placeholder = "匹配域名规则 (如 * 或 google.com)"
        matchField.text = script?.matchPattern ?? "*"

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.layer.borderWidth = 0.5
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.layer.cornerRadius = 8
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.text = script?.code ?? "(function() {\n    'use strict';\n})();"

        view.addSubview(nameField)
        view.addSubview(matchField)
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            nameField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            nameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nameField.heightAnchor.constraint(equalToConstant: 38),

            matchField.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 8),
            matchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            matchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            matchField.heightAnchor.constraint(equalToConstant: 38),

            textView.topAnchor.constraint(equalTo: matchField.bottomAnchor, constant: 12),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    @objc private func handleSave() {
        let codeText = textView.text ?? ""
        var nameText = nameField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        var matchText = matchField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        let parsed = UserScriptStore.shared.parseMetadata(from: codeText)
        if nameText.isEmpty { nameText = parsed.name }
        if matchText.isEmpty { matchText = parsed.match }

        let item = UserScript(
            id: script?.id ?? UUID().uuidString,
            name: nameText,
            matchPattern: matchText,
            code: codeText,
            isEnabled: script?.isEnabled ?? true
        )

        onSave?(item)
        dismiss(animated: true)
    }

    @objc private func handleCancel() {
        dismiss(animated: true)
    }
}
