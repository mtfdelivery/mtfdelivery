/// Model for home services displayed on the primary home screen
class HomeServiceModel {
  final String id;
  final String name;
  final String iconUrl;
  final String route;
  final bool isAvailable;
  final ServiceCardSize size;

  const HomeServiceModel({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.route,
    this.isAvailable = true,
    this.size = ServiceCardSize.small,
  });
}

enum ServiceCardSize { large, small }
