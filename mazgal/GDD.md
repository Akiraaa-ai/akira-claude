# MAZGAL — Oyun Tasarım Dokümanı

> Çalışma adı. Backrooms tarzı, bodycam görünümlü birinci şahıs korku/kaçış oyunu. Three.js ile tarayıcıda çalışır.

## Oyunun özü

Selim, gece vardiyasında bir mazgaldan düşüp sarı duvarlı, nemli halılı, floresan ışıklı sonsuz bir koridor labirentine düşer. Amaç çıkışı bulmak. Ekranda hep bodycam görüntüsü var: REC ●, tarih ve 00:00'da donmuş saat. Oyuncu bir şeyin kendisini avladığını bilmez, görmez, adını da duymaz. Sadece hisseder.

## Oyuncu ne yapar

- Yürür, koşar, fener yakar. Koşmak stamina harcar ve ses çıkarır.
- Haritada pil, kaset ve ipucu arar.
- Her oyunda farklı olan labirentte çıkışı bulmaya çalışır.

## Açılış sinematiği

1. **Daktilo yazısı:** Siyah ekranda satır satır, daktilo sesiyle:
   *"14 Ekim, 23:52. / Gece vardiyasının son turu. / Sokak lambası söndü. Mazgalın altından bir vızıltı geliyordu. / Eğildim. Izgara yerinden oynadı."*
2. **Düşüş:** Bodycam açılır. Kamera beton kuyunun tepesinden, mazgalın altından düşer; dönerek yuvarlanır, rüzgâr sesi yükselir, parazit artar. Aşağıda floresan ışığı belirir.
3. **Çarpma:** Ağır bir çarpma sesi, kayıt kararır. Kulak çınlaması.
4. **Uyanma:** Yerde, yan yatmış görüntü. Göz kırpar gibi kararma açılıp kapanır, Selim yavaşça doğrulur. Vızıltı geri gelir. Altyazı: *"...neredeyim?"*
5. Kontrol oyuncuya geçer. Başlangıç karesinin tavanında düşülen delik ve yukarıda mazgal görünür.

Boşluk tuşu sinematiği geçer. `CFG.intro = false` ile tamamen kapatılabilir.

## Korku nasıl çalışıyor (yaratık mantığı)

Yaratık (kod adı "Bekçi") hiç görünmez, adı oyunda geçmez. Üç şeyle belli eder kendini:

- **Lambalar:** Her 7-14 saniyede lambalar söner. Işık dönünce yaratık biraz daha yakındadır. Sönme anı "yaklaştı" demektir.
- **Ses:** Alçak, nefes gibi bir ses. Yaklaştıkça yükselir ve hangi yönden geldiği duyulur. Her ışınlanmada ağır bir ayak sesi gelir.
- **Bodycam bozulması:** Yaklaştıkça görüntüde parazit, bant kayması, renk ayrışması ve cızırtı artar.

Davranış:

- Oyuncuya labirentin yolundan yaklaşır (BFS en kısa yol), duvardan geçmez.
- Koşan oyuncunun sesini duyar ve karartma başına fazladan bir adım atar.
- Fener kapalı ve oyuncu hareketsizse çoğu zaman (%75) rastgele dolaşır.
- 1.4 m'ye gelirse ya da oyuncunun karesine girerse "KAYIT KESİLDİ"; tıklayınca yeni labirentle baştan başlar.
- İlk 20 saniyede yaklaşmaz, oyuncuya uyum süresi verir.

## Kaynak yönetimi

- Fener pili yaklaşık 4 dakikada biter, %20 altında titrer, bitince söner. Yeşil piller yarım pil doldurur.
- Karanlık bölgeler: başlangıçtan uzak 3 alanda lambalar kapalı, ortam ışığı ve vızıltı kesilir, sis koyulaşır. Bu bölgelerde de pil bulunur: risk karşılığında ödül.
- Denge: feneri kapatmak pil kazandırır ama kör bırakır; koşmak hızlıdır ama yaratığı çeker.

## İpuçları ve hikâye

- **Kasetler:** Önceki girenlerin bodycam kayıtları (Mehmet, Ayşe, Kenan). Altyazılı ve sesli oynar, yaratıktan açıkça bahsetmez, sadece belirsiz uyarılar verir: "ışığı takip etmeyin", "ses kesilen yerde durun", "koşunca ayak seslerim çoğalıyor". Kayıt oynarken oyun durur.
- **Duvar yazıları:** "IŞIĞI TAKİP ETME" gibi (henüz eklenmedi).
- **Planlanan ipucu zinciri:** duvar yazısı → kaset (çıkışın nerede olduğu ve şifre) → elektrik panosu → bulunan bodycam → harita parçası → çıkış.

## Yapılacaklar (sırayla)

- [x] Açılış sinematiği (daktilo yazısı, düşme)
- [ ] Duvar yazıları
- [ ] Elektrik panosu ve şifre
- [ ] Harita parçası
- [ ] Çıkış ve final
- [ ] Daha fazla kaset / bodycam kaydı
- [ ] İngilizce desteği

## Telif notu

Kane Pixels içeriği, Backrooms wiki seviye/yaratık adları ve orijinal fotoğraf kullanılmaz. Tüm dokular kodla üretilir.
