import '../models/user_model.dart';

/// Mock user and address data
class MockUsers {
  MockUsers._();

  static final UserModel currentUser = UserModel(
    id: 'u1',
    name: 'John Doe',
    email: 'john.doe@email.com',
    phone: '+1 234 567 8900',
    avatarUrl:
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200',
    addresses: addresses,
    createdAt: DateTime.now().subtract(const Duration(days: 365)),
  );

  static final List<AddressModel> addresses = [
    AddressModel(
      id: 'a1',
      label: 'Home',
      street: '123 Main Street, Apt 4B',
      city: 'New York',
      zipCode: '10001',
      landmark: 'Near Central Park',
      latitude: 40.7589,
      longitude: -73.9851,
      isDefault: true,
    ),
    AddressModel(
      id: 'a2',
      label: 'Work',
      street: '456 Business Ave, Floor 12',
      city: 'New York',
      zipCode: '10016',
      landmark: 'Empire State Building nearby',
      latitude: 40.7484,
      longitude: -73.9857,
      isDefault: false,
    ),
    AddressModel(
      id: 'a3',
      label: 'Gym',
      street: '789 Fitness Blvd',
      city: 'New York',
      zipCode: '10025',
      latitude: 40.8003,
      longitude: -73.9654,
      isDefault: false,
    ),
  ];
}
