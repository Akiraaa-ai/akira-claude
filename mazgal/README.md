# MAZGAL (çalışma adı)

Backrooms tarzı, bodycam görünümlü birinci şahıs korku/kaçış oyunu. Three.js ile tarayıcıda çalışır, kurulum gerekmez.

## Çalıştırma

`index.html` dosyasına çift tıklayın (internet gerekir; Three.js bir CDN'den yüklenir).
Açılmazsa PowerShell'de `serve.ps1` çalıştırın, http://localhost:8765 adresine gidin.

## Kontroller

WASD yürü (açılışta kamyoneti sürer: W gaz, S fren/geri, A D direksiyon) · Shift koş · F fener · Fare ya da ok tuşları bak · Boşluk sinematiği/kaseti atla · T son kaseti tekrar izle · I parazit testi · B Bekçi mesafesi (test)

## Dosyalar

| Dosya | Ne işe yarar |
| --- | --- |
| `index.html` | Oyunun tamamı (HTML + CSS + JS, tek dosya) |
| `GDD.md` | Oyun tasarım dokümanı: hikâye, yaratık, ipucu zinciri, final, sistem sırası |
| `serve.ps1` | Yerel test sunucusu (PowerShell) |
| `SESLENDIRME.md` | Seslendirme metni: karakterler, ses yönü, dosya adları |
| `dokular.js`, `dokular/` | Flow ile üretilen doku görselleri (duvar, tavan, asfalt, kulübe duvarı, torpido, kapı paneli, cam damlaları). `dokular.js` aynı görsellerin gömülü hâli; çift tıklayınca (file://) da çalışsın diye. Dosya yoksa oyun kodla çizilen dokulara döner. |
| `modeller.js` | Sketchfab'dan alınan 3B modellerin gömülü hâli (şimdilik bekçi kulübesi). Dosya yoksa oyun kodla kurulan kulübeye döner. |
| `ses/` | Seslendirme ve efekt mp3'leri: `yagmur.mp3` hazır; `zil.mp3`, `kapi.mp3`, `yaklasma.mp3` isteğe bağlı (yoksa kodla üretilen ses çalar) |

## Ayarlar

Oyun içi menü (başlık ve duraklatma ekranı): grafik kalitesi (Düşük / Orta / Yüksek), parlaklık, bodycam efekti şiddeti, fare hassasiyeti. Seçimler tarayıcıda saklanır. Bilgisayar yavaşsa Düşük seçin.

Kod tarafında `index.html` başındaki `CFG` nesnesi: yürüme/koşma hızı, stamina, kafa sallanması, bodycam efekt şiddeti, labirent boyutu, pil, karanlık bölgeler, yaratık davranışı, açılış sinematiği (`intro`).

## Sistemler (index.html içinde sırayla)

- **Bodycam shader:** sahne bir render target'a çizilir; balık gözü, chromatic aberration, gren, tarama çizgileri, vinyet ve renk kayması. `interference` (0..1) bant kayması, gürültü ve renk ayrışmasını artırır.
- **Dokular:** duvar, tavan, asfalt, kulübe, torpido ve kapı paneli `dokular.js` içindeki fotoğraflardan gelir (`photoTex`); halı, kuyu ve geri kalanlar canvas ile kodla üretilir. Duvarlar InstancedMesh ile tek çizim.
- **Labirent:** DFS + rastgele duvar kaldırma (döngüler) + geniş alanlar. `grid[y][x]` (1 = duvar), her kare 4 m.
- **Oyuncu:** ızgara tabanlı çarpışma, stamina, yürüme/koşma için ayrı kafa sallanması.
- **Işık:** en yakın lambalara atanan ışık havuzu, ara sıra titreme, yaratık yakındayken güçlü titreme.
- **Fener ve pil, karanlık bölgeler, yaratık, kasetler, ses:** ayrıntılar `GDD.md` içinde.
- **Açılış sinematiği:** yağmurlu sokakta Fen İşleri kulübesi → telefon → kulübenin önündeki kamyonete biniş → oyuncu kamyoneti mazgala sürer (ara sokak, kavşakta sola, ana cadde; yaklaşınca kendiliğinden durur) → mazgala yürüyüş → kuyudan düşüş → karartma → yerde uyanma. Sokak (`buildStreet`) yalnızca açılışta kurulur, düşüşten sonra silinir.
- **Görsellik:** floresanlarda parlama (bloom, çeyrek çözünürlükte iki geçiş), duvar diplerinde ve tavan köşelerinde gölge (duvar maskesinden bulanıklaştırılmış doku, zemin ve tavana çarpılarak bindirilir), geniş alanlarda kolonlar, priz, havalandırma, eksik ve lekeli tavan karoları, halı lekeleri. Kalite ayarı çözünürlüğü, ışık sayısını, parlamayı ve detay yoğunluğunu değiştirir.
- **Duvar yazıları:** canvas ile boyanmış yarı saydam paneller; ilki başlangıçta görüş alanına, diğerleri uzağa ve aralıklı yerleşir (`WALL_TEXTS`).

Seslendirme: `ses/` klasörüne `SESLENDIRME.md`'deki adlarla mp3 konursa kasetler ve Selim'in replikleri o kayıtlarla çalar. `serve.ps1` ile açınca kayda bodycam mikrofonu filtresi ve oda yankısı eklenir.

Kasetler `TAPES` listesindedir; `src` alanına video dosyası yazılırsa (ör. `kasetler/mehmet.mp4`) altyazılı ses yerine o video oynar.

## Notlar

- `window.__mazgal` ve B tuşu göstergesi test içindir, yayından önce kaldırılmalı.
- Telif: Kane Pixels içeriği, Backrooms wiki seviye/yaratık adları ve orijinal fotoğraf kullanılmaz.

## Ses kaynakları

- `ses/yagmur.mp3`: Pixabay, liecio, "Calming Rain" (Pixabay İçerik Lisansı). Döngü için 58 sn'ye kısaltıldı.

## Model kaynakları

- Bekçi kulübesi: "Guard Booth with interior", castleonsandYT, CC BY 4.0. https://sketchfab.com/3d-models/guard-booth-with-interior-181cd7b921c14f70ba5b64d3f4fdd8db (oyun için küçültülmüş dokular, kapı ayrı parça).
