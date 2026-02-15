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
import '../../data/models/user_model.dart';
import '../../widgets/widgets.dart';

/// Checkout screen
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _selectedPaymentMethod = 'card';
  bool _isLoading = false;

  void _placeOrder() {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ref.read(cartProvider.notifier).clearCart();
        context.go(Routes.orderTracking('order_123'));
      }
    });
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.checkout), centerTitle: true),
      body: SingleChildScrollView(
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
                                const SizedBox(width: AppDimensions.spacingMd),
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
                    '•••• 4242',
                  ),
                  _buildPaymentOption(
                    'cash',
                    'Cash on Delivery',
                    Iconsax.money,
                    null,
                  ),
                  _buildPaymentOption(
                    'paypal',
                    'PayPal',
                    Iconsax.wallet,
                    'john@email.com',
                  ),
                ],
              ),
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
                            style: const TextStyle(fontWeight: FontWeight.w500),
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
    String? subtitle,
  ) {
    final isSelected = _selectedPaymentMethod == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      child: GestureDetector(
        onTap: () => setState(() => _selectedPaymentMethod = value),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMd),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
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
              MtfRadio<String>(value: value),
            ],
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
