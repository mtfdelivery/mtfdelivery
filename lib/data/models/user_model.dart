/// User model for the food delivery app
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final List<AddressModel> addresses;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.addresses = const [],
    required this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    List<AddressModel>? addresses,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      addresses: addresses ?? this.addresses,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Address model for delivery locations
class AddressModel {
  final String id;
  final String label; // Home, Work, etc.
  final String street;
  final String city;
  final String zipCode;
  final String? landmark;
  final double latitude;
  final double longitude;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.label,
    required this.street,
    required this.city,
    required this.zipCode,
    this.landmark,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
  });

  String get fullAddress => '$street, $city, $zipCode';
}
