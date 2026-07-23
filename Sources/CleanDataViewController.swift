import UIKit

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
