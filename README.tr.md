<p align="center"><img src="docs/banner.png" alt="Notch'un altında açılmış Cumba paneli ve mini oynatıcı"></p>

<h1 align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/cumba-dark.svg">
    <img src="docs/cumba-light.svg" alt="Cumba" width="300">
  </picture>
</h1>

<p align="center"><sub>by LJASP · eski adıyla cumbaNotch</sub></p>

<p align="center">
  <a href="https://github.com/LJASP-studio/Cumba/releases/latest"><img src="https://img.shields.io/github/v/release/LJASP-studio/Cumba?label=download&color=DCB669" alt="Son sürüm"></a>
  <a href="https://github.com/LJASP-studio/Cumba/actions/workflows/build.yml"><img src="https://github.com/LJASP-studio/Cumba/actions/workflows/build.yml/badge.svg?branch=main" alt="Derleme durumu"></a>
  <img src="https://img.shields.io/badge/macOS-26%2B-111111?logo=apple" alt="macOS 26 veya üstü">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/LJASP-studio/Cumba?color=111111" alt="MIT lisansı"></a>
</p>

<p align="center"><a href="https://cumbanotch.com">cumbanotch.com</a> · <a href="README.md">English</a></p>

<p align="center"><img src="docs/demo.gif" width="800" alt="Cumba kullanımda: panel müzik ve hava durumuyla açılıyor, Claude Code bir dosyayı düzenlemek için izin istiyor ve izin notch'tan veriliyor, ardından pano geçmişi ve notch'un yanında ses düzeyi"></p>

macOS için ücretsiz ve açık kaynaklı bir notch uygulaması. İmleci MacBook notch'unun üzerinde tuttuğunuzda kamera yuvasından bir panel büyür: çalan müzik ya da video, Claude Code ve Codex'in ne yaptığı ve seçtiğiniz widget'lar; hepsi size göre ayarladığınız bir görünümle.

*Cumba*, eski Türk evlerinin üst katından sokağa taşan küçük çıkmadır: oturup sokakta olup biteni izlediğiniz sakin bir köşe. Panel de aynısını ekranınızın tepesinden yapar.

## Neler sunar

- Hangi uygulamada ne çalıyorsa tek bir mini oynatıcıda: Spotify, Müzik, Safari ya da Chrome'da YouTube, podcast'ler. Kapak görseli, sarma ve kontroller; uzantı ya da kurulum gerekmez.
- Notch'ta Claude Code ve Codex. Ajanın ne yaptığını ve bağlam penceresinin ne kadar dolu olduğunu görün, izin isteklerini pencere değiştirmeden İzin Ver, Reddet ya da Terminalde ile yanıtlayın.
- Sekmelere dizdiğiniz widget'lar: görüşmeler için Katıl düğmeli takvim, Apple Notlar, Anımsatıcılar, pano geçmişi, zamanlayıcı ve Pomodoro, hava durumu, AirDrop destekli dosya rafı ve daha fazlası.
- Düz siyah ve Liquid Glass'tan Neon Tokyo ve Synthwave'e sekiz tema; ya da cam, renk geçişi, neon kenar, kendi renkleriniz ve fontunuzla kendi temanız. Temalar JSON olarak içe ve dışa aktarılır.
- Kapalı notch'un iki yanında canlı etkinlikler: çalışan zamanlayıcı, çalışan bir ajan, şarj, çalan şarkı, ses ve parlaklık.
- Yolunuza çıkmaz. Tıklamalar menü çubuğuna geçer, tam ekran uygulamalarda da çalışır, boştayken CPU kullanmaz.
- Türkçe, İngilizce, İspanyolca ve Fransızca.

Her widget ve seçenek [özellik turunda](docs/features.tr.md).

## İndirme ve kurulum

