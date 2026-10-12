# MAZGAL — Seslendirme metni

Her replik ayrı bir mp3 dosyasıdır. Dosyaları `ses/` klasörüne aşağıdaki adlarla koyun. Oyun dosyayı bulursa onu çalar, bulamazsa tarayıcının Türkçe sesine geri döner. Bir kısmını kaydetmek de yeter.

## Genel yön

- Bunlar stüdyo kaydı değil. Hepsi göğse takılı bir bodycam'in mikrofonuna, sessiz bir koridorda konuşulmuş. Bağırma yok, çoğu yarı fısıltı.
- Cümle aralarında nefes, duraksama, yutkunma olsun. Kesik cümleler kesik kalsın.
- Yaratığın adı hiç geçmez. Kimse "canavar" demez, korktukları şeyi anlatamazlar.
- Arka plana müzik veya efekt koymayın. Vızıltıyı, cızırtıyı ve oda yankısını oyun ekliyor (`serve.ps1` ile açınca mikrofon filtresi de devreye girer).

**ElevenLabs için:** Türkçe destekleyen çok dilli bir model, Stability düşük (%30-45, daha duygusal), Style biraz açık. Her repliği ayrı üretip mp3 indirin. Yavaş okutmak için cümle sonlarına "..." eklemek işe yarar.

## Giriş sahnesi: Selim ve Amir

Gece, belediyenin Fen İşleri kulübesinde nöbetteki Selim'e amiri telefon eder, açık kalan mazgalın kapağını kapatmaya yollar. Selim yürüyüp mazgala gider, aşağıdan gelen sesi dinlemek için eğilir ve düşer.

**Selim:** Belediye işçisi, 30'larında, gece nöbetinde uyuklarken telefon çalmış. Yorgun, biraz huysuz ama saygılı ("abi" diyor). Mazgalın başında sesi kısılır, yarı fısıltı. "Neredeyim" düşüşten sonra sersemlemiş, boğuk.

**Amir:** 50'lerinde, kalın sesli, evden arıyor, uykulu ve aceleci. Telefon hattı efektini oyun ekliyor (`serve.ps1` ile açınca), siz düz kaydedin. "İçinden ses geliyormuş" kısmını kendisi de tuhaf bulduğu için duraksayarak söylüyor.

| Dosya | Kim | Replik |
| --- | --- | --- |
| `selim_01.mp3` | Selim | Alo. |
| `amir_01.mp3` | Amir | Selim, uyumuyorsun değil mi? |
| `selim_02.mp3` | Selim | Yok abi. Söyle. |
| `amir_02.mp3` | Amir | Köşedeki mazgalın kapağı açık kalmış. Biri aramış. |
| `amir_03.mp3` | Amir | Git bir bak, kapat şunu. Sabah çocuklar oradan geçiyor. |
| `selim_03.mp3` | Selim | Tamam abi, çıkıyorum. |
| `amir_04.mp3` | Amir | Bir de... içinden ses geliyormuş. Öyle dedi kadın. |
| `selim_04.mp3` | Selim | Ne sesi? |
| `amir_05.mp3` | Amir | Bilmiyorum. Git bak işte. |
| `selim_05.mp3` | Selim | Kim açar bunu bu saatte... (yürürken kendi kendine, mırıldanarak) |
| `selim_06.mp3` | Selim | ...bu ses ne? (mazgalın başında, fısıltı) |
| `selim_neredeyim.mp3` | Selim | ...neredeyim? (düşüşten sonra) |

## Efekt sesleri (isteğe bağlı)

| Dosya | Ne zaman çalar |
| --- | --- |
| `yagmur.mp3` | Açılıştaki sokak sahnesi boyunca, döngüde (hazır) |
| `zil.mp3` | Kulübedeki telefon çalarken |
| `kapi.mp3` | Selim kulübenin kapısını açarken |
| `yaklasma.mp3` | Labirentte ışıklar söndüğünde bir şey yaklaşırken (ağır adım sesleri yerine) |

Yoksa oyun bunları kodla üretir.

## Kaset 1 · Mehmet (2019)

Orta yaşlı, kalın sesli, kendini sakin tutmaya çalışan biri. Günlerdir uyumamış. Son cümlede sesi kırılıyor.

