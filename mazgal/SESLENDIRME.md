# MAZGAL — Seslendirme metni

Her replik ayrı bir mp3 dosyasıdır. Dosyaları `ses/` klasörüne aşağıdaki adlarla koyun. Oyun dosyayı bulursa onu çalar, bulamazsa tarayıcının Türkçe sesine geri döner. Bir kısmını kaydetmek de yeter.

## Genel yön

- Bunlar stüdyo kaydı değil. Hepsi göğse takılı bir bodycam'in mikrofonuna, sessiz bir koridorda konuşulmuş. Bağırma yok, çoğu yarı fısıltı.
- Cümle aralarında nefes, duraksama, yutkunma olsun. Kesik cümleler kesik kalsın.
- Yaratığın adı hiç geçmez. Kimse "canavar" demez, korktukları şeyi anlatamazlar.
- Arka plana müzik veya efekt koymayın. Vızıltıyı, cızırtıyı ve oda yankısını oyun ekliyor (`serve.ps1` ile açınca mikrofon filtresi de devreye girer).

**ElevenLabs için:** Türkçe destekleyen çok dilli bir model, Stability düşük (%30-45, daha duygusal), Style biraz açık. Her repliği ayrı üretip mp3 indirin. Yavaş okutmak için cümle sonlarına "..." eklemek işe yarar.

## Selim (oyuncu karakteri)

Gece bekçisi/güvenlik görevlisi, 30'larında. Giriş anlatımında sakin ve yorgun, sanki olaydan sonra raporunu kaydediyor. "Neredeyim" düşüşten sonra sersemlemiş, boğuk.

| Dosya | Replik |
| --- | --- |
| `selim_giris_01.mp3` | 14 Ekim, 23:52. |
| `selim_giris_02.mp3` | Gece vardiyasının son turu. |
| `selim_giris_03.mp3` | Sokak lambası söndü. Mazgalın altından bir vızıltı geliyordu. |
| `selim_giris_04.mp3` | Eğildim. Izgara yerinden oynadı. |
| `selim_neredeyim.mp3` | ...neredeyim? |

Giriş satırları yazı ekrana gelirken çalar. Her biri 3-4 saniyeyi geçmesin.

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

Metni değiştirirseniz `index.html` içindeki `TAPES` ve `INTRO_LINES` listelerini de güncelleyin, altyazılar oradan gelir.
