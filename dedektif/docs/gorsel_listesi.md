# Görsel ve ses listesi

> Bu dosya `dart run tool/gorsel_listesi.dart` ile vaka JSON'larından üretilir. Elle düzenleme.

Görselleri `assets/images/` altına, tabloda yazan **ad** ile koy. Uzantı `.png`, `.jpg` ya da `.webp` olabilir (ör. `assets/images/menu_arkaplan.jpg`). Dosya bulunursa yer tutucu yerine otomatik kullanılır, kod değişmez.

Sahne görsellerinde ipucu dokunma alanları görselin oranına göre (0–1) tanımlıdır; bu yüzden sahneler **tam 9:16** olmalı.

| Ad | Tür | Boyut | Nerede |
|---|---|---|---|
| `menu_arkaplan` | Arka plan (dikey) | 1080×1920 px (9:16) | Ana menü |
| `vaka_01_kapak` | Kapak | 1280×720 px (16:9) | vaka_01: vaka seçimi kartı |
| `vaka_01_giris` | Arka plan (dikey) | 1080×1920 px (9:16) | vaka_01: giriş sahnesi |
| `vaka_01_sahne_calisma_odasi` | Sahne (dikey) | 1080×1920 px (9:16) | vaka_01: sahne "Çalışma odası" |
| `vaka_01_sahne_mutfak` | Sahne (dikey) | 1080×1920 px (9:16) | vaka_01: sahne "Mutfak" |
| `vaka_01_sahne_guvenlik` | Sahne (dikey) | 1080×1920 px (9:16) | vaka_01: sahne "Güvenlik kayıtları" |
| `vaka_01_portre_selma` | Portre | 600×800 px (3:4) | vaka_01: Selma Aksoy (eş, 58) |
| `vaka_01_portre_kerem` | Portre | 600×800 px (3:4) | vaka_01: Kerem Aksoy (yeğen, 31) |
| `vaka_01_portre_aylin` | Portre | 600×800 px (3:4) | vaka_01: Dr. Aylin Demirtaş (aile doktoru, 45) |
| `vaka_01_portre_hasan` | Portre | 600×800 px (3:4) | vaka_01: Hasan Usta (kâhya, 60) |
| `vaka_01_final` | Arka plan (dikey) | 1080×1920 px (9:16) | vaka_01: final sahnesi |

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
| `vaka_01_muzik` | vaka_01: soruşturma müziği (döngü) |
| `vaka_01_gerilim` | vaka_01: suçlama gerilim müziği (döngü) |
| `vaka_01_final` | vaka_01: final müziği |
