class AddressModel {
  final String id;
  final String label; // Home, Work, Other, or custom
  final String address;
  final String name; // Contact name at address
  final String phone; // Contact phone
  final double? latitude;
  final double? longitude;
  final String plusCode; // e.g. VVFG+7M5
  final String streetNumber;
  final String house; // House/Building name
  final String floor;

  const AddressModel({
    required this.id,
    required this.label,
    required this.address,
    this.name = '',
    this.phone = '',
    this.latitude,
    this.longitude,
    this.plusCode = '',
    this.streetNumber = '',
    this.house = '',
    this.floor = '',
  });

  factory AddressModel.empty() {
    return const AddressModel(id: '', label: '', address: '');
  }

  AddressModel copyWith({
    String? id,
    String? label,
    String? address,
    String? name,
    String? phone,
    double? latitude,
    double? longitude,
    String? plusCode,
    String? streetNumber,
    String? house,
    String? floor,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      plusCode: plusCode ?? this.plusCode,
      streetNumber: streetNumber ?? this.streetNumber,
      house: house ?? this.house,
      floor: floor ?? this.floor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'address': address,
      'name': name,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'plus_code': plusCode,
      'street_number': streetNumber,
      'house': house,
      'floor': floor,
    };
  }
}
