# Cumba güvenli mi?

[README](../README.tr.md)'ye dön · [English](safety.md)

Cumba yeni (ilk sürüm Ekim 2026) ve tek bir geliştirici tarafından yapay zeka desteğiyle (Claude Code) geliştiriliyor. Bağımsız bir güvenlik denetiminden geçmedi.

İnsanlar genelde önce iki şey soruyor: *"Bunu yapay zeka yazmadı mı?"* ve *"macOS neden uyarıyor?"* Aşağıda ikisinin de açık cevabı var; her iddiayı kimsenin sözüne güvenmeden kendiniz nasıl doğrulayacağınız da.

## Yapay zekayla yazıldı, her kod gibi denetleniyor

Cumba'yı tek bir kişi tasarlıyor ve geliştiriyor; kodunun büyük kısmı Claude Code ile yazılıyor. Yapay zekayla yazılan kodda da her kodda olabilecek hatalar olabilir. Bu yüzden Cumba, kodu kimin yazdığına güvenmeniz gerekmeyecek şekilde kuruldu:

- **Her şey açık.** Uygulamanın tamamı MIT lisansıyla bu depoda. Kapalı bir parçası yok ve uygulama sonradan kod indirmiyor.
- **`main`'e denetlenmeden hiçbir şey girmiyor.** Her değişiklik bir pull request'le geliyor. Birleşmeden önce GitHub'ın makinelerinde derlenmesi, 200'den fazla birim testini, katı biçim denetimini ve Release derlemesini geçmesi gerekiyor. `main`'e doğrudan push, force push ve geçmişi yeniden yazma herkese kapalı, geliştiricinin kendisine de.
- **İndirdiğiniz dosyalar bir dizüstü bilgisayardan değil, GitHub'dan geliyor.** Sürümleri yalnızca [yayın iş akışı](../.github/workflows/release.yml) derliyor: etiketli bir commit'ten, GitHub'ın Mac'inde, salt okunur yetkiyle. Her dosya, onu bu depoya ve o commit'e bağlayan imzalı derleme kaynağı (build provenance) taşıyor; sürümler yayımlandıktan sonra değiştirilemiyor.
- **Ters gidebilecek az şey var.** Tek bir dış kitaplık ([FlyingFox](https://github.com/swhitty/FlyingFox), MIT, bir commit'e sabit), analiz ya da reklam SDK'sı yok, telemetri yok. İş akışları yalnızca GitHub'ın kendi action'larını kullanabiliyor, onlar da commit'e sabit. Sır taraması, push koruması ve Dependabot güvenlik güncellemeleri açık; CodeQL her hafta Chrome uzantısını, iş akışlarını ve betikleri tarıyor.
- **Güvenlik çalışmaları kayıt altında.** [CHANGELOG](../CHANGELOG.md) her sürümün güvenlik düzeltmelerini listeliyor. [SECURITY.md](../SECURITY.md)'de tehdit modeli ve güvenlikle ilgili kodun haritası var; incelemek isteyen için on kadar dosya.
- **Eksik olan:** Cumba'yı henüz bağımsız bir firma denetlemedi. Bir sorun bulursanız lütfen [SECURITY.md](../SECURITY.md)'de anlatıldığı gibi gizlice bildirin.

<a name="macos-neden-uyariyor"></a>

## macOS neden uyarıyor

macOS ilk açılışta, Apple'ın Cumba'nın kötü amaçlı yazılım içermediğini doğrulayamadığını söyler. Notarize edilmemiş her uygulama için aynısını söyler. Notarizasyon, Apple'ın otomatik kötü amaçlı yazılım taramasıdır ve yalnızca ücretli bir Apple Developer ID ile imzalanan uygulamalar için yapılır. Cumba'nın böyle bir kimliği yok; bu yüzden sürümleri ad hoc imzalanıyor.

- Uyarı, Apple'ın bu derlemeyi taramadığı anlamına gelir. Bir şey bulunduğu anlamına gelmez.
- macOS'in yerleşik kötü amaçlı yazılım koruması XProtect, her uygulamada olduğu gibi Cumba'yı da ilk açılışta yine denetler.
- Apple'ın taraması yerine, notarizasyonun göstermediği bir şeyi kendiniz doğrulayabilirsiniz: indirdiğiniz dosyanın bu açık koddan GitHub'da derlendiğini (aşağıdaki ilk satır).

## Kendiniz doğrulayın

Terminal'de birkaç komut; ilki için [GitHub CLI](https://cli.github.com) gerekir.

| İddia | Komut | Görmeniz gereken |
|---|---|---|
| Dosyayı bu depodan GitHub derledi | `gh attestation verify ~/Downloads/Cumba-vX.Y.Z.dmg --repo LJASP-studio/Cumba` | `Verification succeeded!` |
| Sürümün listelediği dosya bu | `shasum -a 256 ~/Downloads/Cumba-vX.Y.Z.dmg` | Sürümdeki `SHA256SUMS.txt` ile aynı değer |
| Yalnızca [Cumba.entitlements](../Cumba/Resources/Cumba.entitlements) dosyasındaki yetkileri var | `codesign -d --entitlements - /Applications/Cumba.app` | App Sandbox kapalı, ardından Apple Events, kamera, takvim ve konum; başka bir şey yok |
| Hardened Runtime açık | `codesign -dv /Applications/Cumba.app 2>&1 \| grep flags` | Bayraklar arasında `runtime` |
| Başka bir cihaz ona bağlanamaz | `lsof -nP -iTCP -sTCP:LISTEN \| grep Cumba` | Çıktı yok; YouTube uzantısı açıksa yalnızca `127.0.0.1` |
| Yalnızca [Gizlilik](privacy.tr.md#ag) bölümündeki sunucularla konuşur | `nettop -p Cumba` ya da LuLu, Little Snitch gibi giden bağlantıları gösteren bir güvenlik duvarı | Güncelleme kontrolü için `api.github.com`; hava durumu ve kapak görseli sunucuları yalnızca onları kullanırken |
| Çıktıktan sonra çalışan bir şey kalmaz | Cumba'dan çıkın, sonra `pgrep -fl Cumba` | Çıktı yok |
| Arka planda çalışacak bir şey kurmaz | `ls ~/Library/LaunchAgents /Library/LaunchAgents /Library/LaunchDaemons` | Cumba dosyası yok; oturum açıldığında başlatma, macOS'in Oturum Açma Öğeleri listesini Cumba'nın kendi adıyla kullanır |

Cumba'nın Mac'inizde nelere erişebildiği [İzinler ve neler çalışır](privacy.tr.md#izinler) bölümünde. Hazır derlenmiş bir uygulamayı hiç çalıştırmak istemezseniz [kaynaktan derleyin](install.tr.md#kaynaktan-derleme).
