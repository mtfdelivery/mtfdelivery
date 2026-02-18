import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/food_item_model.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../providers/restaurant_providers.dart';
import '../../domain/customization_entity.dart';
import '../controllers/customization_controller.dart';
import 'restaurant_conflict_dialog.dart';

/// Modal bottom sheet for customizing a food item before adding to cart.
class ItemCustomizationSheet extends ConsumerWidget {
  final FoodItemModel item;

  const ItemCustomizationSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addonsAsync = ref.watch(menuItemAddonsProvider(item.id));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
      ),
      child: addonsAsync.when(
        data: (groups) => _ItemCustomizationBody(item: item, groups: groups),
        loading:
            () => SizedBox(
              height: 300.h,
              child: const Center(child: CircularProgressIndicator()),
            ),
        error:
            (err, stack) => SizedBox(
              height: 300.h,
              child: Center(child: Text('Error loading options: $err')),
            ),
      ),
    );
  }
}

class _ItemCustomizationBody extends ConsumerStatefulWidget {
  final FoodItemModel item;
  final List<CustomizationGroup> groups;

  const _ItemCustomizationBody({required this.item, required this.groups});

  @override
  ConsumerState<_ItemCustomizationBody> createState() =>
      __ItemCustomizationBodyState();
}

class __ItemCustomizationBodyState
    extends ConsumerState<_ItemCustomizationBody> {
  late final CustomizationController _controller;

  @override
  void initState() {
    super.initState();
    // Sort groups: required ones first.
    final sortedGroups = List<CustomizationGroup>.from(widget.groups)
      ..sort((a, b) {
        if (a.required && !b.required) return -1;
        if (!a.required && b.required) return 1;
        return 0;
      });

    _controller = CustomizationController(
      basePrice: widget.item.price,
      groups: sortedGroups,
    )..addListener(_onControllerChanged);
  }

  void _onControllerChanged() => setState(() {});

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _addToCart() async {
    final extras = _controller.extrasUnitPrice;
    final names = _controller.selectedCustomizationNames;
    final adjustedItem =
        extras > 0
            ? widget.item.copyWith(price: widget.item.price + extras)
            : widget.item;

    try {
      ref
          .read(cartProvider.notifier)
          .addItem(
            adjustedItem,
            quantity: _controller.quantity,
            instructions: names.isNotEmpty ? names.join(', ') : null,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.item.name} added to cart'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on RestaurantConflictException {
      if (!mounted) return;

      final shouldClear = await showDialog<bool>(
        context: context,
        builder: (context) => const RestaurantConflictDialog(),
      );

      if (shouldClear == true && mounted) {
        final cart = ref.read(cartProvider.notifier);
        cart.clearCart();
        cart.addItem(
          adjustedItem,
          quantity: _controller.quantity,
          instructions: names.isNotEmpty ? names.join(', ') : null,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Panier mis à jour avec ${widget.item.name}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDragHandle(),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 20.h),
                ..._controller.groups.asMap().entries.map((entry) {
                  return _buildGroup(entry.key, entry.value);
                }),
              ],
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  // ── Sub-Builders ───────────────────────────────────────────────────

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 12.h),
        width: 40.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: AppColors.divider.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(2.r),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: 'Dismiss',
              barrierColor: Colors.black.withValues(alpha: 0.9),
              pageBuilder: (context, _, __) {
                return GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    body: Center(
                      child: Hero(
                        tag: 'food_image_${widget.item.id}',
                        child: CachedNetworkImage(
                          imageUrl: widget.item.imageUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          child: Hero(
            tag: 'food_image_${widget.item.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: CachedNetworkImage(
                imageUrl: widget.item.imageUrl,
                width: 120.w,
                height: 120.h,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.name,
                style: GoogleFonts.urbanist(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                widget.item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '\$${widget.item.price.toStringAsFixed(2)}',
                style: GoogleFonts.urbanist(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroup(int groupIndex, CustomizationGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider
        Divider(color: AppColors.divider, height: 32.h),
        // Title row
        Row(
          children: [
            Text(
              group.title,
              style: GoogleFonts.urbanist(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (group.required) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'Required',
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Text(
              group.type == SelectionType.checkbox
                  ? 'Select multiple'
                  : 'Select one',
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        // Options
        // Options
        if (group.type == SelectionType.checkbox)
          ...group.options.asMap().entries.map((entry) {
            return _buildCheckboxOption(
              groupIndex: groupIndex,
              optionIndex: entry.key,
              option: entry.value,
              selected: _controller.isSelected(groupIndex, entry.key),
            );
          })
        else
          RadioGroup<int>(
            groupValue: _controller.getSelectedRadioIndex(groupIndex),
            onChanged: (val) {
              if (val != null) {
                _controller.selectRadio(groupIndex, val);
              }
            },
            child: Column(
              children:
                  group.options.asMap().entries.map((entry) {
                    return _buildRadioOption(
                      groupIndex: groupIndex,
                      optionIndex: entry.key,
                      option: entry.value,
                      selected: _controller.isSelected(groupIndex, entry.key),
                    );
                  }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildCheckboxOption({
    required int groupIndex,
    required int optionIndex,
    required CustomizationOption option,
    required bool selected,
  }) {
    return InkWell(
      onTap: () => _controller.toggleCheckbox(groupIndex, optionIndex),
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Row(
          children: [
            SizedBox(
              width: 24.w,
              height: 24.h,
              child: Checkbox(
                value: selected,
                onChanged:
                    (_) => _controller.toggleCheckbox(groupIndex, optionIndex),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.r),
                ),
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                option.name,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              option.displayPrice,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color:
                    option.isFree ? AppColors.success : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required int groupIndex,
    required int optionIndex,
    required CustomizationOption option,
    required bool selected,
  }) {
    return InkWell(
      onTap: () => _controller.selectRadio(groupIndex, optionIndex),
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Row(
          children: [
            SizedBox(
              width: 24.w,
              height: 24.h,
              child: Radio<int>(
                value: optionIndex,
                activeColor: AppColors.primary,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                option.name,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              option.displayPrice,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color:
                    option.isFree ? AppColors.success : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Quantity selector
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(32.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _controller.decrementQuantity,
                    icon: Icon(Icons.remove_rounded, size: 20.sp),
                    splashRadius: 20.r,
                  ),
                  Text(
                    _controller.quantity.toString().padLeft(2, '0'),
                    style: GoogleFonts.urbanist(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: _controller.incrementQuantity,
                    icon: Icon(Icons.add_rounded, size: 20.sp),
                    splashRadius: 20.r,
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            // Add to Cart button with live price
            Expanded(
              child: ElevatedButton(
                onPressed: _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Add to Cart — \$${_controller.grandTotal.toStringAsFixed(2)}',
                  style: GoogleFonts.urbanist(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
