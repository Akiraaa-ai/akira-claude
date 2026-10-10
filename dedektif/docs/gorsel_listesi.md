# Görsel ve ses listesi

> Bu dosya `dart run tool/gorsel_listesi.dart` ile vaka JSON'larından üretilir. Elle düzenleme.

Görselleri `assets/images/` altına, tabloda yazan **ad** ile koy. Uzantı `.png`, `.jpg` ya da `.webp` olabilir (ör. `assets/images/menu_arkaplan.jpg`). Dosya bulunursa yer tutucu yerine otomatik kullanılır, kod değişmez.

Sahne görsellerinde ipucu dokunma alanları görselin oranına göre (0–1) tanımlıdır; bu yüzden sahneler **tam 9:16** olmalı.

| Ad | Tür | Boyut | Nerede |
|---|---|---|---|
| `menu_arkaplan` | Arka plan (dikey) | 1080×1920 px (9:16) | Ana menü |
| `ornek_vaka_kapak` | Kapak | 1280×720 px (16:9) | ornek_vaka: vaka seçimi kartı |
| `ornek_vaka_giris` | Arka plan (dikey) | 1080×1920 px (9:16) | ornek_vaka: giriş sahnesi |
| `ornek_sahne_dukkan` | Sahne (dikey) | 1080×1920 px (9:16) | ornek_vaka: sahne "Dükkân" |
| `ornek_sahne_depo` | Sahne (dikey) | 1080×1920 px (9:16) | ornek_vaka: sahne "Arka depo" |
| `ornek_portre_sahip` | Portre | 600×800 px (3:4) | ornek_vaka: Nuri Bey (Sahaf sahibi) |
| `ornek_portre_cirak` | Portre | 600×800 px (3:4) | ornek_vaka: Deniz (Çırak) |
| `ornek_portre_musteri` | Portre | 600×800 px (3:4) | ornek_vaka: Selma Hanım (Daimi müşteri) |
| `ornek_portre_komsu` | Portre | 600×800 px (3:4) | ornek_vaka: Kemal (Yan dükkândaki saatçi) |
| `ornek_final` | Arka plan (dikey) | 1080×1920 px (9:16) | ornek_vaka: final sahnesi |

## Sesler

`assets/audio/` altına `.mp3`, `.ogg`, `.m4a` ya da `.wav` olarak koy. Eksik ses hata vermez, sessizce atlanır.

| Ad | Nerede |
|---|---|
| `menu_muzik` | Genel: Ana menü müziği (döngü) |
| `dokunma` | Genel: Düğme dokunma efekti |
| `ipucu_bulundu` | Genel: İpucu bulununca |
| `celiski` | Genel: Çelişki yakalanınca |
| `yanlis` | Genel: Sunulan ipucu çelişmeyince |
| `cozuldu` | Genel: Vaka çözülünce |
| `yanlis_suclama` | Genel: Yanlış suçlamada |
| `ornek_giris_seslendirme` | ornek_vaka: giriş voice (0 ms) |
| `gok_gurultusu` | ornek_vaka: giriş sfx (1500 ms) |
| `ornek_muzik` | ornek_vaka: soruşturma müziği (döngü) |
| `ornek_gerilim` | ornek_vaka: suçlama gerilim müziği (döngü) |
| `ornek_final` | ornek_vaka: final müziği |
