import XCTest
@testable import YanYana

@MainActor
final class ComposerModelTests: XCTestCase {
    func testEmptyInputCannotTranslate() {
        let model = ComposerModel(translator: ImmediateTranslator())
        model.setSource(" \n ")
        XCTAssertFalse(model.canTranslate)
        XCTAssertNil(model.takeTranslation())
    }

    func testBackspaceRemovesOneWholeEmoji() {
        let model = ComposerModel(translator: ImmediateTranslator())
        model.setSource("Merhaba 👩🏽‍❤️‍👩🏻")
        model.backspace()
        XCTAssertEqual(model.sourceText, "Merhaba ")
    }

    func testTranslationCanOnlyBeInsertedOnce() async {
        let model = ComposerModel(translator: ImmediateTranslator())
        model.setSource("Seni özledim ❤️")
        model.translate()
        await waitUntil { !model.isTranslating }
        XCTAssertEqual(model.takeTranslation(), "Estou com saudade de você ❤️")
        XCTAssertNil(model.takeTranslation())
        XCTAssertEqual(model.sourceText, "")
    }

    func testEditingInvalidatesAnOldResult() async {
        let model = ComposerModel(translator: ImmediateTranslator())
        model.setSource("Seni özledim")
        model.translate()
        await waitUntil { !model.isTranslating }
        model.append("!")
        XCTAssertFalse(model.canInsert)
        XCTAssertEqual(model.translatedText, "")
    }

    func testChangingDirectionInvalidatesAnOldResult() async {
        let model = ComposerModel(translator: ImmediateTranslator())
        model.setSource("Merhaba")
        model.translate()
        await waitUntil { !model.isTranslating }
        model.swapDirection()
        XCTAssertEqual(model.direction, .portugueseToTurkish)
        XCTAssertFalse(model.canInsert)
    }

    func testLateResponseCannotOverwriteEditedDraft() async {
        let translator = DelayedTranslator()
        let model = ComposerModel(translator: translator)
        model.setSource("Eski mesaj")
        model.translate()
        await waitUntil { translator.pending != nil }
        model.setSource("Yeni mesaj")
        translator.pending?.resume(returning: "A stale translation")
        translator.pending = nil
        for _ in 0..<20 { await Task.yield() }
        XCTAssertEqual(model.sourceText, "Yeni mesaj")
        XCTAssertEqual(model.translatedText, "")
        XCTAssertFalse(model.canInsert)
    }

    func testOversizedPasteIsBoundedAndExplained() {
        let model = ComposerModel(translator: ImmediateTranslator())
        model.setSource(String(repeating: "❤️", count: 2_001))
        XCTAssertEqual(model.sourceText.count, 2_000)
        XCTAssertNotNil(model.notice)
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<1_000 {
            if condition() { return }
            await Task.yield()
        }
        XCTFail("Asenkron işlem tamamlanmadı")
    }
}

@MainActor
private struct ImmediateTranslator: MessageTranslating {
    func translate(_ text: String, direction: TranslationDirection) async throws -> String {
        "Estou com saudade de você ❤️"
    }
}

@MainActor
private final class DelayedTranslator: MessageTranslating {
    var pending: CheckedContinuation<String, Error>?
    func translate(_ text: String, direction: TranslationDirection) async throws -> String {
        try await withCheckedThrowingContinuation { pending = $0 }
    }
}
