# Dedektif — Geliştirme Planı

Türkçe dedektif bulmaca oyunu. Flutter, hedef platform Android (Google Play).

## Temel ilke: veri odaklı vaka

Kodda hiçbir vakaya özel metin, isim ya da kural yok. Her vaka tek bir JSON dosyasıdır:

- `assets/cases/<vaka_id>.json` → vaka metinleri, şüpheliler, ipuçları, sorgular, çözüm, giriş sahnesi zaman çizelgesi
- `assets/images/<isim>.png|jpg|webp` → sahne, portre ve kapak görselleri (yoksa yer tutucu çizilir)
- `assets/audio/<isim>.mp3|ogg|wav` → müzik, efekt, seslendirme (yoksa sessizce atlanır)

Uygulama açılışta `AssetManifest` üzerinden `assets/cases/` altındaki tüm JSON'ları bulur. Yeni vaka = yeni JSON + görseller; kod değişmez.
Şema ayrıntısı: `docs/vaka_semasi.md`.

## Klasör yapısı

```
lib/
  main.dart, app.dart          → başlangıç, servislerin kurulumu, tema
  core/                        → tema, rota/geçiş yardımcıları
  models/                      → saf veri sınıfları (JSON → Dart)
  services/                    → vaka okuma, kayıt, ayarlar, ses, görsel çözümleme, satın alma, reklam, paylaşım
  features/<özellik>/          → ekranlar ve o ekrana ait controller (ChangeNotifier)
  widgets/                     → ortak bileşenler ve kodla yapılmış animasyonlar
tool/gorsel_listesi.dart       → JSON'lardan docs/gorsel_listesi.md üretir
test/                          → model, oyun mantığı ve baştan sona oynanış testleri
```

İş mantığı `features/game/game_controller.dart` içindedir (ipucu toplama, çelişki açma, suçlama değerlendirme). Ekranlar yalnızca controller'ı okur ve olayları iletir.

## Aşama 1 — Oynanabilir çekirdek
- Proje iskeleti, bağımlılıklar, klasör yapısı
- Vaka JSON şeması, modeller, `CaseRepository`
- `docs/vaka_01.md` → `assets/cases/vaka_01.json` (metinler aynen)
- Ekranlar: ana menü, vaka seçimi, sahne gezme (dokunma alanları), dedektif defteri, şüpheli listesi + sorgu (ipucu sunarak çelişki açma), suçlu seçimi (kim + neden), sonuç (kaç ipucuyla çözüldü, paylaş)
- Yer tutucu görseller (renkli kutu + dosya adı), gerçek görsel gelince otomatik kullanılır
- `docs/gorsel_listesi.md`
- Test: `flutter analyze` + baştan sona oynanış widget testi

## Aşama 2 — Atmosfer
- Giriş sahnesi: JSON'daki zaman çizelgesiyle seslendirme/efekt/müzik/yazı/titreme tetikleme, atlanabilir (`docs/giris_seslendirme.md` → `intro` bölümü)
- Ses servisi: müzik, efekt, seslendirme; ayarlardan açma/kapama; dosya yoksa hata vermeden geçer
- Kodla animasyonlar: yağmur parçacıkları, fade geçişleri, ipucu parlaması, ekran titremesi, daktilo yazısı, Ken Burns yakınlaşması

## Aşama 3 — Kalıcılık ve yayın
- İlerleme kaydı (`shared_preferences`): çözülen vakalar, en iyi skor, toplanan ipuçları, açılan çelişkiler, satın alınan paketler, ayarlar
- Para kazanma altyapısı: ilk vaka ücretsiz, diğerleri `packId` ile satın alma (`in_app_purchase`); ödüllü reklamla ipucu (`google_mobile_ads`), test kimlikleri `lib/services/monetization_config.dart` içinde
- Play Store release (aab) adımları: `docs/yayin.md`

## Varsayımlar
- Ekran dikey (portre) kilitli; sahne görselleri 9:16.
- "Neden" seçimi, JSON'daki `reasonOptions` listesinden yapılır; hem suçlu hem gerekçe doğruysa vaka çözülür.
- Ödüllü reklamın ödülü: sahnede bulunmamış bir ipucunun yerini kısa süre parlatmak.

## Vaka 1 (Şekersiz Kahve) aktarım notları
Metinler değiştirilmeden `assets/cases/vaka_01.json` dosyasına aktarıldı. Oyun yapısı için verilen kararlar:
- **Sahneler:** İpuçları üç sahneye dağıtıldı: Çalışma odası (fincan, tepsi, ilaç dolabı), Mutfak (kayıt defteri), Güvenlik kayıtları (kapı kaydı, iki kamera, telefon kaydı). Sahne adları bu yapı için eklendi.
- **Sorguda açılan ipuçları:** Kerem'in bahçe ifadesine bahçe kamerası ve telefon kaydı birlikte sunulunca çelişki açılır ve "Kerem’in ceket cebi" deftere eklenir. Ceket cebi bulununca "Şişe analizi" kendiliğinden gelir.
- **Diğer çelişkiler:** "Cebindeki şeker paketleri? → Susuyor." ceket cebi sunulunca; "Oysa Nuri Bey o saatte odadaydı…" koridor kamerası sunulunca açılır. "Çalışma odasında ne yaptın?" sorusu koridor kamerası bulununca görünür.
- **Neden seçenekleri:** Kaynakta çoktan seçmeli seçenek olmadığı için seçenekler metindeki cümlelerden kuruldu. Doğru cevap çıkarım zincirinin 2. ve 3. adımıdır; diğerleri kırmızı balıklardır (miras, zehre erişim, tepsi, kumar borcu).
- **İpucu hakkı:** Oyuncu 3 reklamsız ipucu hakkıyla başlar, her yanlış suçlama bir hak eksiltir. Hak bitince ipucu ödüllü reklamla alınır.
- **Giriş sahnesi:** Seslendirme şimdilik yok; giriş metni daktilo satırları olarak oynar.
- **"Gece yarısına kadar vaktin var":** Süre sınırı mekaniği eklenmedi, cümle atmosfer metni olarak kaldı.

