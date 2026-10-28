import SwiftUI
import UIKit

final class KeyboardViewController: UIInputViewController {
    private let composer = ComposerModel(translator: DeviceTranslator())
    private var heightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        let root = KeyboardView(
            model: composer,
            insert: { [weak self] text in self?.textDocumentProxy.insertText(text) },
            paste: { [weak self] in self?.pasteMessage() },
            nextKeyboard: { [weak self] in self?.advanceToNextInputMode() }
        )
        let host = UIHostingController(rootView: root)
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)
        let height = view.heightAnchor.constraint(equalToConstant: 396)
        height.priority = .init(999)
        height.isActive = true
        heightConstraint = height
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        heightConstraint?.constant = view.window?.windowScene?.interfaceOrientation.isLandscape == true ? 300 : 396
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        composer.cancel()
    }

    private func pasteMessage() {
        // Pasteboard is inspected only after an explicit button tap.
        guard hasFullAccess else {
            composer.showNotice("Panodan almak için Ayarlar → Genel → Klavye → Klavyeler → YanYana → Tam Erişim’i aç. Çeviri için sunucu kullanılmaz.")
            return
        }
        guard let text = UIPasteboard.general.string, !text.isEmpty else {
            composer.showNotice("Önce WhatsApp’taki mesajı basılı tutup kopyala.")
            return
        }
        composer.setSource(text)
    }
}
