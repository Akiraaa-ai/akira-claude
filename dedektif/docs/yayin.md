# Google Play yayın adımları

## 1. Kimlikleri değiştir
| Ne | Nerede |
|---|---|
| Paket adı (`com.akira.dedektif`) | `android/app/build.gradle.kts` → `applicationId` (ve istersen `namespace`) |
| AdMob uygulama kimliği | `android/app/src/main/AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID` |
| Ödüllü reklam birimi | `lib/services/monetization_config.dart` → `rewardedAdUnitId` |
| Vaka paketi ürünleri | Play Console → Para kazanma → Uygulama içi ürünler: **tek seferlik** ürün oluştur, kimliği vaka JSON'undaki `access.packId` ile aynı olsun (ör. `vaka_paketi_1`) |

Geliştirirken test kimliklerinde kal; gerçek reklamlara kendi cihazından tıklamak AdMob hesabını riske atar.

## 2. Yükleme anahtarı oluştur (bir kez)
```bash
keytool -genkey -v -keystore ~/dedektif-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
`android/key.properties` dosyasını oluştur (git'e girmez):
```properties
storePassword=<şifre>
keyPassword=<şifre>
keyAlias=upload
storeFile=C:/Users/<sen>/dedektif-upload.jks
```
Bu dosya yoksa release derlemesi debug anahtarıyla imzalanır; Play bunu kabul etmez.

## 3. Sürümü artır
`pubspec.yaml` → `version: 1.0.0+1`. Her yüklemede `+` sonrasındaki sayı (versionCode) artmalı.

## 4. AAB üret
```bash
flutter clean
flutter pub get
flutter test
flutter build appbundle --release
```
Çıktı: `build/app/outputs/bundle/release/app-release.aab`.

## 5. Play Console
1. Uygulama oluştur → Dahili test kanalına `app-release.aab` yükle.
2. Mağaza girişi: ekran görüntüleri, simge (512×512), öne çıkan görsel (1024×500), Türkçe açıklama.
3. İçerik derecelendirmesi anketi, hedef kitle, **Reklam içerir: Evet**, veri güvenliği formu (AdMob reklam kimliği toplar).
4. Gizlilik politikası URL'si (reklam ve satın alma olduğu için zorunlu).
5. Satın almayı test etmek için: Play Console → Lisans testi'ne kendi Google hesabını ekle, uygulamayı dahili test kanalından indir.

## 6. Yayından önce
- Satın alma doğrulaması şu an cihazda yapılıyor (`StorePurchaseService`). Gelir önemliyse makbuzu sunucuda Google Play Developer API ile doğrula.
- AdMob'da uygulamayı Play Store kaydına bağla, GDPR/UMP onay formunu ayarla (AB kullanıcıları için gerekli).
