# MAZGAL (çalışma adı)

Backrooms tarzı, bodycam görünümlü birinci şahıs korku/kaçış oyunu. Three.js ile tarayıcıda çalışır, kurulum gerekmez.

## Çalıştırma

`index.html` dosyasına çift tıklayın (internet gerekir; Three.js bir CDN'den yüklenir).
Açılmazsa PowerShell'de `serve.ps1` çalıştırın, http://localhost:8765 adresine gidin.

## Kontroller

WASD yürü (açılışta arabayı sürer: W gaz, S fren/geri, A D direksiyon) · Shift koş · F fener · Fare ya da ok tuşları bak · Boşluk sinematiği/kaseti atla · T son kaseti tekrar izle · ESC ya da P duraklat · I parazit testi · B Bekçi mesafesi (test)

## Dosyalar

| Dosya | Ne işe yarar |
| --- | --- |
| `index.html` | Oyunun tamamı (HTML + CSS + JS, tek dosya) |
| `GDD.md` | Oyun tasarım dokümanı: hikâye, yaratık, ipucu zinciri, final, sistem sırası |
| `serve.ps1` | Yerel test sunucusu (PowerShell) |
| `SESLENDIRME.md` | Seslendirme metni: karakterler, ses yönü, dosya adları |
| `dokular.js`, `dokular/` | Flow ile üretilen doku görselleri (duvar, tavan, asfalt, kulübe duvarı, torpido, kapı paneli, cam damlaları). `dokular.js` aynı görsellerin gömülü hâli; çift tıklayınca (file://) da çalışsın diye. Dosya yoksa oyun kodla çizilen dokulara döner. |
| `modeller.js` | Sketchfab'dan alınan 3B modellerin gömülü hâli: bekçi kulübesi, masa telefonu, tüplü TV, sürücünün kolları, apartman blokları, araba (içi ve dışı). Dosya yoksa oyun kodla kurulan eski hâllere döner. |
| `ses/` | Seslendirme ve efekt mp3'leri: `yagmur.mp3` hazır; `zil.mp3`, `kapi.mp3`, `yaklasma.mp3` isteğe bağlı (yoksa kodla üretilen ses çalar) |

## Ayarlar

Oyun içi menü (başlık ve ESC ekranı), dört sekme:
- **Görüntü:** grafik kalitesi (Düşük / Orta / Yüksek), parlaklık, görüş açısı (60–100°), bodycam efekti, kamera sallanması
- **Ses:** ana ses, ortam (yağmur, uğultu, rüzgâr), konuşmalar
- **Kontrol:** fare hassasiyeti, dikeyi ters çevir, altyazı aç/kapa ve boyutu
- **Tuşlar:** tuş listesi

ESC ekranında ayrıca Devam Et, Baştan Başla ve Ana Menü var (son ikisi onay için iki tıklama ister). ESC açılış sinematiğini ve araba sürüşünü de durdurur. Seçimler tarayıcıda saklanır. Bilgisayar yavaşsa Düşük seçin.

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
- Masa telefonu: "Office Phone", R3indeer, CC BY-NC 4.0. https://sketchfab.com/3d-models/office-phone-7b12706d32264bca8698a81bdfe5300a (ahize ayrı parça). **Ticari olmayan lisans:** oyun satılacaksa bu model değiştirilmeli.
- Tüplü TV: "CRT TV", Timothy Ahene, Sketchfab Standart Lisansı. https://sketchfab.com/3d-models/crt-tv-9ba4baa106e64319a0b540cf0af5aa9e (ekrandaki karlı yayın kodla çizilir).
- Sürücünün kolları: "Arms", RomeGD, Sketchfab Standart Lisansı. https://sketchfab.com/3d-models/arms-845beebb5fe043df90e210d93a9f4fc3 (eski kamyonette kullanılıyordu; yeni arabada gizli, iskeletli ve dokulu bir FPS kol modeli bekleniyor).
- Apartman blokları: "street city (7) for games FREE", dasy444, Sketchfab Standart Lisansı. https://sketchfab.com/3d-models/street-city-7-for-games-free-493a69b451284ff88346c7b3e4e1b5a7 (yalnız iki blok tipi alındı; yabancı tabelalı dükkânlar alınmadı).
- Araba: "2012 Hyundai Genesis Coupe", amirbuilds2000, Sketchfab Standart Lisansı. https://sketchfab.com/3d-models/2012-hyundai-genesis-coupe-95175f735af343b490b8709767a0271e (ön, arka ve direksiyon logoları silindi, jant kapağındaki logo boyandı; tekerlek, direksiyon ve gösterge ibreleri ayrı parça).
