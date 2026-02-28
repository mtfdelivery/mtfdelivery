import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../navigation/app_router.dart';
import '../../providers/cart_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/restaurant_providers.dart';
import '../../data/models/user_model.dart';
import '../../widgets/widgets.dart';

/// Checkout screen
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _selectedPaymentMethod = 'cash';
  bool _isLoading = false;
  String? _errorMessage;
  late final TextEditingController _instructionsController;

  @override
  void initState() {
    super.initState();
    _instructionsController = TextEditingController();
  }

  /// Called once per frame — safe place for Riverpod listeners
  /// (equivalent to initState for ref.listen).
  bool _listenerRegistered = false;
  void _registerPaymentListener() {
    if (_listenerRegistered) return;
    _listenerRegistered = true;

    final cartItems = ref.read(cartProvider);
    final firstItemRestaurantId =
        cartItems.isNotEmpty ? cartItems.first.foodItem.restaurantId : null;
    if (firstItemRestaurantId == null) return;

    ref.listen(restaurantProvider(firstItemRestaurantId), (prev, next) {
      if (next.hasValue && next.value != null) {
        final res = next.value!;
        if (_selectedPaymentMethod == 'card' && !res.acceptsCard) {
          setState(() => _selectedPaymentMethod = 'cash');
        } else if (_selectedPaymentMethod == 'cash' && !res.acceptsCash) {
          if (res.acceptsCard) {
            setState(() => _selectedPaymentMethod = 'card');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final selectedAddress = ref.read(selectedAddressProvider);
    final cartItems = ref.read(cartProvider);

    // Validate address
    if (selectedAddress == null) {
      setState(() => _errorMessage = 'Please select a delivery address');
      return;
    }

    // Validate cart
    if (cartItems.isEmpty) {
      setState(() => _errorMessage = 'Your cart is empty');
      return;
    }

    // Get restaurant info from first cart item
    final firstItem = cartItems.first;
    final restaurantId = firstItem.foodItem.restaurantId;

    // Fetch real restaurant info
    final restaurantAsync = await ref.read(
      restaurantProvider(restaurantId).future,
    );
    final restaurantName = restaurantAsync?.name ?? 'Restaurant';
    final restaurantImage = restaurantAsync?.imageUrl ?? '';

    // Check if restaurant is open
    if (restaurantAsync != null && !restaurantAsync.isOpen) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This restaurant is currently closed and not accepting orders.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orderId = await ref
          .read(orderProvider.notifier)
          .submitOrder(
            restaurantId: restaurantId,
            restaurantName: restaurantName,
            restaurantImage: restaurantImage,
            deliveryAddress: selectedAddress,
            paymentMethod: _selectedPaymentMethod,
            notes:
                _instructionsController.text.trim().isEmpty
                    ? null
                    : _instructionsController.text.trim(),
          );

      if (orderId != null && mounted) {
        // Reset loading state before navigation
        setState(() => _isLoading = false);
        context.go(Routes.orderTracking(orderId));
      } else if (mounted) {
        final orderState = ref.read(orderProvider);
        setState(() {
          _isLoading = false;
          _errorMessage = orderState.errorMessage ?? 'Failed to place order';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final addresses = ref.watch(userAddressesProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final deliveryFee = ref.watch(deliveryFeeProvider);
    final tax = ref.watch(taxProvider);
    final total = ref.watch(cartTotalProvider);

    // Get restaurant info to check payment support
    final firstItemRestaurantId =
        cartItems.isNotEmpty ? cartItems.first.foodItem.restaurantId : null;
    final restaurantAsync =
        firstItemRestaurantId != null
            ? ref.watch(restaurantProvider(firstItemRestaurantId))
            : null;
    final restaurant = restaurantAsync?.valueOrNull;

    final acceptsCard = restaurant?.acceptsCard ?? true;
    final acceptsCash = restaurant?.acceptsCash ?? true;

    // Register listener once to enforce payment method restrictions
    _registerPaymentListener();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.checkout), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Delivery Address Section
              _buildSectionTitle(AppStrings.deliveryAddress),
              const SizedBox(height: AppDimensions.spacingMd),
              MtfRadioGroup<AddressModel?>(
                groupValue: selectedAddress,
                onChanged: (address) {
                  ref.read(selectedAddressProvider.notifier).state = address;
                },
                child: Column(
                  children:
                      addresses.map((address) {
                        final isSelected = selectedAddress?.id == address.id;
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppDimensions.spacingSm,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              ref.read(selectedAddressProvider.notifier).state =
                                  address;
                            },
                            child: Container(
                              padding: const EdgeInsets.all(
                                AppDimensions.paddingMd,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusMd,
                                ),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    address.label == 'Home'
                                        ? Iconsax.home
                                        : address.label == 'Work'
                                        ? Iconsax.building
                                        : Iconsax.location,
                                    color:
                                        isSelected
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                  ),
                                  const SizedBox(
                                    width: AppDimensions.spacingMd,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              address.label,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (address.isDefault)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  left: 8,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Default',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          address.fullAddress,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  MtfRadio<AddressModel?>(value: address),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
              SecondaryButton(
                text: AppStrings.addNewAddress,
                icon: Iconsax.add,
                onPressed: () => context.push(Routes.addAddress),
                height: 44,
              ),

              const SizedBox(height: AppDimensions.spacingXxl),

              // Payment Method Section
              _buildSectionTitle(AppStrings.paymentMethod),
              const SizedBox(height: AppDimensions.spacingMd),
              MtfRadioGroup<String>(
                groupValue: _selectedPaymentMethod,
                onChanged: (v) {
                  if (v != null) setState(() => _selectedPaymentMethod = v);
                },
                child: Column(
                  children: [
                    _buildPaymentOption(
                      'card',
                      'Credit/Debit Card',
                      Iconsax.card,
                      acceptsCard ? '•••• 4242' : 'Not accepted by restaurant',
                      enabled: acceptsCard,
                    ),
                    _buildPaymentOption(
                      'cash',
                      'Cash on Delivery',
                      Iconsax.money,
                      acceptsCash ? null : 'Not accepted by restaurant',
                      enabled: acceptsCash,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXxl),

              // Order Instructions Section
              _buildSectionTitle(AppStrings.orderInstructions),
              const SizedBox(height: AppDimensions.spacingMd),
              CustomTextField(
                controller: _instructionsController,
                hint: AppStrings.orderInstructionsHint,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),

              const SizedBox(height: AppDimensions.spacingXxl),

              // Order Summary Section
              _buildSectionTitle(AppStrings.orderSummary),
              const SizedBox(height: AppDimensions.spacingMd),
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingMd),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Column(
                  children: [
                    ...cartItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppDimensions.spacingSm,
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${item.quantity}x',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spacingSm),
                            Expanded(
                              child: Text(
                                item.foodItem.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              '\$${item.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: AppDimensions.spacingXxl),
                    _buildPriceRow('Subtotal', subtotal),
                    const SizedBox(height: 4),
                    _buildPriceRow('Delivery', deliveryFee),
                    const SizedBox(height: 4),
                    _buildPriceRow('Tax', tax),
                    const Divider(height: AppDimensions.spacingLg),
                    _buildPriceRow('Total', total, isTotal: true),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXxl),

              // Error message
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(
                    bottom: AppDimensions.spacingMd,
                  ),
                  padding: const EdgeInsets.all(AppDimensions.paddingMd),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: AppDimensions.spacingSm),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),

              // Place Order Button
              PrimaryButton(
                text: 'Place Order - \$${total.toStringAsFixed(2)}',
                isLoading: _isLoading,
                onPressed: _placeOrder,
              ),

              const SizedBox(height: AppDimensions.spacingLg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    IconData icon,
    String? subtitle, {
    bool enabled = true,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      child: GestureDetector(
        onTap:
            enabled
                ? () => setState(() => _selectedPaymentMethod = value)
                : null,
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMd),
          decoration: BoxDecoration(
            color:
                enabled
                    ? AppColors.surface
                    : AppColors.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color:
                  isSelected && enabled ? AppColors.primary : AppColors.border,
              width: isSelected && enabled ? 2 : 1,
            ),
          ),
          child: Opacity(
            opacity: enabled ? 1.0 : 0.5,
            child: Row(
              children: [
                Icon(
                  icon,
                  color:
                      isSelected && enabled
                          ? AppColors.primary
                          : AppColors.textSecondary,
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (enabled) MtfRadio<String>(value: value),
                if (!enabled)
                  const Icon(
                    Icons.block_rounded,
                    size: 16,
                    color: AppColors.error,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
