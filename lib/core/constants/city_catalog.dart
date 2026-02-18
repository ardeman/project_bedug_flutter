class CityOption {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  const CityOption({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

const supportedCities = <CityOption>[
  CityOption(
    id: 'jakarta',
    name: 'DKI Jakarta',
    latitude: -6.2088,
    longitude: 106.8456,
  ),
  CityOption(
    id: 'bandung',
    name: 'Bandung',
    latitude: -6.9175,
    longitude: 107.6191,
  ),
  CityOption(
    id: 'semarang',
    name: 'Semarang',
    latitude: -6.9667,
    longitude: 110.4167,
  ),
  CityOption(
    id: 'yogyakarta',
    name: 'Yogyakarta',
    latitude: -7.7956,
    longitude: 110.3695,
  ),
  CityOption(
    id: 'surabaya',
    name: 'Surabaya',
    latitude: -7.2575,
    longitude: 112.7521,
  ),
  CityOption(
    id: 'denpasar',
    name: 'Denpasar',
    latitude: -8.6500,
    longitude: 115.2167,
  ),
  CityOption(
    id: 'medan',
    name: 'Medan',
    latitude: 3.5952,
    longitude: 98.6722,
  ),
  CityOption(
    id: 'makassar',
    name: 'Makassar',
    latitude: -5.1477,
    longitude: 119.4327,
  ),
  CityOption(
    id: 'balikpapan',
    name: 'Balikpapan',
    latitude: -1.2379,
    longitude: 116.8529,
  ),
  CityOption(
    id: 'jayapura',
    name: 'Jayapura',
    latitude: -2.5337,
    longitude: 140.7181,
  ),
];
