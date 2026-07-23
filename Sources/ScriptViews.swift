import UIKit
import WebKit

enum CustomBottomSheetLayout {
    case grid
    case list
}

struct CustomBottomSheetItem {
    let title: String
    var isDestructive: Bool = false
    let handler: (() -> Void)?
}

final class CustomBottomSheetViewController: UIViewController {
    private let titleString: String
    private let items: [CustomBottomSheetItem]
    private let layout: CustomBottomSheetLayout

    private let dimmingView = UIView()
    private let containerView = UIView()

    init(title: String, items: [CustomBottomSheetItem], layout: CustomBottomSheetLayout = .list) {
        self.titleString = title
        self.items = items
        self.layout = layout
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        view.backgroundColor = .clear

        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        let tapDimming = UITapGestureRecognizer(target: self, action: #selector(handleDismiss))
        dimmingView.addGestureRecognizer(tapDimming)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.0)
        containerView.layer.cornerRadius = 24
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.clipsToBounds = true

        let handleBar = UIView()
        handleBar.translatesAutoresizingMaskIntoConstraints = false
        handleBar.backgroundColor = .systemGray4
        handleBar.layer.cornerRadius = 2.5

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.text = titleString

        let closeButton = TouchButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.tintColor = .tertiaryLabel
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)), for: .normal)
        closeButton.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)

        let contentContainer = UIView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false

        if layout == .grid {
            setupGridLayout(in: contentContainer)
        } else {
            setupListLayout(in: contentContainer)
        }

        containerView.addSubview(handleBar)
        containerView.addSubview(titleLabel)
        containerView.addSubview(closeButton)
        containerView.addSubview(contentContainer)

        view.addSubview(dimmingView)
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            handleBar.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            handleBar.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            handleBar.widthAnchor.constraint(equalToConstant: 36),
            handleBar.heightAnchor.constraint(equalToConstant: 5),

            titleLabel.topAnchor.constraint(equalTo: handleBar.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),

            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28),

            contentContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            contentContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            contentContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            contentContainer.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    private func setupGridLayout(in container: UIView) {
        let mainStack = UIStackView()
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.axis = .vertical
        mainStack.spacing = 8

        let gridItems = items.filter { !$0.isDestructive }
        let destructiveItems = items.filter { $0.isDestructive }

        var rowStack: UIStackView?
        for (idx, item) in gridItems.enumerated() {
            if idx % 2 == 0 {
                rowStack = UIStackView()
                rowStack?.axis = .horizontal
                rowStack?.spacing = 8
                rowStack?.distribution = .fillEqually
                mainStack.addArrangedSubview(rowStack!)
            }

            let card = createCardButton(item: item, tag: idx, height: 44)
            rowStack?.addArrangedSubview(card)
        }

        if gridItems.count % 2 != 0 {
            let spacer = UIView()
            rowStack?.addArrangedSubview(spacer)
        }

        for item in destructiveItems {
            let idx = items.firstIndex(where: { $0.title == item.title }) ?? 0
            let card = createCardButton(item: item, tag: idx, height: 44)
            mainStack.addArrangedSubview(card)
        }

        container.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: container.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    private func setupListLayout(in container: UIView) {
        let itemsStack = UIStackView()
        itemsStack.translatesAutoresizingMaskIntoConstraints = false
        itemsStack.axis = .vertical
        itemsStack.spacing = 6

        for (idx, item) in items.enumerated() {
            let card = createCardButton(item: item, tag: idx, height: 44)
            itemsStack.addArrangedSubview(card)
        }

        container.addSubview(itemsStack)
        NSLayoutConstraint.activate([
            itemsStack.topAnchor.constraint(equalTo: container.topAnchor),
            itemsStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            itemsStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            itemsStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    private func createCardButton(item: CustomBottomSheetItem, tag: Int, height: CGFloat) -> TouchButton {
        let card = TouchButton(type: .custom)
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .white
        card.layer.cornerRadius = 14
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.03
        card.layer.shadowRadius = 6
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.clipsToBounds = false
        card.tag = tag
        card.addTarget(self, action: #selector(handleItemTap(_:)), for: .touchUpInside)

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = item.isDestructive ? .systemRed : .label
        label.text = item.title
        label.textAlignment = .center
        label.numberOfLines = 1

        card.addSubview(label)
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: height),
            label.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: card.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -8)
        ])

        return card
    }

    @objc private func handleItemTap(_ sender: UIButton) {
        let item = items[sender.tag]
        dismiss(animated: true) {
            item.handler?()
        }
    }

    @objc private func handleDismiss() {
        dismiss(animated: true)
    }
}

