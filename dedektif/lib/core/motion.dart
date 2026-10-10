import 'package:flutter/widgets.dart';

/// Sürekli dönen animasyonların (yağmur, Ken Burns, daktilo) açık olup olmadığı.
/// Testlerde ve sistemde "animasyonları kapat" seçiliyken kapalıdır.
class Motion {
  static bool enabled = true;

  static bool of(BuildContext context) =>
      enabled && !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
}
