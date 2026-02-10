import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'address_controller.dart';
import '../../../core/responsive_utils.dart';
import '../../../core/widgets/premium_loader.dart';

class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.onSurface,
            size: scaledFont(20),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'My address',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: scaledFont(16),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: addressesAsync.when(
        data:
            (addresses) =>
                addresses.isEmpty
                    ? _buildEmptyState(context)
                    : _buildAddressList(context, addresses, ref),
        loading: () => const PremiumMtfLoader(),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton:
          addressesAsync.valueOrNull?.isNotEmpty == true
              ? FloatingActionButton(
                onPressed: () => context.push('/profile/addresses/add'),
                backgroundColor: const Color(0xFF10B981),
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 100.sp,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                  Positioned(
                    bottom: 20.h,
                    child: Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.home, color: Colors.white, size: 20.sp),
                    ),
                  ),
                  Positioned(
                    top: 20.h,
                    right: 20.w,
                    child: Container(
                      padding: EdgeInsets.all(2.r),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Text(
                'No address found',
                style: TextStyle(
                  fontSize: scaledFont(20),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Please add your address for a better experience',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: scaledFont(16),
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/profile/addresses/add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Add an address',
                        style: TextStyle(
                          fontSize: scaledFont(16),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressList(BuildContext context, addresses, WidgetRef ref) {
    return ListView.builder(
      padding: EdgeInsets.all(16.r),
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        final address = addresses[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          elevation: 0,
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey[200]!,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        address.label == 'Home'
                            ? Icons.home
                            : address.label == 'Work'
                            ? Icons.work
                            : address.label == 'Parents'
                            ? Icons.family_restroom
                            : Icons.grid_view,
                        color: const Color(0xFF10B981),
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address.label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: scaledFont(14),
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            address.address,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: scaledFont(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20.sp,
                      ),
                      onPressed: () {
                        ref
                            .read(addressControllerProvider.notifier)
                            .removeAddress(address.id);
                      },
                    ),
                  ],
                ),
                if (address.name.isNotEmpty || address.phone.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Divider(height: 1.h, color: Theme.of(context).dividerColor),
                  SizedBox(height: 12.h),
                  if (address.name.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16.sp,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          address.name,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.8),
                            fontSize: scaledFont(12),
                          ),
                        ),
                      ],
                    ),
                  if (address.phone.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 16.sp,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          address.phone,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.8),
                            fontSize: scaledFont(12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
