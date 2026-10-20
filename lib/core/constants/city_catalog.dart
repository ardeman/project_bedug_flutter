/// Countries the city catalog covers. Their display names are localized in
/// `countryLabel` (`lib/core/widgets/city_picker.dart`).
enum CityCountry {
  indonesia,
  malaysia,
  singapore,
  brunei,
  thailand,
  philippines,
  saudiArabia,
  unitedArabEmirates,
  qatar,
  kuwait,
  bahrain,
  oman,
  jordan,
  palestine,
  egypt,
  morocco,
  turkey,
  pakistan,
  india,
  bangladesh,
  unitedKingdom,
  france,
  germany,
  netherlands,
  unitedStates,
  canada,
  australia,
  japan,
  southKorea,
  nigeria,
  southAfrica,
}

class CityOption {
  final String id;
  final String name;
  final CityCountry country;
  final double latitude;
  final double longitude;

  const CityOption(
    this.id,
    this.name,
    this.country,
    this.latitude,
    this.longitude,
  );
}

/// The city used when auto detect is off and none has been picked: the
/// best-known city for each app language.
const _defaultCityIds = {
  'id': 'jakarta',
  'ms': 'kuala_lumpur',
  'ar': 'makkah',
  'en': 'silicon_valley',
};

CityOption defaultCityFor(String languageCode) =>
    cityById(_defaultCityIds[languageCode] ?? _defaultCityIds['id'])!;

CityOption? cityById(String? id) {
  if (id == null || id.isEmpty) return null;
  return supportedCities.where((c) => c.id == id).firstOrNull;
}

