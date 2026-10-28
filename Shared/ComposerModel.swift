import Combine
import Foundation

@MainActor
final class ComposerModel: ObservableObject {
    @Published private(set) var sourceText = ""
    @Published private(set) var translatedText = ""
    @Published private(set) var direction: TranslationDirection = .turkishToPortuguese
    @Published private(set) var isTranslating = false
    @Published private(set) var notice: String?

    private let translator: any MessageTranslating
    private var work: Task<Void, Never>?
    private var generation = UUID()
    var canTranslate: Bool {
        !sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isTranslating
    }
    var canInsert: Bool { !translatedText.isEmpty && !isTranslating }

    init(translator: any MessageTranslating) { self.translator = translator }

    func setSource(_ text: String) {
        invalidate()
        sourceText = String(text.prefix(2_000))
        if text.count > 2_000 { notice = "İlk 2.000 karakter alındı. Mesajını kontrol et." }
    }

    func append(_ text: String) { setSource(sourceText + text) }
    func backspace() {
        guard !sourceText.isEmpty else { return }
        setSource(String(sourceText.dropLast()))
    }

    func swapDirection() {
        invalidate()
        direction = direction.reversed
    }

    func clear() { setSource("") }
    func showNotice(_ message: String) { notice = message }

    func translate() {
        guard canTranslate else { return }
        invalidate()
        let currentGeneration = generation
        let input = sourceText
        let selectedDirection = direction
        isTranslating = true
        work = Task { [weak self, translator] in
            do {
                let output = try await translator.translate(input, direction: selectedDirection)
                try Task.checkCancellation()
                guard let self, self.generation == currentGeneration else { return }
                self.translatedText = output
                self.isTranslating = false
                if output.isEmpty { self.notice = "Çeviri boş döndü. Tekrar dene." }
            } catch {
                guard let self, self.generation == currentGeneration else { return }
                self.isTranslating = false
                if !(error is CancellationError) {
                    self.notice = (error as? TranslationProblem)?.localizedDescription
                        ?? "Çeviri tamamlanamadı. YanYana’da dilleri hazırlayıp tekrar dene."
                }
            }
        }
    }

    func takeTranslation() -> String? {
        guard canInsert else { return nil }
        let text = translatedText
        clear()
        return text
    }

    func cancel() {
        work?.cancel()
        generation = UUID()
        isTranslating = false
    }

    private func invalidate() {
        cancel()
        translatedText = ""
        notice = nil
    }
}
