// Para kazanma ayarları. Şu an Google'ın herkese açık TEST kimlikleri kullanılıyor.
// Yayından önce kendi kimliklerini buraya ve android/app/src/main/AndroidManifest.xml
// içindeki com.google.android.gms.ads.APPLICATION_ID değerine yaz (bkz. docs/yayin.md).

class MonetizationConfig {
  /// Ödüllü reklam birimi (Android). TEST kimliği.
  static const rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  /// AdMob uygulama kimliği (yalnızca bilgi; asıl değer AndroidManifest.xml'de). TEST kimliği.
  static const admobAppId = 'ca-app-pub-3940256099942544~3347511713';

  /// Vaka JSON'undaki "access.packId" değeri doğrudan Play Console'daki
  /// uygulama içi ürün kimliği (tek seferlik, tüketilmeyen) olarak kullanılır.
  /// Örnek: "vaka_paketi_1".
  static String productIdForPack(String packId) => packId;
}
