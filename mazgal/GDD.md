# MAZGAL — Oyun Tasarım Dokümanı

> Çalışma adı. Backrooms tarzı, bodycam görünümlü birinci şahıs korku/kaçış oyunu. Three.js ile tarayıcıda çalışır.

## Oyunun özü

Belediye işçisi Selim, yağmurlu bir gecede açık kalan bir mazgalı kapatmaya giderken içine düşer ve kendini sarı duvarlı, nemli halılı, floresan ışıklı sonsuz bir koridor labirentinde bulur. Amaç çıkışı bulmak. Ekranda hep bodycam görüntüsü var: REC ●, tarih ve 00:00'da donmuş saat. Oyuncu bir şeyin kendisini avladığını bilmez, görmez, adını da duymaz. Sadece hisseder.

## Oyuncu ne yapar

- Yürür, koşar, fener yakar. Koşmak stamina harcar ve ses çıkarır.
- Haritada pil, kaset ve ipucu arar.
- Her oyunda farklı olan labirentte çıkışı bulmaya çalışır.

## Açılış sinematiği

Oyuncu izler, kontrol sonda gelir. Gece, yağmur yağıyor. Bodycam henüz takılı değil: görüntü çıplak göz, kayıt yazısı ve saat yok.

0. **Ev:** Selim'in odası (geçici, kodla kurulu; ev modeli gelince değişecek). Kanepede sigara içip yayın sonu çubukları gösteren tüplü TV'ye boş boş bakar. Ekranda MAZGAL yazısı daktiloyla belirip söner. Sigarayı kül tablasına bırakır, TV'deki yayın ekranı kaplar: tüplü TV görüntüsüyle fotoğraflar, video, "GECE KUŞAĞI · KAMU YAYINI" renk çubukları ve karlı yayın, üstünde anlatıcının sesi (mazgal, sokak ve koridor karesi yok). Son kare odanın TV'den görünüşü: kanepe boş, kül tablasında sigara tütüyor. Ses bitince kamera ekrandan geri çekilip Selim'in gözüne döner. Selim söylenir, TV'yi kapatır, saate bakar, sigarayı söndürür, kalkıp çıkar. Evin önünde yağmurda arabaya yürür, kapıyı açıp biner; oyuncu ana caddenin batı ucundan (uzun yol, sokak lambaları) kulübeye sürer (kavşaktan sola, ara sokak); kulübenin önüne gelince araba yanaşır.
1. **Kulübe:** Selim, belediyenin Fen İşleri kulübesinde nöbette, sandalyede uyuklamış. Pencereden yağmurlu sokak görünür. Masadaki eski telefon çalar, Selim döner ve açar. Masada karlı yayın veren tüplü televizyon, kasetli bir walkman, pil ve açılmış bir konserve; kulübede kodla çizilmiş eşya yok, hepsi model.
2. **Telefon:** Amiri arar: köşedeki mazgalın kapağı açık kalmış, biri ihbar etmiş, gidip kapatması lazım. Konuşmanın sonunda amir "içinden ses geliyormuş" der, bilmediğini söyleyip kapatır. Meşgul sesi.
3. **Sürüş:** Selim ahizeyi kapatır, bodycam'i takar (kayıt başlar, saat 23:52'den akar), kapıdan çıkıp kulübenin önündeki belediye kamyonetine biner. Buradan oyuncu sürer (W gaz, S fren/geri, A D direksiyon, fare ile etrafa bakış). Ara sokaktan çıkıp kavşakta sola döner; ana caddede mazgala yaklaşınca kamyonet kendiliğinden yanaşıp durur. Silecekler, yağmur damlaları, motor sesi ve gösterge çalışır. Selim inip mazgala yürür: kapak kenara çekilmiş, yanında devrilmiş bir koni var. "Kim açar bunu bu saatte..." Mazgalın yanındaki sokak lambası titremeye başlar.
4. **Mazgalın başı:** Aşağıdan vızıltı yükselir. Lamba söner, Selim feneri yakar, kuyuya eğilir: "...bu ses ne?" Kenar çöker.
5. **Düşüş:** Mazgalın altı 12 m'lik ıslak beton bir kuyu (paslı basamaklar, biri kopuk, boru). Kenar çöker, Selim kayar, kamera önce aşağı sonra yukarıdaki açıklığa ve yağmura bakarak düşer, duvara çarpıp savrulur (parazit, sarsıntı), karanlıkta yere çakılır.
6. **Çarpma:** Ağır bir çarpma sesi, kayıt kararır, kulak çınlaması. Bodycam saati 00:00:00'da donar ve oyun boyunca öyle kalır.
7. **Uyanma:** Yerde, yan yatmış görüntü. Göz kırpar gibi kararma açılıp kapanır, Selim yavaşça doğrulur. Vızıltı geri gelir. Altyazı: *"...neredeyim?"*
8. Kontrol oyuncuya geçer. Başlangıç karesinin tavanında düşülen delik görünür.

