import 'package:adhan/adhan.dart';

/// Kementerian Agama Republik Indonesia (Kemenag RI)
/// Referensi: SK DJ.II/369 Tahun 2013
///   Fajr:  20.0°
///   Isha:  18.0°
///   Madhab: Syafi'i
class KemenagMethod {
  KemenagMethod._();

  static CalculationParameters getParameters() {
    // adhan v2: use CalculationMethod.other as base
    final params = CalculationMethod.other.getParameters();
    params.fajrAngle  = 20.0;
    params.ishaAngle  = 18.0;
    params.madhab     = Madhab.shafi;
    // Note: 'rounding' was removed in adhan v2, no longer needed
    return params;
  }
}

enum AppCalculationMethod {
  kemenag,
  muslimWorldLeague,
  isna,
  egyptian,
  ummAlQura,
  karachi,
  kuwait,
  qatar,
  singapore,
  turkey,
}

extension AppCalculationMethodExt on AppCalculationMethod {
  CalculationParameters getParameters() {
    switch (this) {
      case AppCalculationMethod.kemenag:
        return KemenagMethod.getParameters();
      case AppCalculationMethod.muslimWorldLeague:
        return CalculationMethod.muslim_world_league.getParameters();
      case AppCalculationMethod.isna:
        return CalculationMethod.north_america.getParameters();
      case AppCalculationMethod.egyptian:
        return CalculationMethod.egyptian.getParameters();
      case AppCalculationMethod.ummAlQura:
        return CalculationMethod.umm_al_qura.getParameters();
      case AppCalculationMethod.karachi:
        return CalculationMethod.karachi.getParameters();
      case AppCalculationMethod.kuwait:
        return CalculationMethod.kuwait.getParameters();
      case AppCalculationMethod.qatar:
        return CalculationMethod.qatar.getParameters();
      case AppCalculationMethod.singapore:
        return CalculationMethod.singapore.getParameters();
      case AppCalculationMethod.turkey:
        return CalculationMethod.turkey.getParameters();
    }
  }
}