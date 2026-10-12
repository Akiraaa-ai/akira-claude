# MAZGAL (çalışma adı)

Backrooms tarzı, bodycam görünümlü birinci şahıs korku/kaçış oyunu. Three.js ile tarayıcıda çalışır, kurulum gerekmez.

## Çalıştırma

`index.html` dosyasına çift tıklayın (internet gerekir; Three.js bir CDN'den yüklenir).
Açılmazsa PowerShell'de `serve.ps1` çalıştırın, http://localhost:8765 adresine gidin.

## Kontroller

WASD yürü · Shift koş · F fener · Fare bak · Boşluk sinematiği/kaseti atla · T son kaseti tekrar izle · I parazit testi · B Bekçi mesafesi (test)

## Dosyalar

| Dosya | Ne işe yarar |
| --- | --- |
| `index.html` | Oyunun tamamı (HTML + CSS + JS, tek dosya) |
| `GDD.md` | Oyun tasarım dokümanı: hikâye, yaratık, ipucu zinciri, final, sistem sırası |
| `serve.ps1` | Yerel test sunucusu (PowerShell) |

## Ayarlar

`index.html` başındaki `CFG` nesnesi: yürüme/koşma hızı, stamina, kafa sallanması, bodycam efekt şiddeti, labirent boyutu, pil, karanlık bölgeler, yaratık davranışı, açılış sinematiği (`intro`).

## Sistemler (index.html içinde sırayla)

- **Bodycam shader:** sahne bir render target'a çizilir; balık gözü, chromatic aberration, gren, tarama çizgileri, vinyet ve renk kayması. `interference` (0..1) bant kayması, gürültü ve renk ayrışmasını artırır.
- **Dokular:** sarı duvar, halı, tavan ve kuyu dokuları canvas ile kodla üretilir. Duvarlar InstancedMesh ile tek çizim.
- **Labirent:** DFS + rastgele duvar kaldırma (döngüler) + geniş alanlar. `grid[y][x]` (1 = duvar), her kare 4 m.
- **Oyuncu:** ızgara tabanlı çarpışma, stamina, yürüme/koşma için ayrı kafa sallanması.
- **Işık:** en yakın lambalara atanan ışık havuzu, ara sıra titreme, yaratık yakındayken güçlü titreme.
- **Fener ve pil, karanlık bölgeler, yaratık, kasetler, ses:** ayrıntılar `GDD.md` içinde.
- **Açılış sinematiği:** daktilo yazısı → kuyudan düşüş → karartma → yerde uyanma.

Kasetler `TAPES` listesindedir; `src` alanına video dosyası yazılırsa (ör. `kasetler/mehmet.mp4`) altyazılı ses yerine o video oynar.

## Notlar

- `window.__mazgal` ve B tuşu göstergesi test içindir, yayından önce kaldırılmalı.
- Telif: Kane Pixels içeriği, Backrooms wiki seviye/yaratık adları ve orijinal fotoğraf kullanılmaz.