Replikler ve dosya adları `SESLENDIRME.md`'de. Yağmur sesi `ses/yagmur.mp3`; `ses/zil.mp3`, `ses/kapi.mp3` konursa kodla üretilen zil ve kapı sesinin yerine çalar.

Boşluk tuşu evdeki açılışı geçer (doğrudan arabaya). `CFG.intro = false` ile tamamen kapatılabilir.

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

- **Kasetler:** Önceki girenlerin bodycam kayıtları (Mehmet 2019, Ayşe 2021, Kenan 2023, Halil 2016, Zeynep 2024) ve sonuncusu Selim'in kendi kaydı (14.10.2026). Halil de mazgalı kapatmaya gelmiş bir belediye işçisi; son sözü "Selim'e söyleyin... gelmesin." Selim'in kaseti döngüyü ve sonraki adımı açar: pano çıkışın önünde, şifre kameradaki tarih (14.10 → 1410), "telefon çalınca açmayın". Kasetler başlangıçtan giderek uzaklaşarak yerleşir, Selim'inki en uzaktadır. Altyazılı ve sesli oynar, yaratıktan açıkça bahsetmez, sadece belirsiz uyarılar verir: "ışığı takip etmeyin", "ses kesilen yerde durun", "koşunca ayak seslerim çoğalıyor". Kayıt oynarken oyun durur.
- **Duvar yazıları:** Sürülmüş, akmış koyu boya. Uyanınca karşıdaki duvarda hep "IŞIĞI TAKİP ETME" yazar; Selim doğrulurken başını ona çevirir. Labirentte aralıklı 6 yazı daha: "KOŞMA", "SES KESİLİRSE DUR", "KARANLIKTA KIPIRDAMA", "KASETLERİ DİNLE", "SAYMAYI BIRAKTIM", "BURASI AYNI YER", çentik sayımı. Liste `WALL_TEXTS`, adet `CFG.wallTexts`.
- **Planlanan ipucu zinciri:** duvar yazısı → kaset (çıkışın nerede olduğu ve şifre) → elektrik panosu → bulunan bodycam → harita parçası → çıkış.

## Yapılacaklar (sırayla)

- [x] Açılış sinematiği (kulübe, telefon, kamyonetle sürüş, yağmurda yürüyüş, düşme)
- [x] Ev açılışı: sigara, MAZGAL yazısı, tüplü TV yayını ve anlatıcı, evden kulübeye sürüş, bodycam kulübede takılır
- [x] Açılış ekranı (kulaklık uyarısı, logo, "herhangi bir tuşa bas"), Steam tarzı ana menü (yeni oyun, ayarlar, kontroller, yapımcılar, çıkış; arkada yağmurlu sokakta açık mazgal ve titreyen lamba, radyo çalar), yenilenmiş duraklatma menüsü
- [x] Labirentte 12 tüplü TV: girişteki gece kuşağı yayını (fotoğraflar, video, renk çubukları) döner, anlatıcının sesi en yakın TV'den yönlü gelir; bekçi yakınken yayın karlanır
- [ ] Selim'in evi modeli (alp gönderecek)
- [x] Duvar yazıları
- [x] Labirentte ofise açılan kapılar (E), ofis haritası, duvar notları ve resimler, ofiste gerilim olayları
- [x] Oyuncunun giyimli gövdesi (aşağı bakınca görünür, yürürken bacak/kol hareketi)
- [x] Envanter (TAB), yedek pil (R), eğilip alma, ruh sağlığı ve walkman müziği (M, ses/muzik.mp3); müzik çalarken ortam sesleri kısılır, ruh sağlığı yavaş dolar
- [x] Gerçekçi birinci şahıs eller: fener tutan sağ el, yerden alan sol el, direksiyonda iki el
- [ ] Gövde: Flow kıyafet dokuları
- [ ] Elektrik panosu ve şifre
- [x] Harita parçası: 4 çeyrek, TAB'da birleşir; X en uzak çıkmazı gösterir, orada "BURADAYDIM" notu (1-8, 7'ye kadar çizik)
- [x] Koşu ~20 sn, tükenince yavaş dolar ve nefes nefese kalır (Selim replikleri: SESLENDIRME.md)
- [x] Walkman labirentte bulunur; muzik.mp3 yoksa kodla ezgi
- [ ] Çıkış ve final
- [x] Daha fazla kaset / bodycam kaydı (Halil, Zeynep, Selim)
- [ ] İngilizce desteği

## Telif notu

Kane Pixels içeriği, Backrooms wiki seviye/yaratık adları ve orijinal fotoğraf kullanılmaz. Dokular ya kodla üretilir ya da Flow ile üretilmiş görsellerdir (`dokular/`). 3B modeller Sketchfab'dan, lisansları README "Model kaynakları" bölümünde.
