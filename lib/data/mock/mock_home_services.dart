import '../models/home_service_model.dart';

/// Mock data for home services
class MockHomeServices {
  MockHomeServices._();

  static const List<HomeServiceModel> services = [
    HomeServiceModel(
      id: 'courier',
      name: 'Coursier',
      iconUrl: 'https://cdn-icons-png.flaticon.com/512/2830/2830305.png',
      route: '/home/courier',
      isAvailable: true,
      size: ServiceCardSize.large,
    ),
    HomeServiceModel(
      id: 'restaurants',
      name: 'Restaurants',
      iconUrl: 'https://cdn-icons-png.flaticon.com/512/1046/1046784.png',
      route: '/home/restaurants',
      isAvailable: true,
      size: ServiceCardSize.large,
    ),
    HomeServiceModel(
      id: 'groceries',
      name: 'Courses',
      iconUrl: 'https://cdn-icons-png.flaticon.com/512/3724/3724788.png',
      route: '/home/groceries',
      isAvailable: false,
      size: ServiceCardSize.small,
    ),
    HomeServiceModel(
      id: 'boutiques',
      name: 'Boutiques',
      iconUrl: 'https://cdn-icons-png.flaticon.com/512/3225/3225194.png',
      route: '/home/boutiques',
      isAvailable: false,
      size: ServiceCardSize.small,
    ),
    HomeServiceModel(
      id: 'pharmacies',
      name: 'Pharmacies',
      iconUrl: 'https://cdn-icons-png.flaticon.com/512/2382/2382533.png',
      route: '/home/pharmacies',
      isAvailable: false,
      size: ServiceCardSize.small,
    ),
  ];
}
