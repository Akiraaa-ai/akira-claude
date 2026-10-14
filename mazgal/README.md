# MAZGAL (çalışma adı)

Backrooms tarzı, bodycam görünümlü birinci şahıs korku/kaçış oyunu. Three.js ile tarayıcıda çalışır, kurulum gerekmez.

## Çalıştırma

`index.html` dosyasına çift tıklayın (internet gerekir; Three.js bir CDN'den yüklenir).
Açılmazsa PowerShell'de `serve.ps1` çalıştırın, http://localhost:8765 adresine gidin.

## Kontroller

WASD yürü (açılışta arabayı sürer: W gaz, S fren/geri, A D direksiyon) · Shift koş · F fener · E kapıyı aç · R yedek pil tak · TAB envanter · M walkman (önce labirentte bulunur) · Fare ya da ok tuşları bak · Boşluk kaseti atla (açılış sahneleri atlanamaz) · T son kaseti tekrar izle · ESC ya da P duraklat · B Bekçi mesafesi (test)

## Dosyalar

| Dosya | Ne işe yarar |
| --- | --- |
| `index.html` | Oyunun tamamı (HTML + CSS + JS, tek dosya) |
| `GDD.md` | Oyun tasarım dokümanı: hikâye, yaratık, ipucu zinciri, final, sistem sırası |
| `serve.ps1` | Yerel test sunucusu (PowerShell) |
| `SESLENDIRME.md` | Seslendirme metni: karakterler, ses yönü, dosya adları |
| `dokular.js`, `dokular/` | Flow ile üretilen doku görselleri (duvar, tavan, asfalt, kulübe duvarı, torpido, kapı paneli, cam damlaları). `dokular.js` aynı görsellerin gömülü hâli; çift tıklayınca (file://) da çalışsın diye. Dosya yoksa oyun kodla çizilen dokulara döner. |
| `oda.js` | Selim'in odası (loft modeli, gömülü glb). Tüplü TV ve kül tablası koddan eklenir. |
| `modeller.js` | Sketchfab'dan alınan 3B modellerin gömülü hâli: bekçi kulübesi, masa telefonu, tüplü TV, sürücünün kolları, sokak (dükkânlar, apartman kuleleri, sokak lambası, çöp kutusu), araba (içi ve dışı), masa eşyaları, oyuncunun giyimli gövdesi. Dosya yoksa oyun kodla kurulan eski hâllere döner. |
| `tv/` | Açılıştaki TV yayınının fotoğrafları ve videosu (alp'in ürettiği görseller; video `mp4` ve `webm` olarak, tarayıcı hangisini oynatabiliyorsa). |
| `harita.js` | Labirentteki kapıların arkasındaki ofis: model, çarpışma ızgarası, lamba yerleri, duvar notları ve resimleri. İlk oynanışta yüklenir; dosya yoksa kapılar açılmaz. |
| `ses/` | Seslendirme ve efekt mp3'leri: `yagmur.mp3` hazır; `anlatici.mp3` açılıştaki TV yayınının sesi; `radyo.mp3` arabaya binince ve ESC menüsünde çalan parça; `muzik_1.mp3`–`muzik_5.mp3` oyunun müzikleri (alp'ten): walkman'de sırayla çalar (M aç/kapat, N sonraki; ruh sağlığını toparlar, dosya yoksa kodla üretilen eski bir ezgi çalar), `muzik_5.mp3` ayrıca TV yayınlarının altında çalar; `zil.mp3`, `kapi.mp3`, `yaklasma.mp3` isteğe bağlı (yoksa kodla üretilen ses çalar) |

## Ayarlar

Oyun içi menü (başlık ve ESC ekranı), dört sekme:
- **Görüntü:** grafik kalitesi (Düşük / Orta / Yüksek), parlaklık, görüş açısı (60–100°), bodycam efekti, kamera sallanması
- **Ses:** ana ses, ortam (yağmur, uğultu, rüzgâr), konuşmalar
- **Kontrol:** fare hassasiyeti, dikeyi ters çevir, altyazı aç/kapa ve boyutu
- **Tuşlar:** tuş listesi

Oyun açılınca önce uyarı ve logo ekranı gelir, bir tuşa basınca ana menü açılır (Yeni Oyun, Ayarlar, Kontroller, Yapımcılar, Çıkış). ESC ekranında Devam Et, Ayarlar, Baştan Başla ve Ana Menü var (son ikisi onay için iki tıklama ister). ESC açılış sinematiğini ve araba sürüşünü de durdurur. Seçimler tarayıcıda saklanır. Bilgisayar yavaşsa Düşük seçin.

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
- Masa telefonu: "Old Phone Blue 2", Peter Gatchev, Sketchfab Standart Lisansı. https://sketchfab.com/3d-models/old-phone-blue-2-f010badd4b564f79ac5f293922baf5c6 (ahize ayrı parça; alp gönderdi, eski CC BY-NC telefonun yerine).
- Tüplü TV: "CRT TV", Timothy Ahene, Sketchfab Standart Lisansı. https://sketchfab.com/3d-models/crt-tv-9ba4baa106e64319a0b540cf0af5aa9e (ekrandaki karlı yayın kodla çizilir).
- Sürücünün kolları: "Arms", RomeGD, Sketchfab Standart Lisansı. https://sketchfab.com/3d-models/arms-845beebb5fe043df90e210d93a9f4fc3 (eski kamyonette kullanılıyordu; yeni arabada gizli, iskeletli ve dokulu bir FPS kol modeli bekleniyor).
- Sokak (dükkânlar, apartman kuleleri, sokak lambası, çöp kutusu): "street city (7) for games FREE", dasy444, Sketchfab Standart Lisansı. https://sketchfab.com/3d-models/street-city-7-for-games-free-493a69b451284ff88346c7b3e4e1b5a7 (dükkân tabelalarındaki İngilizce/Almanca yazılar silinip aynı boya üslubunda Türkçe tabelalar yazıldı; garaj binası alınmadı).
- Walkman ve kaset: "SONY Walkman WMD-DT1 (Evangelion Ver.)", 융해열흡수 (heat_of_fusion), Sketchfab Standart Lisansı. https://sketchfab.com/3d-models/sony-walkman-wmd-dt1-evangelion-ver-9051b4d387964cdbbf7d1df9af79b50e (kulübe masasında; kaseti labirentteki kaset olarak kullanılır; kulaklıklar alınmadı, marka ve yazılar dokudan silindi).
- El feneri ve pil: "ZENITCO \"KLESCH-2P + LASER\" FLASHLIGHT", suspensy, Sketchfab Standart Lisansı. https://sketchfab.com/3d-models/zenitco-klesch-2p-laser-flashlight-c92e0a1bd8c64ab98d39f4e494045460 (alp gönderdi; dört fenerden biri ve paketten bir pil alındı; marka yazıları ve çıkartma dokudan silindi).
- Konserve: "Game-ready Can of beef Tushonka", Antarct1c, Sketchfab Standart Lisansı. https://sketchfab.com/3d-models/game-ready-can-of-beef-tushonka-d3426a22025a48a09547a3f167445cec (etiket yazıları silindi).
- Katlanır sandalye: "Game-ready Folding Chair", Antarct1c, Sketchfab Standart Lisansı. https://sketchfab.com/3d-models/game-ready-folding-chair-1fdf04d3539040ebba17db82f75488d9
- Kapıların arkasındaki ofis (`harita.js`): Sketchfab "backrooms-vr", VTX. Lisansı henüz doğrulanmadı; yayından önce model sayfasından bakılıp buraya yazılmalı. Dokular küçültüldü, ışık dokulara pişmiş hâliyle kullanılır, İngilizce EXIT tabelası ÇIKIŞ olarak yeniden boyandı, priz/duman dedektörü gibi küçük parçalar çıkarıldı.
- GLTFLoader (`gltf.js`): three.js r149, MIT lisansı, klasik betiğe çevrildi.
- Selim'in odası (`oda.js`): "interior (15) mini loft", dasy444, Sketchfab Standard lisansı (https://sketchfab.com/3d-models/interior-15-mini-loft-ace0229c6a9d4d7d9cbf709b53964f13). Çerçevelerdeki fotoğraflar oyuna özel resimlerle değiştirildi.
- Müzikler (`ses/muzik_1-5.mp3`): alp'in gönderdiği parçalar (Level 0, Fluorescent Corridors, Detuned Night, Detuned Night II, Channel 4 Test Card).
- Birinci şahıs eller: "Rigged FPS Arms" (eldivenli), alp'in gönderdiği FBX ve dokular; glb'ye çevrilip `eller.js` içine gömüldü. **Yazar ve lisans henüz doğrulanmadı, satıştan önce kontrol edilecek.**
- Oyuncunun gövdesi: "Man base mesh", BlakkMato, CC BY 4.0. https://sketchfab.com/BlakkMato (değiştirildi: iskelet ve ağırlıklar eklendi, mont, pantolon, bot ve fosforlu yelek gövdeden üretildi, baş ve saç birinci şahıs görünümde çıkarıldı).
- Araba: "2012 Hyundai Genesis Coupe", amirbuilds2000, Sketchfab Standart Lisansı. https://sketchfab.com/3d-models/2012-hyundai-genesis-coupe-95175f735af343b490b8709767a0271e (ön, arka ve direksiyon logoları silindi, jant kapağındaki logo boyandı; tekerlek, direksiyon ve gösterge ibreleri ayrı parça).