| Dosya | Replik |
| --- | --- |
| `mehmet_01.mp3` | Kayıt... çalışıyor mu? Tamam. Çalışıyor. |
| `mehmet_02.mp3` | Kaç gündür buradayım bilmiyorum. Saat hep sıfırda. |
| `mehmet_03.mp3` | Işıklar bazen sönüyor. Söndüğünde... olduğunuz yerde kalın. |
| `mehmet_04.mp3` | Işığı takip etmeyin. Işık bir yere götürmüyor. Ben denedim. |

## Kaset 2 · Ayşe (2021)

Genç kadın, hızlı ve fısıltılı konuşuyor, sanki biri duyacakmış gibi. Panik bastırılmış, cümleler arasında arkasını dinliyor.

| Dosya | Replik |
| --- | --- |
| `ayse_01.mp3` | Bunu bulan biri varsa... beni dinle. |
| `ayse_02.mp3` | Koşunca ayak seslerim çoğalıyor. Hepsi benim değil. |
| `ayse_03.mp3` | Feneri kapatıp kıpırdamadan durunca daha az... fark ediliyorum sanki. |
| `ayse_04.mp3` | Ses kesilen yerde durun. Vızıltı kesilirse orada bir şey var demektir. |

## Kaset 3 · Kenan (2023)

40'larında, yorgun ve biraz kopuk, kendi kendine konuşur gibi. Son replik yarıda kesiliyor: "onu—" dedikten sonra ses aniden bitmeli.

| Dosya | Replik |
| --- | --- |
| `kenan_01.mp3` | Duvarlar hep aynı. Ama halı... halı hep ıslak. |
| `kenan_02.mp3` | Kamerada bir şey görmüyorum. Ama görüntü bozuluyor. Hep yaklaşınca. |
| `kenan_03.mp3` | Biri buradan çıkmış. Eminim. Bir pano gördüm, kilitliydi. |
| `kenan_04.mp3` | Şifreyi... şifre kasetteydi. Diğer kasette. Ben onu— |

## Kaset 4 · Halil (2016)

Belediye işçisi, 40'larında, Selim'le aynı işi yapmış. Sakin, biraz utangaç, köylü ağzı hafif. Kendini anlatırken resmî, sonlara doğru sesi kısılıyor. Son repliği bir isim fısıldar gibi, sanki dinleyenin kim olduğunu biliyormuş gibi söylemeli.

| Dosya | Replik |
| --- | --- |
| `halil_01.mp3` | Belediyeden... Halil. Mazgalın kapağını kapatmaya gelmiştim. |
| `halil_02.mp3` | Biri ihbar etmiş. Açık kalmış dediler. Kim açmış, söyleyen olmadı. |
| `halil_03.mp3` | Düştüğüm delik kapandı. Arkamdan. Yukarı baktım, tavan vardı. |
| `halil_04.mp3` | Selim'e söyleyin... gelmesin. |

## Kaset 5 · Zeynep (2024)

20'lerinin ortası, uzun süredir içeride, artık panik yok, tuhaf bir sakinlik var. Kısık sesle, kelimeleri tartarak konuşuyor, arada uzun susmalar. Kayıt yapıyor ama kendine not alır gibi.

| Dosya | Replik |
| --- | --- |
| `zeynep_01.mp3` | Gün... sanırım dokuz. Uyuduğum yere işaret koyuyorum. |
| `zeynep_02.mp3` | Uyandığımda işaretler başka duvardaydı. |
| `zeynep_03.mp3` | Pil bulunca sevinmeyin. Hep karanlığın içine bırakılmış oluyor. |
| `zeynep_04.mp3` | Ben artık feneri yakmıyorum. Dinliyorum. Kapatınca daha iyi duyuluyor. |

## Kaset 6 · Selim (14.10.2026)

Oyuncunun kendisi. Açılıştaki Selim'in sesiyle aynı kişi, ama çok yorgun, sesi çatlamış, belki günlerdir konuşmamış. Oyuncu bu kaseti bulunca kendi sesini duyduğunu anlamalı. Bağırma yok. Son replik bir rica gibi.

| Dosya | Replik |
| --- | --- |
| `selim_kaset_01.mp3` | Kaç kere düştüm bilmiyorum. Saat yine sıfırda. |
| `selim_kaset_02.mp3` | Pano çıkışın yanında değil. Çıkış... panonun arkasında. |
| `selim_kaset_03.mp3` | Şifreyi unutmayın. Kameraya bakın. Tarih hiç değişmiyor. |
| `selim_kaset_04.mp3` | Telefon çalınca... açmayın. |

Metni değiştirirseniz `index.html` içindeki `TAPES` ve `INTRO_CALL` listelerini de güncelleyin, altyazılar oradan gelir.