/// Grouped by country, in the order the picker lists them.
const supportedCities = <CityOption>[
  // Indonesia: every provincial capital plus the largest cities.
  CityOption(
      'banda_aceh', 'Banda Aceh', CityCountry.indonesia, 5.5483, 95.3238),
  CityOption('medan', 'Medan', CityCountry.indonesia, 3.5952, 98.6722),
  CityOption('padang', 'Padang', CityCountry.indonesia, -0.9471, 100.4172),
  CityOption('pekanbaru', 'Pekanbaru', CityCountry.indonesia, 0.5071, 101.4478),
  CityOption('batam', 'Batam', CityCountry.indonesia, 1.0456, 104.0305),
  CityOption('tanjung_pinang', 'Tanjung Pinang', CityCountry.indonesia, 0.9186,
      104.4554),
  CityOption('jambi', 'Jambi', CityCountry.indonesia, -1.6101, 103.6131),
  CityOption(
      'palembang', 'Palembang', CityCountry.indonesia, -2.9761, 104.7754),
  CityOption('pangkal_pinang', 'Pangkal Pinang', CityCountry.indonesia, -2.1291,
      106.1090),
  CityOption('bengkulu', 'Bengkulu', CityCountry.indonesia, -3.7928, 102.2608),
  CityOption('bandar_lampung', 'Bandar Lampung', CityCountry.indonesia, -5.4292,
      105.2610),
  CityOption('jakarta', 'Jakarta', CityCountry.indonesia, -6.2088, 106.8456),
  CityOption('bogor', 'Bogor', CityCountry.indonesia, -6.5971, 106.8060),
  CityOption('depok', 'Depok', CityCountry.indonesia, -6.4025, 106.7942),
  CityOption(
      'tangerang', 'Tangerang', CityCountry.indonesia, -6.1783, 106.6319),
  CityOption('bekasi', 'Bekasi', CityCountry.indonesia, -6.2383, 106.9756),
  CityOption('serang', 'Serang', CityCountry.indonesia, -6.1200, 106.1503),
  CityOption('bandung', 'Bandung', CityCountry.indonesia, -6.9175, 107.6191),
  CityOption('cirebon', 'Cirebon', CityCountry.indonesia, -6.7320, 108.5523),
  CityOption('semarang', 'Semarang', CityCountry.indonesia, -6.9667, 110.4167),
  CityOption(
      'surakarta', 'Surakarta', CityCountry.indonesia, -7.5755, 110.8243),
  CityOption(
      'yogyakarta', 'Yogyakarta', CityCountry.indonesia, -7.7956, 110.3695),
  CityOption('surabaya', 'Surabaya', CityCountry.indonesia, -7.2575, 112.7521),
  CityOption('malang', 'Malang', CityCountry.indonesia, -7.9666, 112.6326),
  CityOption('denpasar', 'Denpasar', CityCountry.indonesia, -8.6500, 115.2167),
  CityOption('mataram', 'Mataram', CityCountry.indonesia, -8.5833, 116.1167),
  CityOption('kupang', 'Kupang', CityCountry.indonesia, -10.1772, 123.6070),
  CityOption(
      'pontianak', 'Pontianak', CityCountry.indonesia, -0.0263, 109.3425),
  CityOption('palangka_raya', 'Palangka Raya', CityCountry.indonesia, -2.2161,
      113.9135),
  CityOption(
      'banjarmasin', 'Banjarmasin', CityCountry.indonesia, -3.3194, 114.5908),
  CityOption(
      'samarinda', 'Samarinda', CityCountry.indonesia, -0.5022, 117.1536),
  CityOption(
      'balikpapan', 'Balikpapan', CityCountry.indonesia, -1.2379, 116.8529),
  CityOption('tanjung_selor', 'Tanjung Selor', CityCountry.indonesia, 2.8375,
      117.3653),
  CityOption('manado', 'Manado', CityCountry.indonesia, 1.4748, 124.8421),
  CityOption('gorontalo', 'Gorontalo', CityCountry.indonesia, 0.5435, 123.0568),
  CityOption('palu', 'Palu', CityCountry.indonesia, -0.8917, 119.8707),
  CityOption('mamuju', 'Mamuju', CityCountry.indonesia, -2.6748, 118.8885),
  CityOption('makassar', 'Makassar', CityCountry.indonesia, -5.1477, 119.4327),
  CityOption('kendari', 'Kendari', CityCountry.indonesia, -3.9985, 122.5129),
  CityOption('ambon', 'Ambon', CityCountry.indonesia, -3.6954, 128.1814),
  CityOption('ternate', 'Ternate', CityCountry.indonesia, 0.7893, 127.3842),
  CityOption('sorong', 'Sorong', CityCountry.indonesia, -0.8762, 131.2558),
  CityOption(
      'manokwari', 'Manokwari', CityCountry.indonesia, -0.8615, 134.0620),
  CityOption('jayapura', 'Jayapura', CityCountry.indonesia, -2.5337, 140.7181),
  CityOption('merauke', 'Merauke', CityCountry.indonesia, -8.4932, 140.4018),

  // Malaysia: the capitals and every state capital.
  CityOption(
      'kuala_lumpur', 'Kuala Lumpur', CityCountry.malaysia, 3.1390, 101.6869),
  CityOption('putrajaya', 'Putrajaya', CityCountry.malaysia, 2.9264, 101.6964),
  CityOption('shah_alam', 'Shah Alam', CityCountry.malaysia, 3.0733, 101.5185),
  CityOption(
      'george_town', 'George Town', CityCountry.malaysia, 5.4141, 100.3288),
  CityOption('ipoh', 'Ipoh', CityCountry.malaysia, 4.5975, 101.0901),
  CityOption(
      'johor_bahru', 'Johor Bahru', CityCountry.malaysia, 1.4927, 103.7414),
  CityOption('melaka', 'Melaka', CityCountry.malaysia, 2.1896, 102.2501),
  CityOption('seremban', 'Seremban', CityCountry.malaysia, 2.7297, 101.9381),
  CityOption('kuantan', 'Kuantan', CityCountry.malaysia, 3.8077, 103.3260),
  CityOption('kuala_terengganu', 'Kuala Terengganu', CityCountry.malaysia,
      5.3302, 103.1408),
  CityOption(
      'kota_bharu', 'Kota Bharu', CityCountry.malaysia, 6.1254, 102.2381),
  CityOption(
      'alor_setar', 'Alor Setar', CityCountry.malaysia, 6.1248, 100.3678),
  CityOption('kangar', 'Kangar', CityCountry.malaysia, 6.4414, 100.1986),
  CityOption(
      'kota_kinabalu', 'Kota Kinabalu', CityCountry.malaysia, 5.9804, 116.0735),
  CityOption('kuching', 'Kuching', CityCountry.malaysia, 1.5533, 110.3592),

  CityOption('singapore', 'Singapore', CityCountry.singapore, 1.3521, 103.8198),
  CityOption('bandar_seri_begawan', 'Bandar Seri Begawan', CityCountry.brunei,
      4.9031, 114.9398),
  CityOption('bangkok', 'Bangkok', CityCountry.thailand, 13.7563, 100.5018),
  CityOption('pattani', 'Pattani', CityCountry.thailand, 6.8696, 101.2501),
  CityOption('manila', 'Manila', CityCountry.philippines, 14.5995, 120.9842),
  CityOption('cotabato', 'Cotabato', CityCountry.philippines, 7.2236, 124.2464),

  CityOption('makkah', 'Makkah', CityCountry.saudiArabia, 21.4225, 39.8262),
  CityOption('madinah', 'Madinah', CityCountry.saudiArabia, 24.4672, 39.6111),
  CityOption('riyadh', 'Riyadh', CityCountry.saudiArabia, 24.7136, 46.6753),
  CityOption('jeddah', 'Jeddah', CityCountry.saudiArabia, 21.4858, 39.1925),
  CityOption('dammam', 'Dammam', CityCountry.saudiArabia, 26.4207, 50.0888),
  CityOption(
      'dubai', 'Dubai', CityCountry.unitedArabEmirates, 25.2048, 55.2708),
  CityOption('abu_dhabi', 'Abu Dhabi', CityCountry.unitedArabEmirates, 24.4539,
      54.3773),
  CityOption('doha', 'Doha', CityCountry.qatar, 25.2854, 51.5310),
  CityOption(
      'kuwait_city', 'Kuwait City', CityCountry.kuwait, 29.3759, 47.9774),
  CityOption('manama', 'Manama', CityCountry.bahrain, 26.2285, 50.5860),
  CityOption('muscat', 'Muscat', CityCountry.oman, 23.5880, 58.3829),
  CityOption('amman', 'Amman', CityCountry.jordan, 31.9539, 35.9106),
  CityOption('al_quds', 'Al-Quds', CityCountry.palestine, 31.7780, 35.2354),
  CityOption('gaza', 'Gaza', CityCountry.palestine, 31.5017, 34.4668),
  CityOption('cairo', 'Cairo', CityCountry.egypt, 30.0444, 31.2357),
  CityOption('alexandria', 'Alexandria', CityCountry.egypt, 31.2001, 29.9187),
  CityOption('rabat', 'Rabat', CityCountry.morocco, 34.0209, -6.8416),
  CityOption('casablanca', 'Casablanca', CityCountry.morocco, 33.5731, -7.5898),
  CityOption('istanbul', 'Istanbul', CityCountry.turkey, 41.0082, 28.9784),
  CityOption('ankara', 'Ankara', CityCountry.turkey, 39.9334, 32.8597),

  CityOption('karachi', 'Karachi', CityCountry.pakistan, 24.8607, 67.0011),
  CityOption('lahore', 'Lahore', CityCountry.pakistan, 31.5204, 74.3587),
  CityOption('islamabad', 'Islamabad', CityCountry.pakistan, 33.6844, 73.0479),
  CityOption('delhi', 'Delhi', CityCountry.india, 28.6139, 77.2090),
  CityOption('mumbai', 'Mumbai', CityCountry.india, 19.0760, 72.8777),
  CityOption('hyderabad', 'Hyderabad', CityCountry.india, 17.3850, 78.4867),
  CityOption('dhaka', 'Dhaka', CityCountry.bangladesh, 23.8103, 90.4125),

  CityOption('london', 'London', CityCountry.unitedKingdom, 51.5074, -0.1278),
  CityOption(
      'birmingham', 'Birmingham', CityCountry.unitedKingdom, 52.4862, -1.8904),
  CityOption('paris', 'Paris', CityCountry.france, 48.8566, 2.3522),
  CityOption('berlin', 'Berlin', CityCountry.germany, 52.5200, 13.4050),
  CityOption(
      'amsterdam', 'Amsterdam', CityCountry.netherlands, 52.3676, 4.9041),

  // Silicon Valley stands for its largest city, San Jose.
  CityOption('silicon_valley', 'Silicon Valley', CityCountry.unitedStates,
      37.3382, -121.8863),
  CityOption('san_francisco', 'San Francisco', CityCountry.unitedStates,
      37.7749, -122.4194),
  CityOption('los_angeles', 'Los Angeles', CityCountry.unitedStates, 34.0522,
      -118.2437),
  CityOption(
      'new_york', 'New York', CityCountry.unitedStates, 40.7128, -74.0060),
  CityOption('chicago', 'Chicago', CityCountry.unitedStates, 41.8781, -87.6298),
  CityOption('houston', 'Houston', CityCountry.unitedStates, 29.7604, -95.3698),
  CityOption('washington', 'Washington, D.C.', CityCountry.unitedStates,
      38.9072, -77.0369),
  CityOption('toronto', 'Toronto', CityCountry.canada, 43.6532, -79.3832),
  CityOption('sydney', 'Sydney', CityCountry.australia, -33.8688, 151.2093),
  CityOption(
      'melbourne', 'Melbourne', CityCountry.australia, -37.8136, 144.9631),
  CityOption('tokyo', 'Tokyo', CityCountry.japan, 35.6762, 139.6503),
  CityOption('seoul', 'Seoul', CityCountry.southKorea, 37.5665, 126.9780),
  CityOption('lagos', 'Lagos', CityCountry.nigeria, 6.5244, 3.3792),
  CityOption(
      'cape_town', 'Cape Town', CityCountry.southAfrica, -33.9249, 18.4241),
];
