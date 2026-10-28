import Foundation
import Translation

enum TranslationDirection: String, CaseIterable, Identifiable {
    case turkishToPortuguese, portugueseToTurkish

    var id: String { rawValue }
    var source: Locale.Language {
        Locale.Language(identifier: self == .turkishToPortuguese ? "tr" : "pt_BR")
    }
    var target: Locale.Language {
        Locale.Language(identifier: self == .turkishToPortuguese ? "pt_BR" : "tr")
    }
    var title: String {
        self == .turkishToPortuguese ? "Türkçe → Português (BR)" : "Português (BR) → Türkçe"
    }
    var placeholder: String {
        self == .turkishToPortuguese ? "Ona ne söylemek istersin?" : "Onun mesajını buraya yapıştır."
    }
    var reversed: Self {
        self == .turkishToPortuguese ? .portugueseToTurkish : .turkishToPortuguese
    }
}

enum TranslationProblem: LocalizedError {
    case empty, tooLong, missingModels, unsupported

    var errorDescription: String? {
        switch self {
        case .empty: return "Önce bir mesaj yaz."
        case .tooLong: return "Mesajı 2.000 karakterden kısa tut."
        case .missingModels: return "YanYana uygulamasını açıp ‘Dilleri hazırla’ya dokun. Sonra bu klavyeye dön."
        case .unsupported: return "Bu iPhone’da Türkçe–Portekizce çeviri kullanılamıyor. iOS dil desteğini kontrol et."
        }
    }
}

@MainActor
protocol MessageTranslating {
    func translate(_ text: String, direction: TranslationDirection) async throws -> String
}

/// No HTTP client, API key, analytics, or paid translation service.
/// Language downloads must be approved in the containing app first.
@MainActor
struct DeviceTranslator: MessageTranslating {
    func translate(_ text: String, direction: TranslationDirection) async throws -> String {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { throw TranslationProblem.empty }
        guard input.count <= 2_000 else { throw TranslationProblem.tooLong }
        let availability = await LanguageAvailability().status(from: direction.source, to: direction.target)
        switch availability {
        case .installed: break
        case .supported: throw TranslationProblem.missingModels
        case .unsupported: throw TranslationProblem.unsupported
        @unknown default: throw TranslationProblem.unsupported
        }
        try Task.checkCancellation()
        let session = TranslationSession(installedSource: direction.source, target: direction.target)
        let response = try await session.translate(input)
        try Task.checkCancellation()
        return response.targetText
    }
}
