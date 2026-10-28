# Mac olmadan derleme: YanYana

Bu yöntem, GitHub’ın macOS bilgisayarında **imzasız** `YanYana-unsigned.ipa` üretir. iPhone’a otomatik kurulum yapmaz. Apple imzası ve telefondaki güven/Geliştirici Modu adımları ayrıca tamamlanmalıdır.

Bu dosyayı hazırlamak herhangi bir bulut çalıştırması, hesap açılışı veya ücretli işlem başlatmaz.

## Önce gerekenler

- Kendi GitHub hesabın ve Actions çalıştırma yetkisi olan bir depo.
- Depoda bu klasördeki kaynaklar, `YanYana.xcodeproj`, `tools/check_project.py` ve workflow dosyası.
- **Yalnızca bağımsız `yanyana-ios` projesini yükle.** Üstteki video çalışma klasörünü, onun `.git` geçmişini, `.env` dosyalarını, API anahtarlarını, sertifikaları veya kişisel dosyaları yükleme. Herkese açık depoda kaynaklar görünür; yüklemeden önce içeriği incele.

Mevcut YanYana kaynaklarında hesap bilgisi veya imzalama anahtarı bulunmaz. Örnek mesajlar geneldir; gerçek WhatsApp yazışmalarına erişilmez.

## Ücretsiz kullanım sınırı

GitHub’ın standart macOS runner’ları herkese açık depolarda ücretsizdir. Özel depoların ücretsiz dakika ve saklama kotaları vardır; kota aşımı ücret doğurabilir. Bu nedenle workflow **özel depoda derleme işini atlar** ve özel depo için bir izin seçeneği sunmaz. Artifact yalnızca 1 gün saklanır. Başlatmadan önce hesabın güncel Actions kullanım ve saklama koşullarını kontrol et. [GitHub ücretlendirme](https://docs.github.com/en/actions/concepts/billing-and-usage)

Kodu herkese açmak istemiyorsan bu workflow’u çalıştırma. Depoyu kendiliğinden herkese açık hâle getiren veya ücretli kota açan bir adım yoktur.

## Elle başlatma

1. Tercihen yalnızca `yanyana-ios` klasörünün **içeriğini** yeni depoya yükle. `YanYana.xcodeproj` ve `.github` depo kökünde bulunmalı.
2. Mevcut bir depoda kaynaklar `yanyana-ios/` altında tutuluyorsa workflow’u ayrıca **depo kökündeki** `.github/workflows/ios-build.yml` konumuna koy. GitHub, alt klasördeki `.github` dizininden workflow başlatmaz. Proje bulma adımı iki kaynak yerleşimini de tanır.
3. Workflow dosyasının deponun varsayılan dalında olduğundan emin ol. GitHub → **Actions → YanYana unsigned iPhone build → Run workflow** yoluyla başlat.
4. Derleme başarılı olduğunda çalıştırmanın **Artifacts** bölümünden `YanYana-unsigned-iphone` paketini indir. İçinde imzasız IPA, SHA-256 özeti ve derleme bilgisi bulunur.

Push veya pull request ile otomatik derleme yoktur. İş 25 dakika ile sınırlıdır; aynı dalda yeni bir elle çalıştırma önceki derlemeyi iptal eder. Workflow yalnızca depo okuma yetkisi ister; kod yazmaz, uygulama imzalamaz ve TestFlight/App Store’a yüklemez.

## Xcode ve sürümler

Workflow `macos-26` standart runner’ını kullanır, mevcut seçili Xcode’u kayda geçirir ve en az Xcode 26 olmasını denetler. 28 Ekim 2026’da kontrol edilen resmi image listesi Xcode 26.6’yı varsayılan, iOS 26.5 SDK’sını kurulu gösteriyor. Bu, projenin iOS 26 minimum sürümü için uygundur. İleride image listesi değişebilir; çalıştırmadaki Xcode sürümü esas alınır. [Runner yazılımları](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-Readme.md)

Kaynak alma ve artifact yükleme, kontrol edilmiş resmi sürümlerin tam commit kimliklerine sabitlenmiştir: [checkout v7.0.1](https://github.com/actions/checkout/releases/tag/v7.0.1), [upload-artifact v7.0.2](https://github.com/actions/upload-artifact/releases/tag/v7.0.2).

## İndirdiğim IPA neden doğrudan açılmıyor?

Paket, ana uygulamayı ve gömülü klavye uzantısını içerir; ikisi de Apple kimliğiyle imzalanmamıştır. iPhone’da çalıştırmak için yerel imzalama aracı, telefon bağlantısı ve kullanıcının kendi hesabıyla yerel oturum açması gerekir. Windows’taki AltServer/AltStore yolu bu aşamada değerlendirilebilir. Apple parolanı sohbete, kaynak koduna veya GitHub Secrets’a yazma; gerekiyorsa yalnızca kendi bilgisayarındaki yerel aracın giriş penceresine kendin gir. [AltStore Windows yönergeleri](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows)

Ücretsiz Apple Personal Team imzaları 7 gün sonra sona erer; yeniden imzalama gerekebilir. TestFlight dağıtımı ayrı Apple Developer Program üyeliği ve uygun imzalı yükleme gerektirir. Bu workflow hiçbir Apple parolası, `.p12`, provisioning profile veya imzalama sırrı toplamaz. [Apple Personal Team](https://developer.apple.com/help/account/basics/about-your-developer-account), [Apple dağıtım açıklaması](https://developer.apple.com/documentation/Xcode/distributing-your-app-for-beta-testing-and-releases)

Başarılı bulut derlemesi, gerçek iPhone’da çeviri çalıştığı anlamına gelmez. Kurulumdan sonra ana uygulamada dilleri hazırlama, WhatsApp klavyesi, panodan alma ve çevrimdışı çeviri cihazda ayrıca denenmelidir.