## Yol haritası: alp'in özellik listesi (2026-10-12)
İlke: "Önce tek bir vakayı bu sistemlerle kusursuz yap, sonra çoğalt." Her aşama önce Vaka 1 üzerinde biter. Hepsi veri odaklı kalır: yeni özellikler vaka JSON'una isteğe bağlı alan olarak eklenir, kullanıcının vaka metni değiştirilmez.

### Aşama 4 — Oynanış çekirdeği (şimdi)
- **Büyüteçle olay yeri incelemesi:** Sahnede sürüklenen büyüteç, altındaki bölgeyi iki kat büyütür ve gizli ipuçlarını belli eder. `needsMagnifier: true` olan ipucu ancak büyüteç üstündeyken alınır.
- **Delil panosu:** Bulunan ipuçları mantar panoya iğnelenir, sürüklenerek dizilir. İki ipucuna sırayla dokununca kırmızı iple bağlanır. Doğru bağlantı (`connections`) bir çıkarım açar; çıkarım metni, vakanın çıkarım zincirinden gelir.
- **"Yalan söylüyorsun!" anı:** İfadeyle çelişen delil sunulunca ekran kırmızıya döner, titrer, şüphelinin tepkisi yazılır.
- **Zaman çizelgesi:** Kim, saat kaçta, neredeydi? Olay kartları ipuçları bulundukça açılır, oyuncu kartları saatlere kendisi yerleştirir ve kontrol eder (`timeline`).
- **Final suçlaması:** Kim + neden + kanıt. Kanıt adımında oyuncu defterinden belirli sayıda kanıt seçer (`solution.evidence`). Yanlış suçlama ceza puanı verir (`wrongAnswer.penaltyPoints`) ve ipucu hakkını eksiltir; tahminle geçilmez.
- **1–3 yıldız:** Kullanılan ipucu yardımı + ceza puanı ne kadar azsa o kadar çok yıldız (`stars`).
- **Dedektif rütbesi:** Toplam yıldızla Çaylak → Dedektif → Komiser Yardımcısı → Komiser → Başkomiser.

### Aşama 5 — Belgeler ve kurbanın telefonu
- Gerçek suç dosyası görünümü: polis tutanağı, otopsi raporu, gazete küpürü. Oyuncu belgeyi okuyup ipucunu kendisi işaretler.
- Kurbanın telefonu: kilit ekranı şifresi (doğum tarihi, evcil hayvan adı gibi başka belgelerde saklı), mesajlar ve silinmiş mesaj kurtarma, galeri (arka planda plaka, saat gibi detaylar), son 24 saatin konum geçmişi haritası, gizli numara çözülen arama kaydı.
- Telefondan çıkan delil sorguda sunulabilir (ör. konum geçmişi şüphelinin "evdeydim" ifadesini çürütür).

### Aşama 6 — Atmosfer
- Seslendirilmiş giriş, noir müzik, yağmur sesi, daktilo sesi: ses altyapısı hazır, dosyalar `assets/audio` altına gelince çalar.
- Parmak izi ve DNA mini oyunları: toz serpme, iz eşleştirme.
- Yanlış suçlamanın bedeli: masum biri tutuklanırsa hikâye değişir ve kötü son açılır; oyuncu vakayı tekrar oynar.
- Her vaka için tutarlı bir çizim tarzı (`docs/gorsel_listesi.md` üzerinden).

### Aşama 7 — Yapay zekâlı sorgu
- Her şüphelinin gizli dosyası: gerçek mazeret, sakladığı sır, yalan söylediği nokta, sinirlendiği konular.
- Oyuncu soruyu kendisi yazar, yapay zekâ karakter olarak ama yalnızca vaka gerçeklerine bağlı cevap verir; suçlu kendiliğinden itiraf etmez, yalnızca kanıt gösterilince çözülür.
- Stres göstergesi (doğru sorularla artar, cevaplar kısalır), envanterden delil sürükleme, sorgu başına 10 soru hakkı.
- API anahtarı uygulamaya gömülemeyeceği için küçük bir sunucu gerekir.

### Aşama 8 — Topluluk ve düzenli içerik (sunucu gerekir)
- Ortak çözüm: iki oyuncu aynı vakayı farklı ipuçlarıyla çözer.
- Topluluk teorileri ve oylama (Afterscene'deki topluluk mantığı yeniden kullanılabilir).
- Günlük mini vaka (Wordle mantığı, sonuç paylaşımı) ve haftalık yeni vaka.

### Aşama 9 — Pazar
- İlk 2–3 vaka ücretsiz, sonrası vaka paketleri (`access.free` / `access.packId` hazır).
- Reklam izleyerek ipucu (hazır).
- Türkçe ve İngilizce dil desteği: arayüz metinleri ve vaka metinleri için çift dil alanı.