final class UserScriptManagerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    private var allScripts: [UserScript] = []
    private var filteredScripts: [UserScript] = []

    var onScriptsUpdated: (() -> Void)?

    private let searchField = UITextField()
    private let tableView = UITableView(frame: .zero, style: .plain)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.0)
        setupInterface()
        loadData()
    }

    private func setupInterface() {
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.text = "管理面板"

        let addButton = TouchButton(type: .system)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)), for: .normal)
        addButton.tintColor = .systemRed
        addButton.addTarget(self, action: #selector(handleAddScript), for: .touchUpInside)

        let closeButton = TouchButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)), for: .normal)
        closeButton.tintColor = .tertiaryLabel
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)

        headerView.addSubview(titleLabel)
        headerView.addSubview(addButton)
        headerView.addSubview(closeButton)

        let searchContainer = UIView()
        searchContainer.translatesAutoresizingMaskIntoConstraints = false
        searchContainer.backgroundColor = UIColor(white: 0.9, alpha: 0.5)
        searchContainer.layer.cornerRadius = 10
        searchContainer.clipsToBounds = true

        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        searchIcon.tintColor = .secondaryLabel

        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.placeholder = "搜索"
        searchField.font = .systemFont(ofSize: 15)
        searchField.delegate = self
        searchField.addTarget(self, action: #selector(handleSearchChanged), for: .editingChanged)

        searchContainer.addSubview(searchIcon)
        searchContainer.addSubview(searchField)

        let sectionHeader = UILabel()
        sectionHeader.translatesAutoresizingMaskIntoConstraints = false
        sectionHeader.font = .systemFont(ofSize: 12, weight: .semibold)
        sectionHeader.textColor = .secondaryLabel
        sectionHeader.text = "USERSCRIPT"

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UserScriptRowCell.self, forCellReuseIdentifier: "UserScriptRowCell")

        view.addSubview(headerView)
        view.addSubview(searchContainer)
        view.addSubview(sectionHeader)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            headerView.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28),

            addButton.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -16),
            addButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 28),
            addButton.heightAnchor.constraint(equalToConstant: 28),

            searchContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 14),
            searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            searchContainer.heightAnchor.constraint(equalToConstant: 36),

            searchIcon.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 10),
            searchIcon.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            searchIcon.widthAnchor.constraint(equalToConstant: 16),
            searchIcon.heightAnchor.constraint(equalToConstant: 16),

            searchField.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 8),
            searchField.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -10),
            searchField.topAnchor.constraint(equalTo: searchContainer.topAnchor),
            searchField.bottomAnchor.constraint(equalTo: searchContainer.bottomAnchor),

            sectionHeader.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 16),
            sectionHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            tableView.topAnchor.constraint(equalTo: sectionHeader.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
    }

    private func loadData() {
        allScripts = UserScriptStore.shared.loadScripts()
        applyFilter()
    }

    private func applyFilter() {
        let query = searchField.text?.trimmingCharacters(in: .whitespaces).lowercased() ?? ""
        if query.isEmpty {
            filteredScripts = allScripts
        } else {
            filteredScripts = allScripts.filter { $0.name.lowercased().contains(query) || $0.matchPattern.lowercased().contains(query) }
        }
        tableView.reloadData()
    }

    @objc private func handleSearchChanged() {
        applyFilter()
    }

    @objc private func handleAddScript() {
        let editor = UserScriptEditorViewController(script: nil)
        editor.onSave = { [weak self] newScript in
            self?.allScripts.append(newScript)
            UserScriptStore.shared.saveScripts(self?.allScripts ?? [])
            self?.loadData()
            self?.onScriptsUpdated?()
        }
        let nav = UINavigationController(rootViewController: editor)
        present(nav, animated: true)
    }

    @objc private func handleClose() {
        dismiss(animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredScripts.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 74
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserScriptRowCell", for: indexPath) as! UserScriptRowCell
        let script = filteredScripts[indexPath.row]
        cell.configure(script: script, index: indexPath.row)
        cell.onToggle = { [weak self] isEnabled in
            guard let self = self else { return }
            if let idx = self.allScripts.firstIndex(where: { $0.id == script.id }) {
                self.allScripts[idx].isEnabled = isEnabled
                UserScriptStore.shared.saveScripts(self.allScripts)
                self.onScriptsUpdated?()
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let script = filteredScripts[indexPath.row]
        let editor = UserScriptEditorViewController(script: script)
        editor.onSave = { [weak self] updatedScript in
            if let idx = self?.allScripts.firstIndex(where: { $0.id == updatedScript.id }) {
                self?.allScripts[idx] = updatedScript
                UserScriptStore.shared.saveScripts(self?.allScripts ?? [])
                self?.loadData()
                self?.onScriptsUpdated?()
            }
        }
        let nav = UINavigationController(rootViewController: editor)
        present(nav, animated: true)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let script = filteredScripts[indexPath.row]
            ScriptDataStore.shared.clearDataForScript(scriptId: script.id)
            allScripts.removeAll { $0.id == script.id }
            UserScriptStore.shared.saveScripts(allScripts)
            applyFilter()
            onScriptsUpdated?()
        }
    }
}

final class UserScriptRowCell: UITableViewCell {
    private let cardView = UIView()
    private let iconView = UIView()
    private let iconLabel = UILabel()
    private let nameLabel = UILabel()
    private let matchLabel = UILabel()
    private let toggleSwitch = UISwitch()

    var onToggle: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.04
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.clipsToBounds = false

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        iconView.layer.cornerRadius = 12
        iconView.clipsToBounds = true

        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconLabel.font = .systemFont(ofSize: 18, weight: .bold)
        iconLabel.textColor = .systemRed
        iconLabel.textAlignment = .center

        iconView.addSubview(iconLabel)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 15, weight: .bold)
        nameLabel.textColor = .label

        matchLabel.translatesAutoresizingMaskIntoConstraints = false
        matchLabel.font = .systemFont(ofSize: 12, weight: .regular)
        matchLabel.textColor = .secondaryLabel
        matchLabel.lineBreakMode = .byTruncatingTail

        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
        toggleSwitch.onTintColor = .systemRed
        toggleSwitch.addTarget(self, action: #selector(handleSwitch), for: .valueChanged)

        let labelStack = UIStackView(arrangedSubviews: [nameLabel, matchLabel])
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        labelStack.axis = .vertical
        labelStack.spacing = 3

        cardView.addSubview(iconView)
        cardView.addSubview(labelStack)
        cardView.addSubview(toggleSwitch)

        contentView.addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),

            iconView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 42),
            iconView.heightAnchor.constraint(equalToConstant: 42),

            iconLabel.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),

            labelStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            labelStack.trailingAnchor.constraint(equalTo: toggleSwitch.leadingAnchor, constant: -10),
            labelStack.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),

            toggleSwitch.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            toggleSwitch.centerYAnchor.constraint(equalTo: cardView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(script: UserScript, index: Int) {
        nameLabel.text = script.name
        matchLabel.text = "匹配: \(script.matchPattern)"
        toggleSwitch.isOn = script.isEnabled

        let firstChar = String(script.name.prefix(1))
        iconLabel.text = firstChar.isEmpty ? "网" : firstChar

        let colors: [UIColor] = [.systemRed, .systemOrange, .systemBlue, .systemPurple, .systemTeal]
        iconLabel.textColor = colors[index % colors.count]
    }

    @objc private func handleSwitch() {
        onToggle?(toggleSwitch.isOn)
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

enum CleanOption: Int, Hashable, CaseIterable {
    case cache = 0
    case loginAndData = 1
    case searchHistory = 2
    case scriptData = 3
}

final class CleanDataSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private var selectedOptions: Set<CleanOption> = [.cache]
    private let savedOptionsKey = "browser_saved_clean_options_v1"

    var onConfirmClean: ((Set<CleanOption>) -> Void)?
    var onOpenWebsiteDataManager: (() -> Void)?

    private let tableView = UITableView(frame: .zero, style: .plain)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "清除数据"
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.0)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(handleCancel))

        setupInterface()
        loadSavedOptions()
    }

    private func setupInterface() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CleanOptionRowCell.self, forCellReuseIdentifier: "CleanOptionRowCell")

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    private func loadSavedOptions() {
        if let saved = UserDefaults.standard.array(forKey: savedOptionsKey) as? [Int] {
            let opts = saved.compactMap { CleanOption(rawValue: $0) }
            selectedOptions = Set(opts)
        }
    }

    private func saveOptions() {
        let rawValues = selectedOptions.map { $0.rawValue }
        UserDefaults.standard.set(rawValues, forKey: savedOptionsKey)
    }

    @objc private func handleCancel() {
        dismiss(animated: true)
    }

    @objc private func requestCleanConfirmation() {
        guard !selectedOptions.isEmpty else {
            dismiss(animated: true)
            return
        }

        var message = "确定要执行清理操作吗？"
        if selectedOptions.contains(.loginAndData) {
            message = "勾选了“登录与本地数据”，未受保护网站的 Cookies 和本地数据库将被清除。"
        }

        let alert = UIAlertController(title: "确认清理", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "确定清理", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            let opts = self.selectedOptions
            self.dismiss(animated: true) {
                self.onConfirmClean?(opts)
            }
        })
        present(alert, animated: true)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 4 }
        return 1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CleanOptionRowCell", for: indexPath) as! CleanOptionRowCell

        if indexPath.section == 0 {
            let option: CleanOption
            let titleText: String
            switch indexPath.row {
            case 0:
                titleText = "网页缓存文件"
                option = .cache
            case 1:
                titleText = "登录与本地数据"
                option = .loginAndData
            case 2:
                titleText = "搜索历史记录"
                option = .searchHistory
            default:
                titleText = "用户脚本缓存数据"
                option = .scriptData
            }

            let isChecked = selectedOptions.contains(option)
            cell.configure(title: titleText, isChecked: isChecked, isDestructive: false)
        } else if indexPath.section == 1 {
            cell.configure(title: "确认清理", isChecked: false, isDestructive: true)
        } else {
            cell.configure(title: "管理网站数据与锁定保护", isChecked: false, isDestructive: false, textColor: .systemBlue)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 {
            let option: CleanOption
            switch indexPath.row {
            case 0: option = .cache
            case 1: option = .loginAndData
            case 2: option = .searchHistory
            default: option = .scriptData
            }

            if selectedOptions.contains(option) {
                selectedOptions.remove(option)
            } else {
                selectedOptions.insert(option)
            }
            saveOptions()
            tableView.reloadRows(at: [indexPath], with: .automatic)
        } else if indexPath.section == 1 {
            requestCleanConfirmation()
        } else {
            dismiss(animated: true) { [weak self] in
                self?.onOpenWebsiteDataManager?()
            }
        }
    }
}

