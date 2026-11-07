# Cumba'nın özellikleri

Cumba'nın yaptığı her şey, parça parça. [README](../README.tr.md)'ye dön · [English](features.md)

## Medya

Hangi uygulama ne çalıyorsa (Safari, Chrome, YouTube, Spotify, Müzik, podcast'ler ve daha fazlası) tek bir mini oynatıcıda görünür; kapak görseli, ilerleme, sarma ve kontroller, uzantı ya da kurulum gerekmeden. Notch'un yanındaki küçük ses dalgası neyin çaldığını gösterir.

Cumba bunu sistemin Şu An Çalan bilgisinden okur; nasıl yaptığı [Medya, parlaklık ve özel API'ler](privacy.tr.md#medya-ve-ozel-apiler) bölümünde. **Ayarlar > Widget'lar > Medya > Tüm uygulamalardaki medyayı oku** seçeneğini kapatırsanız Spotify ve Müzik için AppleScript'i, YouTube için aşağıdaki uzantıyı kullanır.

<a name="youtube-uzantisi"></a>

### YouTube uzantısı (isteğe bağlı)

Medya her uygulamadan okurken gerekmez. Küçük bir Chrome uzantısı (diğer Chromium tarayıcılarda da çalışır) YouTube sekmelerinde çalanı yerel bir bağlantı üzerinden uygulamaya gönderir; uygulama da oynat, duraklat, sonraki ve sarma komutlarını geri yollar.

1. Cumba'da **Ayarlar > Bağlantılar**'ı açın, **YouTube uzantısını bağla**'yı açın ve **Uzantı Klasörünü Göster**'e tıklayın.
2. Chrome'da `chrome://extensions` adresini açın, **Geliştirici modu**'nu etkinleştirin ve **Paketlenmemiş öğe yükle**'ye tıklayın. 1. adımdaki klasörü seçin.
3. Uzantının **Ayrıntılar > Uzantı seçenekleri** sayfasını açın, **Ayarlar > Bağlantılar**'daki portu ve token'ı yapıştırıp kaydedin.

Chrome, uzantının `youtube.com` ve `music.youtube.com` üzerindeki verilerinizi okuyup değiştirebileceğini söyler: uzantı oynatıcıyı okur (başlık, kapak, ilerleme) ve orada oynat, duraklat, sonraki ve sarma düğmelerine basar. Başka hiçbir sitede çalışmaz, tek diğer izni depolamadır (port ve token için) ve yalnızca `127.0.0.1` ile konuşur.

## Claude Code ve Codex

Yapay Zeka Ajanları widget'ı bir oturumun o an ne yaptığını ("Notch.swift düzenleniyor", "Testler çalıştırılıyor"), başlığını ve son yanıtını, bağlam penceresinin ne kadar dolu olduğunu gösterir. Ajan çalışırken notch'un yanında bir halka döner, paneli açınca da onun sekmesi gelir.

Ajan soru sorduğunda, izin istediğinde veya bitirdiğinde notch'un altında ne olduğunu söyleyen bir bildirim açılır; **Aç** ajanın çalıştığı uygulamayı öne getirir. Bir oturum hata verince de görürsünüz. Claude Code'un (terminal, IDE uzantıları ve Claude masaüstü uygulaması) izin istekleri **İzin Ver**, **Reddet** ve **Terminalde** seçenekleriyle görünür; kart, isteğin tamamını gizli karakterleri görünür hale getirerek gösterir. Sorular ve plan onayları izin isteği değildir: ajanda kalırlar, onları ajan kendisi sorar; notch oturumun sizi beklediğini gösterir.

**Notch'taki İzin Ver, Claude Code'daki İzin Ver ile aynıdır: araç hemen çalışır.** Varsayılan olarak kabuk komutları terminalde yanıtlanır, geri kalan her şeye notch'tan izin verilebilir; Ayarlar > Ajanlar'dan her şeye izin verilmesini seçebilir ya da İzin Ver'i tamamen kapatıp yalnızca Reddet ve Terminalde seçeneklerini bırakabilirsiniz. Gizli karakter içeren isteklerde İzin Ver düğmesi hiç gösterilmez; kutusuna sığmayan bir istekte İzin Ver, sonuna kadar kaydırana kadar bekler.

Hook'ları **Ayarlar > Ajanlar**'dan kurun; `~/.claude/settings.json` değişikliğini önce siz görürsünüz ve yedek alınır. Hook'lar uygulamaya yalnızca sizin kullanıcı hesabınızın açabildiği özel bir soket üzerinden ulaşır; böylece başka hiçbir şey Claude Code'a uygulama adına cevap veremez. Hook'lar uzantınınkinden ayrı, kendi token'larını kullanır.

**Codex** de aynı şekilde çalışır: hook'larını **Ayarlar > Ajanlar > Codex**'ten kurun (`~/.codex/hooks.json` dosyasına yazılır), ardından Codex'te bir kez `/hooks` komutunu çalıştırıp onlara güvenin; Codex yeni hook'ları ancak bundan sonra çalıştırır.

Ayrıntılar ve elle kurulum [Claude Code ve Codex kurulumu](claude-code-setup.md) sayfasında (İngilizce).

## Widget'lar

Görüntülü görüşmeler için Katıl düğmeli takvim (günler arasında kaydırarak herhangi bir günün etkinliklerine bakın), zamanlayıcı, Pomodoro, Notlar'daki notlarınız (son notlar ve panelden yeni not), Apple Anımsatıcılar'dan yapılacaklar (işaretleyin, yenisini ekleyin), pano geçmişi (metin, bağlantı, görsel, dosya ve yeni ekran resimleri kartlar hâlinde), uyanık tut, teleprompter, pil, AirDrop destekli dosya rafı, kamera aynası, hava durumu, Kısayollar ve CPU/bellek grafiği.

Widget'lar sekmelerde durur. Panelden ya da Ayarlar'daki galeriden ekleyin, sekmeler arasında iki parmakla kaydırarak geçin; yeni kurulum yalnızca üçüyle başlar.

## Size uyan bir panel

Sekmeler altta ya da üstte durur ve doğrudan panelde düzenlenir (ad, simge, sıra, widget'lar). Panel açık sekme kadar geniştir; sekmesinde tek başına olan widget ayrıntılı görünür: Apple'ın widget'ı gibi önümüzdeki saatler ve günlerle hava durumu, etkinliklerinizin yanında ayın tamamı, büyük albüm kapağı. Yazı boyutu ve kapalı notch'un kameranın ne kadar dışına taşacağı ayarlanabilir.

## Temalar

Düz siyah ve Liquid Glass'tan Neon Tokyo, Sakura, Synthwave ve Narenciye'ye sekiz hazır tema. Kendi temanızı yapın: cam, düz veya renkli cam, renk geçişli zemin, neon kenar, renkler, font, köşe yuvarlaklığı, gölge ve animasyon. Panel boyutu ve yazı boyutu hangi temayı seçerseniz seçin aynı kalır. Temaları JSON olarak içe/dışa aktarın.

## Canlı etkinlikler

Çalışan zamanlayıcı, çalışan bir yapay zeka ajanı, bekleyen bir istek, şarj, çalan şarkı ya da ses veya parlaklık değişikliği kapalı notch'un iki yanında görünür.

## İsteğe bağlı ekstralar

Bunlar siz açana kadar kapalıdır: paneli istediğiniz ekranda gösterme, sistemin ses ve parlaklık göstergeleri yerine notch, mikrofon veya kamera kullanılırken bir nokta, toplantılardan önce geri sayım, medya kaynağı seçimi ve [kendi script'leriniz için bir API](#scriptler).

<a name="scriptler"></a>

## Script'ler

Kendi script'lerinizin, Kısayollar'ın veya derleme araçlarınızın notch'un yanında kısa bir durum göstermesi için **Ayarlar > Bağlantılar > Script'ler**'i açın. **Örnek Komutu Kopyala**, token'ınızla çalışmaya hazır bir komut kopyalar:

```bash
curl -s --unix-socket "$HOME/Library/Application Support/Cumba/hook.sock" \
  -H "X-Cumba-Token: <token>" -H "Content-Type: application/json" \
  -d '{"id":"build","title":"Build done","symbol":"hammer","duration":5}' \
  http://localhost/activity
```

Alanlar: `id` (harf, rakam, `.`, `_` ve `-`), `title` (en fazla 60 karakter), `symbol` (bir SF Symbol adı), `progress` (0 ile 1 arası, çubuk gösterir), `duration` (saniye, 1–3600) ve bir etkinliği kaldırmak için `"remove": true`. Etkinlikler yalnızca metindir, Claude Code istekleri gibi kaçışlanır ve içlerinde tıklanabilecek bir şey yoktur.

## Yolunuza çıkmaz

Tıklamalar menü çubuğuna geçer, pencere sürüklerken panel açılmaz, tam ekran uygulamalarda da çalışır (isterseniz orada gizlenir) ve boşta CPU kullanımı sıfırdır. Ayarlar için notch'a sağ tıklayın.

## Diller

Arayüz Türkçe, İngilizce, İspanyolca (İspanya ve Latin Amerika) ve Fransızca.
