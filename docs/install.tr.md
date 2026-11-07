# Kurulum, güncelleme ve kaldırma

[README](../README.tr.md)'ye dön · [English](install.md)

## Gereksinimler

- Notch'lu bir Mac (diğer Mac'ler sanal notch gösterebilir, bkz. Ayarlar > Genel)
- macOS 26 veya üstü

## Homebrew ile

```bash
brew install --cask ljasp-studio/cumba/cumba
```

Cask, [LJASP-studio/homebrew-cumba](https://github.com/LJASP-studio/homebrew-cumba) deposunda duruyor. Son sürümdeki `.dmg` dosyasının aynısını, SHA-256 değerini doğruladıktan sonra kurar; ardından Cumba.app'teki macOS indirme işaretini kaldırır; böylece Yine de Aç adımı gerekmez ([uyarının anlamı](safety.tr.md#macos-neden-uyariyor)). Yeni bir sürüm cask'a ancak sağlama toplamı ve derleme kaydı doğrulandıktan sonra girer. Kurduktan sonra aşağıdaki 5. adımdan devam edin; ileride `brew upgrade --cask cumba` ile güncelleyin.

## Elle

1. [cumbanotch.com](https://cumbanotch.com) ya da [son sürümden](https://github.com/LJASP-studio/Cumba/releases/latest) `Cumba-vX.Y.Z.dmg` (ya da `.zip`) dosyasını indirin.
2. **Açmadan önce dosyayı doğrulayın.** SHA-256 değeri, sürüm sayfasındaki `SHA256SUMS.txt` ile aynı olmalı:
   ```bash
   shasum -a 256 ~/Downloads/Cumba-vX.Y.Z.dmg
   ```
   1.1.0'dan itibaren sürümler ayrıca değiştirilemezdir (yayımlandıktan sonra dosyaları ve etiketi değişemez) ve imzalı derleme kaydı (build provenance) taşır. [GitHub CLI](https://cli.github.com) ile dosyanın bu deponun yayın iş akışında derlendiğini doğrulayabilirsiniz:
   ```bash
   gh attestation verify ~/Downloads/Cumba-vX.Y.Z.dmg --repo LJASP-studio/Cumba
   ```
   1.1.0, depo LJASP-studio'ya taşınmadan önce derlendi; onu `--repo` yerine `--owner muazfurkan` ile doğrulayın.
3. Disk görüntüsünü açın ve Cumba'yı Uygulamalar klasörüne sürükleyin.
4. Cumba Apple tarafından notarize edilmedi, çünkü bu ücretli bir geliştirici hesabı gerektiriyor; bu yüzden macOS ilk açılışı engeller ([uyarının anlamı](safety.tr.md#macos-neden-uyariyor)). Bir kez açmayı deneyin, ardından **Sistem Ayarları > Gizlilik ve Güvenlik**'te **Yine de Aç**'a tıklayın. İndirilmiş bir derlemeyi hiç çalıştırmak istemezseniz [kaynaktan derleyin](#kaynaktan-derleme).
5. Kısa bir karşılama penceresi paneli denemenizi sağlar. Cumba'nın simgesi menü çubuğunda durur; notch'un arkasında kalırsa Ayarlar için notch'a sağ tıklayın.

<details>
<summary>Yine de Aç yerine Terminal</summary>

`xattr -dr com.apple.quarantine /Applications/Cumba.app` yalnızca bu uygulamadaki indirme işaretini kaldırır, Gatekeeper da sormayı bırakır. Bunu yalnızca 2. adımda doğruladığınız bir kopya için yapın.
</details>

## Güncellemeler

Uygulama yeni sürüm çıktığında haber verir; kendi başına hiçbir şey indirmez veya kurmaz. Sürümler ad-hoc imzalı olduğu için güncellemeden sonra macOS verdiğiniz izinleri (Otomasyon, Takvim, Konum, Kamera) ve Cumba'nın token'ları için Anahtar Zinciri erişimini yeniden sorar. Önce yeni dosyayı doğrulayın, sonra izin verin.

## cumbaNotch'tan geçiş

Cumba aynı uygulamanın yeni adı. cumbaNotch'tan çıkın, eski uygulamayı Çöp Sepeti'ne taşıyın ve Cumba'yı kurun; ayarlarınız, düzeniniz, notlarınız ve temalarınız aynen gelir. Claude Code hook'larını kullanıyorsanız Ayarlar > Ajanlar'da bir kez **Güncelle…**'ye tıklayın. Chrome uzantısını kullanıyorsanız onu `chrome://extensions` sayfasından kaldırın, [YouTube uzantısı](features.tr.md#youtube-uzantisi) bölümündeki gibi yeni uygulamadan tekrar yükleyin ve token'ı yapıştırın.

<a name="kaynaktan-derleme"></a>

## Kaynaktan derleme

Xcode 26 veya üstü ve [Homebrew](https://brew.sh) gerekir.

```bash
brew install xcodegen
git clone https://github.com/LJASP-studio/Cumba.git
cd Cumba
cp Local.xcconfig.example Local.xcconfig   # ardından DEVELOPMENT_TEAM değerini girin
xcodegen generate
open Cumba.xcodeproj
```

Ayrıntılar için [CONTRIBUTING.md](../CONTRIBUTING.md) dosyasına bakın (İngilizce).

<a name="kaldirma"></a>

## Kaldırma

1. Claude Code veya Codex hook'larını kurduysanız önce **Ayarlar > Ajanlar > Kaldır…** ile (her ajan için) kaldırın. Uygulama silindikten sonra geride kalan hook'lar hiçbir şey yapmaz ama `~/.claude/settings.json` ve `~/.codex/hooks.json` dosyalarında durur.
2. Ayarlar > Genel'de **Oturum açıldığında başlat**'ı kapatın, menü çubuğundan Cumba'dan çıkın ve uygulamayı Çöp Sepeti'ne taşıyın. Homebrew ile kurduysanız bunun yerine `brew uninstall --cask cumba` çalıştırın; `--zap` ayarlarını, temalarını ve notlarını da siler (4. adımdaki token'ları silmez).
3. Uzantıyı `chrome://extensions` sayfasından kaldırın.
4. Verilerini de silmek için (temalar, düzen, notlar, tercihler ve token'lar):
   ```bash
   rm -rf ~/Library/Application\ Support/Cumba
   defaults delete io.github.muazfurkan.ljaspnotch
   security delete-generic-password -s io.github.muazfurkan.ljaspnotch.server -a token
   security delete-generic-password -s io.github.muazfurkan.ljaspnotch.server -a extension-token
   security delete-generic-password -s io.github.muazfurkan.ljaspnotch.server -a scripts-token
   ```
   Hook kurulumunda alınan yedekler, yedeklenen dosyanın yanında `~/.claude/settings.json.bak-…` ve `~/.codex/hooks.json.bak-…` adıyla durur; saklayabilir ya da silebilirsiniz.
