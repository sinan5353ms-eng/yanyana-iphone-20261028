# YanYana — Türkçe ↔ Brezilya Portekizcesi

iPhone’da WhatsApp’tan çıkmadan mesaj çevirmek için hazırlanan özel klavye projesi.

**Teslim durumu:** Swift kaynakları ve doğrudan açılabilen Xcode projesi içerir. Bu Windows bilgisayarda Xcode derlemesi, iPhone testi ve Apple imzalaması yapılamadı. Kurulabilir bir IPA veya TestFlight bağlantısı değildir. Gerçek cihazda doğrulama yapılmadan çalıştığı kabul edilmemelidir.

## Hemen kullanabileceğin hazır uygulama

[Ücretsiz Gboard’u App Store’dan indir](https://apps.apple.com/us/app/gboard-the-google-keyboard/id1091700242).

1. Gboard’u aç ve kurulum yönergelerini izle.
2. Ayarlar → Genel → Klavye → Klavyeler → Yeni Klavye Ekle bölümünden Gboard’u ekle.
3. WhatsApp’ta mesaj alanına dokun. Küre tuşunu basılı tutup Gboard’u seç.
4. Gboard’un özellikler menüsünde Çeviri’yi aç. Türkçe → Portekizce seç.
5. Türkçe yaz, çeviriyi seçerek mesaj alanına ekle ve WhatsApp’ın gönder düğmesine dokun.

[Google’ın iPhone için resmi çeviri rehberi](https://support.google.com/gboard/answer/7421372?co=GENIE.Platform%3DiOS&hl=en). Gboard’un hedef listesinde yalnızca “Portekizce” bulunursa Brezilya bölgesini ayrıca seçmek mümkün olmayabilir.

## YanYana ne yapar?

- Başlangıç yönü Türkçe → Brezilya Portekizcesidir (`tr` → `pt_BR`).
- Türkçe Q tuşları ve Portekizce aksan düğmeleri içerir.
- Mesaj klavyenin kendi taslak alanında yazılır; **Çevir** sonucu önizler.
- **Mesaja ekle**, çeviriyi etkin mesaj alanında imlecin bulunduğu yere yerleştirir. Varsa seçili metin iOS’un standart davranışıyla değiştirilir. Mevcut taslak kendiliğinden temizlenmez.
- Gönderme işlemini kullanıcı WhatsApp’ın gönder düğmesiyle yapar.
- **Panodan al**, yalnızca düğmeye dokunulduğunda kopyalanmış metni okur. Yön düğmesiyle Portekizce → Türkçeye geçilip gelen mesaj çevrilebilir.
- Taslak düzenlendiğinde veya çeviri yönü değiştiğinde eski çeviri kaldırılır. Geç tamamlanan sonuçlar yeni taslağın yerine yazılmaz.
- Çeviri ekleme düğmesi sonucu bir kez tüketir; peş peşe dokunmak aynı sonucu tekrar eklemez.
- 2.000 karakter sınırı vardır; daha uzun yapıştırmada ilk 2.000 karakter alınır ve kullanıcı bilgilendirilir.

## Çeviri ve gizlilik

Apple Translation framework’ünün iOS 26’da gelen `TranslationSession(installedSource:target:)` başlatıcısı kullanılır. iOS 26 ve üzeri, Xcode 26 ve üzeri iOS SDK’sı gerekir. Türkçe–Portekizce dil çiftinin cihazdaki desteği çalışma anında ayrıca denetlenir.

İlk dil indirmesi ana uygulamadaki **Dilleri hazırla** düğmesiyle, Apple’ın indirme onayı üzerinden yapılır. Klavye dil indirmesini başlatmaz. Modeller hazır değilse kullanıcıya ana uygulamayı açmasını söyler. Apple’ın modeline `pt_BR` istenir; lehçe, argo ve romantik ifadelerin doğruluğu garanti edilmez. Önemli mesajları göndermeden kontrol et.

Uygulama kodunda uzak çeviri servisi, API anahtarı, ücretli API, abonelik, analiz SDK’sı veya mesaj geçmişi kaydı yoktur. Mesajlar Apple’ın cihaz içi çeviri motorunda işlenir. Apple kendi API kullanım ölçümlerini toplayabilir; bu uygulama analitik göndermez.

Klavye ayarındaki **Tam Erişim**, isteğe bağlı panodan alma için istenir. Açıldığında iOS klavyeye teknik olarak ağ erişimi de verebilir; bu projede ağ isteği yapan kod bulunmaz. Normal yazma/ekleme ve cihaz içi çeviri akışı bu izne göre engellenmez. İzin kapalı/açık iki durumun da gerçek cihazda test edilmesi gerekir. Uygulama WhatsApp konuşma geçmişine erişemez; gelen mesajı kullanıcı kopyalar. Taslaklar bellekte tutulur; klavye yeniden başlatıldığında kaybolabilir.

## Mac ile kişisel iPhone’a kurulum

1. Bu klasörü bir Mac’e kopyala ve Xcode 26 veya daha yeni bir sürüm yükle.
2. **YanYana.xcodeproj** dosyasını aç. Harici paket yöneticisi veya XcodeGen gerekmez.
3. Xcode → Settings → Accounts bölümünde kendi Apple hesabını ekle.
4. `YanYana`, `YanYanaKeyboard` ve `YanYanaTests` hedeflerinin Signing & Capabilities bölümünde aynı Team’i seç. Automatically manage signing açık kalsın.
5. Bundle identifier’ları sana özel değerlerle değiştir. Örneğin ana uygulama `com.adin.yanyana`, klavye `com.adin.yanyana.keyboard`, test `com.adin.yanyana.tests`. Klavyenin kimliği ana uygulamanın kimliğiyle başlamalıdır.
6. iPhone’u Mac’e bağla; cihazın güven ve Geliştirici Modu yönergelerini tamamla. `YanYana` şemasını ve iPhone’u seçip Run’a bas.
7. Telefonda YanYana’yı aç, **Dilleri hazırla** ile indirmeyi onayla. Önce ana uygulamada kısa bir çeviri dene.
8. Ayarlar → Genel → Klavye → Klavyeler → Yeni Klavye Ekle → YanYana yoluyla klavyeyi etkinleştir.
9. Gelen mesajları panodan almak istersen YanYana klavye ayarlarında Tam Erişim’i aç. iOS’un yapıştırma sorusunu da onaylaman gerekebilir.
10. WhatsApp’ta küre tuşuyla YanYana’yı seç. Türkçe yaz → Çevir → Mesaja ekle → WhatsApp’tan gönder.

Ücretsiz Apple hesabıyla kişisel kurulum mümkündür; Apple’ın Personal Team profilleri 7 gün sonra sona erer ve yeniden derleyip yüklemek gerekir. App Store/TestFlight dağıtımı ayrı Apple üyeliği ve imzalama süreci gerektirir. Bu projede ücretli bir üyelik veya dağıtım işlemi başlatılmadı.

Bu ZIP doğrudan iPhone’a kurulan bir uygulama dosyası değildir. Kendi Mac’ine sahip olmadan da bulutta macOS üzerinde derleme, ardından Windows’ta Apple hesabınla yerel imzalama ve USB ile yükleme yolu kullanılabilir. Bunun için GitHub bağlantısı, bağlı ve güven verilmiş iPhone ve kullanıcının kendi yapacağı Apple hesabı girişi gerekir. Bu yolun hazırlığı `CLOUD-BUILD.md` dosyasında anlatılır; derleme ve imzalama henüz tamamlanmadı. Gboard hemen kullanılabilen seçenektir. Ana ekrana eklenen bir web sayfası, WhatsApp’ın içine özel klavye olarak yerleşemez.

## Doğrulama

Proje yapısını yeniden oluşturmak için, yalnızca Python standart kütüphanesiyle:

```sh
python3 tools/create_project.py
python3 tools/check_project.py
```

`create_project.py` proje ayarlarını varsayılanlarla yeniden yazar. Xcode’da imzalama ve bundle kimliklerini değiştirdikten sonra bu komutu çalıştırma; mevcut projeyi doğrudan aç.

Mac üzerinde derleme:

```sh
xcodebuild -project YanYana.xcodeproj -scheme YanYana \
  -sdk iphoneos -configuration Debug -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO build
```

Xcode’da Product → Test ile birim testlerini çalıştır. Kaynak testleri boş girdi, emoji silme, eski/geç çeviriler, yön değişimi, uzun yapıştırma ve bir kez ekleme durumlarını kapsar. Bunlar bu Windows ortamında çalıştırılmadı.

Gerçek cihaz kabul kontrolü:

1. Henüz dil indirmeden çeviri iste: anlaşılır indirme yönlendirmesi görünmeli.
2. Dilleri indir, uçak modunu aç; “Bugünün nasıl geçti?” metnini iki yönde çevir.
3. WhatsApp’ta çeviriyi ekle; WhatsApp’ın gönder düğmesine dokunana kadar mesaj gönderilmemeli.
4. Çeviri sürerken taslağı değiştir veya yönü değiştir; önceki sonuç eklenememeli.
5. Gelen Portekizce mesajı kopyalayıp Panodan al ile Türkçeye çevir. Yapıştırma izni reddedildiğinde uygulama çökmemeli.
6. Tam Erişim kapalı ve açıkken cihaz içi çeviriyi dene. Apple’ın klavye sandbox’ında bir servis kısıtlaması varsa hata ekranını incele.
7. Dik/yatay ekranı, koyu modu ve küre tuşuyla başka klavyeye dönüşü dene.
8. Çok uzun metni ve emoji içeren mesajları dene. Gerçek konuşma verilerini test kayıtlarına ekleme.

Simülatör, gerçek çeviri modeli ve klavye bellek sınırlarını doğrulamak için yeterli değildir. Otomatik düzeltme, kaydırarak yazma, dikte ve basılı tutarak harf seçenekleri bu basit sürümde yoktur. Apple bazı alanlarda (örneğin şifreler) kendi klavyesine döner.

## Dosyalar

- `App/`: kurulum, dil indirme ve çeviri deneme ekranı.
- `Keyboard/`: WhatsApp içinde çalışan klavye uzantısı.
- `Shared/`: çeviri motoru ve taslak/sonuç durum yönetimi.
- `Tests/`: XCTest testleri.
- `YanYana.xcodeproj/`: ana uygulama, gömülü klavye uzantısı ve test hedefleri.
- `tools/`: proje üretimi ve yapısal denetim.

## Teknik kaynaklar

- [Apple: TranslationSession](https://developer.apple.com/documentation/translation/translationsession)
- [Apple: Önceden indirilmiş dillerle oturum açma](https://developer.apple.com/documentation/translation/translationsession/init(installedsource:target:))
- [Apple: Dil modellerini hazırlama ve çeviri](https://developer.apple.com/documentation/translation/translating-text-within-your-app)
- [Apple: Özel klavye ve Tam Erişim sınırları](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html)
- [Apple: Ücretsiz Personal Team ve profil süreleri](https://developer.apple.com/help/account/basics/about-your-developer-account)
