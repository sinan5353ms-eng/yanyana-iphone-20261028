import SwiftUI

struct KeyboardView: View {
    @ObservedObject var model: ComposerModel
    let insert: (String) -> Void
    let paste: () -> Void
    let nextKeyboard: () -> Void
    @State private var shifted = false
    @State private var symbols = false
    private let green = Color(red: 0.08, green: 0.34, blue: 0.27)

    private var rows: [[String]] {
        if symbols {
            return [Array("1234567890").map(String.init),
                    ["@", "#", "₺", "€", "&", "-", "+", "(", ")", "/"],
                    [".", ",", "?", "!", "'", "\"", ":", ";"]]
        }
        return [Array("qwertyuıopğü").map(String.init),
                Array("asdfghjklşi").map(String.init),
                Array("zxcvbnmöç").map(String.init)]
    }

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 340
            VStack(spacing: compact ? 4 : 8) {
                HStack {
                    Button { model.swapDirection() } label: {
                        HStack(spacing: 6) {
                            Text(model.direction.title).font(.system(size: 13, weight: .semibold))
                            Image(systemName: "arrow.left.arrow.right").font(.caption)
                        }.foregroundStyle(green)
                    }.accessibilityLabel("Çeviri yönünü değiştir: \(model.direction.title)")
                    Spacer(minLength: 2)
                    Button("Panodan al", action: paste).font(.system(size: 12, weight: .medium))
                        .foregroundStyle(green)
                }.frame(height: 22)

                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(model.sourceText.isEmpty ? model.direction.placeholder : model.sourceText)
                            .foregroundStyle(model.sourceText.isEmpty ? .secondary : .primary)
                            .font(.system(size: compact ? 14 : 16))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if !model.translatedText.isEmpty {
                            Text(model.translatedText).font(.system(size: compact ? 14 : 16, weight: .medium))
                                .foregroundStyle(green)
                        }
                        if let notice = model.notice {
                            Text(notice).font(.caption).foregroundStyle(.secondary)
                        }
                    }.padding(10)
                }
                .frame(maxHeight: .infinity)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("Mesaj ve çeviri önizlemesi")

                HStack(spacing: 8) {
                    Button { model.translate() } label: {
                        HStack(spacing: 5) {
                            if model.isTranslating { ProgressView().tint(.white) }
                            Text(model.isTranslating ? "Çevriliyor…" : "Çevir")
                        }.frame(maxWidth: .infinity).frame(height: compact ? 30 : 38)
                    }.buttonStyle(.plain)
                        .foregroundStyle(.white)
                        .background(model.canTranslate ? green : green.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
                        .disabled(!model.canTranslate)
                    Button {
                        if let text = model.takeTranslation() { insert(text) }
                    } label: {
                        Label("Mesaja ekle", systemImage: "arrow.up.right")
                            .frame(maxWidth: .infinity).frame(height: compact ? 30 : 38)
                    }.buttonStyle(.plain).foregroundStyle(model.canInsert ? green : .secondary)
                        .background(green.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        .disabled(!model.canInsert)
                    Button { model.clear() } label: {
                        Image(systemName: "trash").frame(width: 30, height: 32)
                    }.foregroundStyle(.secondary).accessibilityLabel("Taslağı temizle")
                }.font(.system(size: 14, weight: .semibold))

                if !compact {
                    HStack(spacing: 5) {
                        ForEach(["❤️", "😊", "ã", "õ", "á", "é", "ê", "ó", "ú"], id: \.self) { key in
                            keyButton(key, height: 26, secondary: true) { model.append(key) }
                        }
                    }
                }
                ForEach(rows.indices, id: \.self) { index in
                    HStack(spacing: compact ? 4 : 3) {
                        if index == 2 {
                            keyButton(shifted ? "⇪" : "⇧", height: compact ? 30 : 38, secondary: true) {
                                shifted.toggle()
                            }.accessibilityLabel("Büyük harf")
                        }
                        ForEach(rows[index], id: \.self) { key in
                            keyButton(display(key), height: compact ? 30 : 38) {
                                model.append(display(key))
                                shifted = false
                            }
                        }
                        if index == 2 {
                            keyButton("⌫", height: compact ? 30 : 38, secondary: true) { model.backspace() }
                                .accessibilityLabel("Son harfi sil")
                        }
                    }
                }
                HStack(spacing: 6) {
                    keyButton(symbols ? "ABC" : "123", height: compact ? 30 : 38, secondary: true) { symbols.toggle() }
                        .frame(width: 48)
                    Button(action: nextKeyboard) {
                        Image(systemName: "globe").font(.system(size: 20))
                            .frame(width: 40, height: compact ? 30 : 38)
                    }.buttonStyle(.plain).foregroundStyle(.primary)
                        .background(Color(.systemGray3), in: RoundedRectangle(cornerRadius: 7))
                        .accessibilityLabel("Sonraki klavye")
                    keyButton("boşluk", height: compact ? 30 : 38) { model.append(" ") }
                    keyButton(".", height: compact ? 30 : 38) { model.append(".") }.frame(width: 30)
                    keyButton("↵", height: compact ? 30 : 38, secondary: true) { model.append("\n") }
                        .frame(width: 42).accessibilityLabel("Yeni satır")
                }
            }.padding(.horizontal, 6).padding(.vertical, compact ? 4 : 8)
                .background(Color(.systemGroupedBackground))
        }
    }

    private func display(_ key: String) -> String {
        shifted ? key.uppercased(with: Locale(identifier: "tr_TR")) : key
    }

    private func keyButton(_ title: String, height: CGFloat, secondary: Bool = false,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.system(size: title.count > 1 ? 14 : 20))
                .minimumScaleFactor(0.7).lineLimit(1)
                .frame(maxWidth: .infinity).frame(height: height).contentShape(Rectangle())
        }
        .buttonStyle(.plain).foregroundStyle(.primary)
        .background(secondary ? Color(.systemGray4) : Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 7))
        .shadow(color: .black.opacity(0.12), radius: 0, y: 1)
    }
}
