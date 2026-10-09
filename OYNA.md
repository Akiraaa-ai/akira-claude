# NextGent — Oyuncu Rehberi

> Tarayıcıda çalışan futbol kariyeri simülasyonu. Kurulum, sunucu veya internet bağlantısı gerektirmez.

---

## İçindekiler

1. [Hızlı Başlangıç](#hızlı-başlangıç)
2. [Sistem Gereksinimleri](#sistem-gereksinimleri)
3. [İlk Açılış](#ilk-açılış)
4. [Kayıt Sistemi](#kayıt-sistemi)
5. [Arayüz ve Ekran Düzeni](#arayüz-ve-ekran-düzeni)
6. [Temalar](#temalar)
7. [Ses](#ses)
8. [Sık Sorulan Sorular ve Sorun Giderme](#sık-sorulan-sorular-ve-sorun-giderme)
9. [Geliştiriciler İçin: Oyun Dosyasını Yeniden Oluşturma](#geliştiriciler-için-oyun-dosyasını-yeniden-oluşturma)

---

## Hızlı Başlangıç

**`NextGent.html` dosyasını çift tıklayarak açın.** Oyun doğrudan tarayıcınızda başlar.

NextGent tek bir dosyadan oluşur. React kütüphanesi ve yazı tipleri dosyanın içine gömülüdür; bu nedenle ek bir kurulum, yerel sunucu veya internet bağlantısı gerekmez.

---

## Sistem Gereksinimleri

| Gereksinim       | Ayrıntı                                              |
| ---------------- | ---------------------------------------------------- |
| İşletim sistemi  | Windows, macOS veya Linux                            |
| Tarayıcı         | Güncel bir Chrome, Edge veya Firefox sürümü          |
| İnternet         | Gerekmez                                             |
| Kurulum          | Gerekmez                                             |

Oyun tüm platformlarda aynı şekilde çalışır.

---

## İlk Açılış

1. **Açılış filmi** otomatik olarak başlar. Beklemek istemiyorsanız sağ alt köşedeki **Atla ›** düğmesini kullanın. Filmi bir kez atladığınızda sonraki açılışlarda tekrar gösterilmez.
2. Ardından iki başlangıç seçeneğiniz vardır:

   | Seçenek            | Açıklama                                                                                                                       |
   | ------------------ | ------------------------------------------------------------------------------------------------------------------------------ |
   | **⚡ HEMEN OYNA**   | Rastgele oluşturulan genç bir oyuncuyla, Süper Lig'de orta ölçekli bir kulüpte kariyerinize anında başlarsınız (yaklaşık 4 saniye). |
   | **Başla** (slot)   | Oyuncunuzu kendiniz oluşturursunuz: isim, mevki, avatar, zorluk seviyesi, lig ve kulüp seçimlerini adım adım yaparsınız.         |

---

## Kayıt Sistemi

- Oyunda **3 kayıt slotu** bulunur.
- İlerlemeniz **otomatik olarak kaydedilir**; ayrı bir "Kaydet" düğmesi yoktur.
- Oyunu kapatıp yeniden açtığınızda kaldığınız yerden devam edersiniz.
- Kayıtlar tarayıcının yerel depolama alanında (`localStorage`) tutulur.

> **⚠️ Önemli:** Kayıtlar, oyunu açtığınız tarayıcıya ve dosyanın konumuna bağlıdır.
>
> - Bir tarayıcıda başlattığınız kariyer başka bir tarayıcıda görünmez (ör. Chrome'daki kayıt Firefox'ta yer almaz).
> - `NextGent.html` dosyasını başka bir klasöre taşırsanız dosyanın `file://` adresi değişir ve tarayıcı farklı bir depolama alanı kullanır. Bu durumda mevcut kayıtlarınız görünmeyebilir.
>
> **Öneri:** Kariyerinizi korumak için dosyayı sabit bir klasörde tutun ve oyunu her zaman aynı tarayıcıyla açın.

---

## Arayüz ve Ekran Düzeni

NextGent, ekran boyutuna göre arayüzünü otomatik olarak uyarlar.

| Cihaz                        | Düzen                                                                          |
| ---------------------------- | ------------------------------------------------------------------------------ |
| **Geniş ekran** (bilgisayar) | Yatay arayüz: stadyum arka planı, üstte bilgi paneli (HUD), altta aksiyon çubuğu |
| **Telefon**                  | Dikey arayüz ve alt navigasyon çubuğu                                           |

Bilgisayarda tarayıcı penceresini büyütüp küçülterek iki düzen arasında geçiş yapabilirsiniz.

---

## Temalar

Sağ üst köşedeki **dişli simgesinden** üç tema arasında seçim yapabilirsiniz:

| Tema              | Not        |
| ----------------- | ---------- |
| **Profesyonel**   | Varsayılan |
| **Şampiyonlar**   |            |
| **Arcade**        |            |

---

## Ses

Oyun sesleri harici ses dosyası kullanılmadan, tarayıcının **Web Audio** özelliğiyle gerçek zamanlı olarak üretilir. Sesi **Ayarlar** menüsünden kapatabilirsiniz.

---

## Sık Sorulan Sorular ve Sorun Giderme

**Dosyaya çift tıkladım ama oyun açılmadı.**
Dosyaya sağ tıklayın → **Birlikte aç** → Chrome, Edge veya Firefox'u seçin.

**Kayıtlarım kayboldu.**
Kayıtlar silinmemiş olabilir. Şunları kontrol edin:
- Oyunu daha önce kullandığınız tarayıcıyla mı açtınız?
- `NextGent.html` dosyası hâlâ ilk açtığınız klasörde mi? Değilse dosyayı eski konumuna geri taşıyın.

**İlerlememi nasıl kaydederim?**
Herhangi bir işlem yapmanız gerekmez; oyun otomatik olarak kaydeder.

**Açılış filmini tekrar izleyebilir miyim?**
Film bir kez atlandıktan sonra açılışta gösterilmez.

**Oyunu oynamak için internet gerekli mi?**
Hayır. Tüm içerik dosyanın içinde yer alır.

---

## Geliştiriciler İçin: Oyun Dosyasını Yeniden Oluşturma

Oyun kodunda değişiklik yaptıysanız, tek dosyalık sürümü yeniden oluşturmak için proje kök dizininde şu komutu çalıştırın:

```bash
python3 tools/build_html.py
```

Betik, `game/` klasöründeki en güncel `FootballCareerSimulator_v*.jsx` dosyasını alır ve `game/NextGent.html` olarak paketler.

**Gereksinim:** Python 3