final class CleanOptionRowCell: UITableViewCell {
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let checkIcon = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 14
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.03
        cardView.layer.shadowRadius = 6
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.clipsToBounds = false

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)

        checkIcon.translatesAutoresizingMaskIntoConstraints = false
        checkIcon.image = UIImage(systemName: "checkmark")
        checkIcon.tintColor = .systemBlue

        cardView.addSubview(titleLabel)
        cardView.addSubview(checkIcon)
        contentView.addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),

            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),

            checkIcon.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            checkIcon.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            checkIcon.widthAnchor.constraint(equalToConstant: 18),
            checkIcon.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(title: String, isChecked: Bool, isDestructive: Bool, textColor: UIColor? = nil) {
        titleLabel.text = title
        if let textColor = textColor {
            titleLabel.textColor = textColor
            titleLabel.textAlignment = .center
            titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
            checkIcon.isHidden = true
        } else if isDestructive {
            titleLabel.textColor = .systemRed
            titleLabel.textAlignment = .center
            titleLabel.font = .systemFont(ofSize: 15, weight: .bold)
            checkIcon.isHidden = true
        } else {
            titleLabel.textColor = .label
            titleLabel.textAlignment = .left
            titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
            checkIcon.isHidden = !isChecked
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

final class TabGridViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var tabs: [TabItem]
    private var activeIndex: Int
    private var collectionView: UICollectionView!
    private let addButton = TouchButton(type: .system)

    var onSelectTab: ((Int) -> Void)?
    var onCloseTab: ((Int) -> Void)?
    var onNewTab: (() -> Void)?

    init(tabs: [TabItem], activeIndex: Int) {
        self.tabs = tabs
        self.activeIndex = activeIndex
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "标签页"
        view.backgroundColor = .systemGroupedBackground

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 88, right: 16)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(TabGridCell.self, forCellWithReuseIdentifier: "TabGridCell")

        addButton.translatesAutoresizingMaskIntoConstraints = false

        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage(
            systemName: "plus",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        )
        configuration.cornerStyle = .capsule
        configuration.baseBackgroundColor = .systemBlue
        configuration.baseForegroundColor = .white

        addButton.configuration = configuration
        addButton.layer.shadowColor = UIColor.black.cgColor
        addButton.layer.shadowOpacity = 0.1
        addButton.layer.shadowRadius = 8
        addButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        addButton.addTarget(self, action: #selector(handleNewTab), for: .touchUpInside)

        view.addSubview(collectionView)
        view.addSubview(addButton)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            addButton.widthAnchor.constraint(equalToConstant: 48),
            addButton.heightAnchor.constraint(equalToConstant: 48)
        ])

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "完成",
            style: .done,
            target: self,
            action: #selector(handleDone)
        )
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        tabs.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "TabGridCell",
            for: indexPath
        ) as! TabGridCell

        let tab = tabs[indexPath.item]
        cell.configure(tab: tab, isActive: indexPath.item == activeIndex)

        cell.onClose = { [weak self] in
            self?.closeTab(at: indexPath.item)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelectTab?(indexPath.item)
        dismiss(animated: true)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = (view.bounds.width - 44) / 2
        return CGSize(width: width, height: width * 1.35)
    }

    private func closeTab(at index: Int) {
        guard tabs.indices.contains(index) else {
            return
        }

        tabs.remove(at: index)

        if activeIndex == index {
            activeIndex = max(0, index - 1)
        } else if activeIndex > index {
            activeIndex -= 1
        }

        collectionView.reloadData()
        onCloseTab?(index)

        if tabs.isEmpty {
            dismiss(animated: true)
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

final class TabGridCell: UICollectionViewCell {
    private let headerView = UIView()
    private let thumbnailView = UIImageView()
    private let titleLabel = UILabel()
    private let closeButton = TouchButton(type: .system)

    var onClose: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 14
        contentView.layer.masksToBounds = true

        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = .secondarySystemGroupedBackground

        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.clipsToBounds = true
        thumbnailView.backgroundColor = .systemBackground

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.lineBreakMode = .byTruncatingTail

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.tintColor = .secondaryLabel
        closeButton.setImage(
            UIImage(
                systemName: "xmark.circle.fill",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            ),
            for: .normal
        )
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)

        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)

        contentView.addSubview(headerView)
        contentView.addSubview(thumbnailView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 34),

            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -4),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -7),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),

            thumbnailView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            thumbnailView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configure(tab: TabItem, isActive: Bool) {
        titleLabel.text = tab.title
        thumbnailView.image = tab.snapshot
        contentView.layer.borderWidth = isActive ? 2 : 0
        contentView.layer.borderColor = isActive ? UIColor.systemBlue.cgColor : UIColor.clear.cgColor
    }

    @objc private func handleClose() {
        onClose?()
    }
}
