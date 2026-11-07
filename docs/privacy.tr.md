# Gizlilik ve izinler

[README](../README.tr.md)'ye dön · [English](privacy.md)

<a name="ag"></a>

## İnternete çıkanlar

Telemetri yok. Her şey Mac'inizde kalır. Şu özellikler ağ isteği yapar, yalnızca siz kullanırken:

| Özellik | İstek |
|---|---|
| Spotify ile medya widget'ı | Spotify'ın görsel sunucusundan (`i.scdn.co`) panel ve kapalı notch için kapak görseli |
| YouTube ile medya widget'ı | YouTube'un görsel sunucularından (`*.ytimg.com`, `*.googleusercontent.com`, `*.ggpht.com`; sayfanın kendi kullandığı adres) panel ve kapalı notch için küçük resim |
| Hava durumu widget'ı | Yaklaşık 10 km'ye yuvarlanmış konumunuz (ya da seçtiğiniz şehrin koordinatları) `api.open-meteo.com`'a; konumunuzla birlikte şehir adı için aynı yuvarlanmış koordinatlar Apple Haritalar'a; aradığınız şehir adı, dilinizle birlikte `geocoding-api.open-meteo.com`'a. Yalnızca widget ekrandayken, en fazla 15 dakikada bir |
| Güncelleme denetimi | Açılışta ve günde bir kez `api.github.com`'dan sürüm listesi, kullanıcı aracısı olarak Cumba'nın sürümüyle; Ayarlar > Genel'den kapatılabilir |

## Mac'inizde kalanlar

