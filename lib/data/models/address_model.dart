class AddressModel {
  final String id;
  final String label; // Home, Work, Parents, etc.
  final String address;
  final String name; // Contact name at address
  final String phone; // Contact phone

  const AddressModel({
    required this.id,
    required this.label,
    required this.address,
    this.name = '',
    this.phone = '',
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
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      name: name ?? this.name,
      phone: phone ?? this.phone,
    );
  }
}
