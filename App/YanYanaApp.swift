import SwiftUI
import Translation

@main
struct YanYanaApp: App {
    var body: some Scene { WindowGroup { HomeView() } }
}

struct HomeView: View {
    @StateObject private var composer = ComposerModel(translator: DeviceTranslator())
    @State private var configuration: TranslationSession.Configuration?
    @State private var preparationMessage = "İlk kullanımda Türkçe ve Brezilya Portekizcesini indir."
    @State private var preparing = false
    private let green = Color(red: 0.08, green: 0.34, blue: 0.27)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("YanYana", systemImage: "bubble.left.and.bubble.right.fill")
                            .font(.title2.bold()).foregroundStyle(green)
                        Text("Bir mesaj,\niki dil.").font(.system(size: 44, weight: .bold, design: .rounded))
                        Text("Sen Türkçe yaz. O, Portekizce okusun.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 14) {
                        Label("Önce dilleri hazırlayalım", systemImage: "arrow.down.circle")
                            .font(.headline)
                        Text(preparationMessage).font(.subheadline).foregroundStyle(.secondary)
                        Button(action: prepare) {
                            HStack {
                                if preparing { ProgressView().tint(.white) }
                                Text(preparing ? "Diller hazırlanıyor…" : "Dilleri hazırla")
                                    .frame(maxWidth: .infinity)
                            }.padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent).tint(green).disabled(preparing)
                        Text("İndirme için internet gerekir. Mesaj çevirisi cihazda yapılır.")
                            .font(.caption).foregroundStyle(.secondary)
                    }.padding(20).background(.white, in: RoundedRectangle(cornerRadius: 24))

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Bir mesaj dene").font(.headline)
                            Spacer()
                            Button { composer.swapDirection() } label: {
                                Image(systemName: "arrow.left.arrow.right")
                            }.accessibilityLabel("Çeviri yönünü değiştir")
                        }
                        Text(composer.direction.title).font(.caption.bold()).foregroundStyle(green)
                        TextEditor(text: Binding(get: { composer.sourceText }, set: { composer.setSource($0) }))
                            .frame(minHeight: 90).scrollContentBackground(.hidden)
                            .padding(8).background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("Çevrilecek mesaj")
                        Button(composer.isTranslating ? "Çevriliyor…" : "Çevir") { composer.translate() }
                            .buttonStyle(.borderedProminent).tint(green).disabled(!composer.canTranslate)
                        if !composer.translatedText.isEmpty {
                            Text(composer.translatedText).textSelection(.enabled).font(.title3)
                            ShareLink(item: composer.translatedText) {
                                Label("Çeviriyi paylaş", systemImage: "square.and.arrow.up")
                            }
                        }
                        if let notice = composer.notice {
                            Text(notice).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }.padding(20).background(.white, in: RoundedRectangle(cornerRadius: 24))

                    VStack(alignment: .leading, spacing: 16) {
                        Text("WhatsApp’ta nasıl kullanırım?").font(.headline)
                        step("1", "Klavyeyi ekle", "Ayarlar → Genel → Klavye → Klavyeler → Yeni Klavye Ekle → YanYana.")
                        step("2", "WhatsApp’a dön", "Mesaj alanına dokun. Küre tuşunu basılı tutup YanYana’yı seç.")
                        step("3", "Yaz, çevir, ekle", "Türkçe mesajını klavyede yaz. Çevir’e, sonra Mesaja ekle’ye dokun. WhatsApp’tan gönder.")
                        step("4", "Onun mesajını anla", "Gelen mesajı kopyala. YanYana’da Panodan al’a dokun, yönü Português → Türkçe yap ve çevir. iOS yapıştırma izni isteyebilir.")
                        Text("Panodan alma için iOS’un istediği durumda YanYana klavye ayarlarında Tam Erişim’i açabilirsin. Çeviri kodu mesajlarını bir sunucuya göndermez.")
                            .font(.caption).foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Sadece ikinizin arasında", systemImage: "lock.shield")
                            .font(.headline).foregroundStyle(green)
                        Text("Hesap, API anahtarı veya abonelik gerekmez. Uygulama mesaj geçmişi tutmaz. Brezilya Portekizcesi istenir; sonuçtaki bölgesel ifadeleri Apple’ın çeviri modeli belirler.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Text("iOS 26 veya üzeri gerekir. Çeviriler gerçek iPhone’da denenmelidir.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(24)
            }
            .background(Color(red: 0.95, green: 0.96, blue: 0.93))
            .toolbar(.hidden, for: .navigationBar)
            .translationTask(configuration) { session in
                do {
                    try await session.prepareTranslation()
                    let status = await LanguageAvailability().status(
                        from: TranslationDirection.turkishToPortuguese.source,
                        to: TranslationDirection.turkishToPortuguese.target
                    )
                    preparationMessage = status == .installed
                        ? "Diller hazır. Artık WhatsApp’ta YanYana klavyesini kullanabilirsin."
                        : "Diller henüz hazır değil. İndirmeyi tamamlayıp tekrar dene."
                } catch {
                    preparationMessage = "Diller hazırlanamadı. İnterneti ve bu iPhone’un dil desteğini kontrol edip tekrar dene."
                }
                preparing = false
            }
        }
    }

    private func prepare() {
        preparing = true
        preparationMessage = "Apple’ın dil indirme ekranını onayla."
        if configuration != nil {
            configuration?.invalidate()
        } else {
            configuration = .init(source: TranslationDirection.turkishToPortuguese.source,
                                  target: TranslationDirection.turkishToPortuguese.target)
        }
    }

    private func step(_ number: String, _ title: String, _ description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number).font(.subheadline.bold()).foregroundStyle(green)
                .frame(width: 28, height: 28).background(green.opacity(0.1), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.bold())
                Text(description).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}
