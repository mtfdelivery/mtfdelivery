class HomeService {
  final String id;
  final String label;
  final String localAssetPath;
  final String? route;
  final bool isLarge;
  final bool isAvailable;
  final String? iconUrl;

  const HomeService({
    required this.id,
    required this.label,
    required this.localAssetPath,
    this.route,
    this.isLarge = false,
    this.isAvailable = true,
    this.iconUrl,
  });

  factory HomeService.fromJson(Map<String, dynamic> json) {
    return HomeService(
      id: json['id'] as String,
      label: json['label'] as String,
      localAssetPath: json['local_asset_path'] ?? 'assets/services/courier.png',
      route: json['route'] as String?,
      isLarge: json['is_large'] ?? false,
      isAvailable: json['is_available'] ?? true,
      iconUrl: json['icon_url'] as String?,
    );
  }
}
