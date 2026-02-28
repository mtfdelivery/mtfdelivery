class AddressModel {
  final String id;
  final String label; // Home, Work, Other, or custom
  final String street;
  final String city;
  final String zipCode;
  final String? landmark; // apt_floor
  final String name; // Contact name at address
  final String phone; // Contact phone
  final double latitude;
  final double longitude;
  final String plusCode; // e.g. VVFG+7M5
  final String streetNumber;
  final String house; // House/Building name
  final String floor;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.label,
    required this.street,
    this.city = '',
    this.zipCode = '',
    this.landmark,
    this.name = '',
    this.phone = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.plusCode = '',
    this.streetNumber = '',
    this.house = '',
    this.floor = '',
    this.isDefault = false,
  });

  String get fullAddress => '$street, $city, $zipCode';

  factory AddressModel.empty() {
    return const AddressModel(
      id: '',
      label: '',
      street: '',
      city: '',
      zipCode: '',
    );
  }

  AddressModel copyWith({
    String? id,
    String? label,
    String? street,
    String? city,
    String? zipCode,
    String? landmark,
    String? name,
    String? phone,
    double? latitude,
    double? longitude,
    String? plusCode,
    String? streetNumber,
    String? house,
    String? floor,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      street: street ?? this.street,
      city: city ?? this.city,
      zipCode: zipCode ?? this.zipCode,
      landmark: landmark ?? this.landmark,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      plusCode: plusCode ?? this.plusCode,
      streetNumber: streetNumber ?? this.streetNumber,
      house: house ?? this.house,
      floor: floor ?? this.floor,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      street:
          json['full_address'] as String? ?? json['street'] as String? ?? '',
      city: json['city'] as String? ?? '',
      zipCode:
          json['postal_code'] as String? ?? json['zip_code'] as String? ?? '',
      landmark: json['apt_floor'] as String? ?? json['landmark'] as String?,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      plusCode: json['plus_code'] as String? ?? '',
      streetNumber: json['street_number'] as String? ?? '',
      house: json['house'] as String? ?? '',
      floor: json['floor'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'full_address': street,
      'city': city,
      'postal_code': zipCode,
      'apt_floor': landmark,
      'name': name,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'plus_code': plusCode,
      'street_number': streetNumber,
      'house': house,
      'floor': floor,
      'is_default': isDefault,
    };
  }
}
