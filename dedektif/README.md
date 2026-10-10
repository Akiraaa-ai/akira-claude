# Dedektif

Türkçe dedektif bulmaca oyunu (Flutter, Android). Oyuncu sahnede ipucu toplar, şüphelileri sorgular, ifadelere ipucu sunarak çelişki yakalar ve suçluyu gerekçesiyle seçer.

- Plan: [docs/plan.md](docs/plan.md)
- Vaka JSON şeması: [docs/vaka_semasi.md](docs/vaka_semasi.md)
- Gerekli görseller ve sesler: [docs/gorsel_listesi.md](docs/gorsel_listesi.md)
- Play Store yayını: [docs/yayin.md](docs/yayin.md)

## Çalıştırma

Gerekenler: [Flutter](https://docs.flutter.dev/get-started/install/windows/mobile) (3.47 veya üstü, `flutter upgrade` ile güncellenir), Android Studio (Android SDK + emülatör).

```bash
cd dedektif
flutter pub get
flutter doctor          # eksik bir şey varsa burada görünür
flutter emulators --launch <emülatör_adı>   # ya da USB ile telefon bağla (geliştirici modu + USB hata ayıklama)
flutter run
```

Emülatör önerisi: Android Studio → Device Manager → **Pixel 7, API 35 (Google Play'li sistem görüntüsü)**. Reklam ve satın alma için Google Play'li görüntü gerekir.

Test ve kontrol:
```bash
flutter analyze
flutter test            # baştan sona oynanış testleri dahil
```

## Yeni vaka eklemek
1. `assets/cases/<vaka_id>.json` oluştur (şema: `docs/vaka_semasi.md`).
2. Görselleri `assets/images/`, sesleri `assets/audio/` altına koy.
3. `dart run tool/gorsel_listesi.dart` ile görsel listesini güncelle, `flutter test` ile vakayı doğrula.

Kod değişikliği gerekmez. Görsel yoksa isimli renkli yer tutucu çizilir; yer tutucu sahnelerde dokunma alanları görünür olur ki oyun oynanabilsin.

## Klasörler
```
lib/models      JSON → Dart veri sınıfları
lib/services    vaka okuma, kayıt, ayarlar, ses, satın alma, reklam, paylaşım
lib/features    ekranlar + controller'lar (iş mantığı features/game/game_controller.dart)
lib/widgets     ortak bileşenler, kodla animasyonlar (effects/)
tool/           yardımcı betikler
test/           birim ve oynanış testleri
```