[Homebrew](https://brew.sh) ile:

```bash
brew install --cask ljasp-studio/cumba/cumba
```

Ya da `.dmg` dosyasını [cumbanotch.com](https://cumbanotch.com)'dan veya [son sürümden](https://github.com/LJASP-studio/Cumba/releases/latest) indirip Cumba'yı Uygulamalar klasörüne sürükleyin. macOS 26 veya üstü gerekir; notch'u olmayan Mac'ler sanal bir notch gösterebilir.

<a name="macos-neden-uyariyor"></a>

**İlk açılış:** Cumba Apple tarafından notarize edilmedi, çünkü bu ücretli bir geliştirici hesabı gerektiriyor; bu yüzden macOS indirilen kopyanın ilk açılışını engeller. Bir kez açmayı deneyin, ardından **Sistem Ayarları > Gizlilik ve Güvenlik**'te **Yine de Aç**'a tıklayın. Homebrew cask'ı dosyayı doğrular ve bu adımı atlar. [Uyarının anlamı](docs/safety.tr.md#macos-neden-uyariyor).

Cumba menü çubuğunda yaşar. Simgesi notch'un arkasında kalırsa Ayarlar için notch'a sağ tıklayın.

<a name="kaynaktan-derleme"></a>
<a name="kaldırma"></a>

Dosyayı doğrulama, güncellemeler, cumbaNotch'tan geçiş, kaynaktan derleme ve kaldırma [Kurulum, güncelleme ve kaldırma](docs/install.tr.md) sayfasında.

<a name="guvenli-mi"></a>

## Güvenli mi?

Cumba yeni (ilk sürüm Ekim 2026) ve tek bir kişi tarafından geliştiriliyor; kodunun büyük kısmı Claude Code ile yazılıyor. Bağımsız bir güvenlik denetiminden geçmedi. Bu yüzden kimsenin sözüne güvenmeniz gerekmeyecek şekilde kuruldu: kodun tamamı bu depoda, her değişiklik `main`'e girmeden önce CI'dan geçmek zorunda ve her sürümü GitHub, etiketli bir commit'ten, doğrulayabileceğiniz imzalı derleme kaynağıyla derliyor. Telemetri yok; Cumba her izni ancak onu gerektiren özelliği açtığınızda ister.

[Cumba güvenli mi?](docs/safety.tr.md) macOS uyarısını açıklıyor ve her iddiayı kendiniz doğrulamanız için komutları veriyor. Cumba'nın Mac'inizde nelere erişebildiği [Gizlilik ve izinler](docs/privacy.tr.md) sayfasında; tehdit modeli ve bir sorunu gizlice bildirme yolu [SECURITY.md](SECURITY.md)'de.

## Gizlilik

Telemetri yok, her şey Mac'inizde kalır. Yalnızca şu özellikler internete çıkar, o da yalnızca siz kullanırken:

| Özellik | Bağlandığı yer |
|---|---|
| Medya oynatıcıda Spotify kapakları | `i.scdn.co` |
| Medya oynatıcıda YouTube küçük resimleri | `*.ytimg.com`, `*.googleusercontent.com`, `*.ggpht.com` |
| Hava durumu | Yaklaşık 10 km'ye yuvarlanmış konumunuzla (ya da seçtiğiniz şehirle) `api.open-meteo.com`, şehir araması için `geocoding-api.open-meteo.com`, şehir adı için Apple Haritalar |
| Güncelleme denetimi | Açılışta ve günde bir kez `api.github.com`; Ayarlar > Genel'den kapatılabilir |

Her isteğin içinde ne olduğu [Gizlilik ve izinler](docs/privacy.tr.md) sayfasında.

## Destek

Cumba ücretsiz. İşinize yarıyorsa [GitHub Sponsors](https://github.com/sponsors/muazfurkan) ya da [Buy Me a Coffee](https://buymeacoffee.com/ljasp) üzerinden destek olabilirsiniz.

## Katkı

Sorular ve fikirler için [Discussions](https://github.com/LJASP-studio/Cumba/discussions) bölümünü kullanabilirsiniz. Kod katkısı için lütfen [CONTRIBUTING.md](CONTRIBUTING.md) ve [Davranış Kuralları](CODE_OF_CONDUCT.md) belgelerini okuyun. Güvenlik açıklarını [SECURITY.md](SECURITY.md) dosyasında anlatıldığı gibi gizli olarak bildirin.

## Lisans

[MIT](LICENSE)