Kamera (Ayna widget'ı) yalnızca panel onu gösterirken çalışır ve hiçbir şey kaydedilmez. Raf yalnızca dosya yollarını Mac'inizde tutar. Notlar ve Yapılacaklar, Mac'inizdeki Apple Notlar ve Apple Anımsatıcılar'ı okuyup yazar; hiçbir şey kopyalanmaz ya da gönderilmez. Önceki sürümlerin notu (`notes.txt`) bir kez Apple Notlar'a taşınır, dosya yerinde bırakılır.

Pano Geçmişi son 20 kopyanızı (metin, bağlantı, görsel ve dosya) yalnızca bellekte tutar ve uygulamaların parola olarak işaretlediği öğeleri almaz; sekmelerinizden birindeyken, bir kopyayı kaçırmamak için panel kapalıyken de panonun değişip değişmediğini saniyede bir kontrol eder. "Yeni ekran resimlerini ekle" açıksa ekran resmi klasöründeki yeni ekran resimlerini izler ve yalnızca konumlarını tutar. Mikrofon ve kamera göstergesi yalnızca bir cihazın kullanımda olup olmadığını okur; sese veya görüntüye asla erişmez.

Açıldığında uzantı sunucusu yalnızca `127.0.0.1` adresini dinler, yalnızca Cumba uzantısını kabul eder ve Anahtar Zinciri'nde saklanan kendi token'ını ister.

<a name="izinler"></a>

## İzinler ve neler çalışır

Aşağıdakilerin hepsi, gerektiren özelliği açana kadar kapalıdır veya kullanılmaz. Her birinin güncel durumu Ayarlar > İzinler'de görünür.

| Ne | Neden | Ne zaman |
|---|---|---|
| Sistemin Şu An Çalan yardımcısı | Her uygulamadaki medya ve kontrolleri | Uygulama açıkken çalışır; yerine AppleScript kullanmak için "Tüm uygulamalardaki medyayı oku" seçeneğini kapatın. Bkz. [aşağısı](#medya-ve-ozel-apiler) |
| Spotify ve Müzik için Otomasyon (Apple Events) | Çalan parçayı okumak; oynat, duraklat, atla, sar | Yalnızca "Tüm uygulamalardaki medyayı oku" kapalıyken; Ayarlar'dan istenir, komutlar yalnızca o uygulama zaten açıkken gönderilir |
| Notlar için Otomasyon (Apple Events) | Notlar widget'ı: son notları listelemek, açmak, yeni not oluşturmak | Notlar'ı widget'ta ya da Ayarlar'da bağladığınızda istenir; Cumba Notlar'ı arka planda başlatır ve var olan hiçbir notu değiştirmez |
| Takvim (tam erişim) | Takvim widget'ı | Widget'ta veya Ayarlar'da İzin Ver'e tıkladığınızda istenir |
| Anımsatıcılar (tam erişim) | Yapılacaklar widget'ı: anımsatıcıları göstermek, işaretlemek ve eklemek | Widget'ta veya Ayarlar'da İzin Ver'e tıkladığınızda istenir |
| Konum | Hava durumu widget'ı, bulunduğunuz yerin havası için | Konumumu Kullan'a tıkladığınızda istenir; şehir seçerseniz kullanılmaz |
| Kamera | Ayna widget'ı | Yalnızca panel onu gösterirken; hiçbir şey kaydedilmez |
| `127.0.0.1` üzerinde yerel sunucu | İsteğe bağlı YouTube uzantısı bağlantısı | Yalnızca Ayarlar > Bağlantılar'dan açtıktan sonra |
| Özel Unix soketi | Claude Code ve Codex hook'ları ve [script etkinlikleri](features.tr.md#scriptler) | Yalnızca hook'lar kuruluyken veya script etkinlikleri açıkken |
| `~/.claude/settings.json`, `~/.codex/hooks.json` | Claude Code ve Codex hook'larını kurmak ve kaldırmak | Yalnızca değişikliği gözden geçirdikten sonra; yedek alınır |
| `~/.claude/projects` içindeki Claude Code oturum kayıtları | Yapay Zeka Ajanları widget'ında bağlam kullanımı ve oturum başlığı | Yalnızca bu Mac'te, son 256 KB, oturum sürerken okunur |
| Erişilebilirlik | Ses veya parlaklık tuşlarını yönetmek | Yalnızca "Sistemin ses göstergesinin yerine geç" veya "…parlaklık göstergesinin…" açıksa |
| Pano | Pano Geçmişi widget'ı | Yalnızca o widget paneldeyken |
| Dosyalar ve Klasörler (Masaüstü ya da ekran resimlerinin kaydedildiği yer) | Yeni ekran resimlerini Pano Geçmişi'ne ekleme | Yalnızca "Yeni ekran resimlerini ekle" açıksa |
| Oturum Açma Öğeleri | Oturum açıldığında başlatma | Siz açana kadar kapalı |
| Ağ | Kapak görselleri, hava durumu, güncelleme kontrolü | Bkz. [İnternete çıkanlar](#ag) |

App Sandbox kapalı: sandbox'taki bir uygulama Spotify ve Müzik'i komutla yönetmek, Claude Code hook'larının ulaştığı soketi çalıştırmak ve `~/.claude/settings.json` dosyasını düzenlemek için istisnalara ihtiyaç duyar. Hardened Runtime açık ve uygulamanın yalnızca [Cumba.entitlements](../Cumba/Resources/Cumba.entitlements) dosyasındaki yetkileri var (Apple Events, takvim, konum, kamera).

Cumba hiçbir zaman telemetri göndermez, yönetici parolası istemez, yardımcı araç, çekirdek veya sistem uzantısı kurmaz, sistem ayarlarını değiştirmez, kod indirmez ve kendini güncellemez. Tehdit modeli ve güvenlikle ilgili kodun haritası [SECURITY.md](../SECURITY.md) dosyasında (İngilizce).

<a name="medya-ve-ozel-apiler"></a>

## Medya, parlaklık ve özel API'ler

macOS'ta bir uygulamanın diğer uygulamaların ne çaldığını görmesinin ya da Apple silicon'da dahili ekranın parlaklığını okumasının açık bir yolu yok. Cumba yalnızca bunlar için iki özel Apple çerçevesi kullanır, başka hiçbir şey için değil:

- **MediaRemote**, sistemin Şu An Çalan bilgisi (medya tuşlarının ve Denetim Merkezi'nin kullandığı). macOS bunu yalnızca Apple'ın kendi programlarına yanıtlar; bu yüzden Cumba kendi uygulama paketindeki küçük bir yardımcı kitaplığı ([kaynak](../NowPlayingHelper/CumbaNowPlaying.m)) sistemin `/usr/bin/perl`'ü içinde, boş bir ortamla çalıştırır. Yardımcı yalnızca Şu An Çalan'ı okur ve oynat, duraklat, atla ve sar komutlarını iletir; hiçbir dosya ya da ağ bağlantısı açmaz ve Cumba kapanınca çıkar. Bunun yerine Spotify ve Müzik için AppleScript'i, YouTube için uzantıyı kullanmak isterseniz **Ayarlar > Widget'lar > Medya > Tüm uygulamalardaki medyayı oku** seçeneğini kapatın.
- **DisplayServices**, yalnızca notch'taki parlaklık düzeyi için. Kullanılmasını istemiyorsanız **Ayarlar > Genel > Parlaklık değişikliklerini notch'ta göster** seçeneğini kapatın.

Özel API'ler herhangi bir macOS güncellemesiyle değişebilir. Çalışmayı bırakırlarsa Cumba yukarıdaki açık yollara geri döner ve çalışmaya devam eder.
