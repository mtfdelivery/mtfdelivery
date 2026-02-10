import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/user_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../core/responsive_utils.dart';
import '../../core/widgets/premium_loader.dart';

class UserDetailsScreen extends ConsumerStatefulWidget {
  const UserDetailsScreen({super.key});

  @override
  ConsumerState<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends ConsumerState<UserDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor, // Base background color
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.05),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20.sp,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: scaledFont(16),
          ),
        ),
      ),
      body:
          user == null
              ? const PremiumMtfLoader()
              : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF10B981).withValues(alpha: 0.05),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: 10.h),

                      // User Info Header
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 35.r,
                              backgroundColor:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : const Color(0xFFE0E0E0),
                              backgroundImage:
                                  user.avatarUrl != null &&
                                          user.avatarUrl!.isNotEmpty
                                      ? NetworkImage(user.avatarUrl!)
                                      : null,
                              child:
                                  user.avatarUrl == null ||
                                          user.avatarUrl!.isEmpty
                                      ? Icon(
                                        Icons.person,
                                        size: scaledFont(35),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.4),
                                      )
                                      : null,
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: TextStyle(
                                      fontSize: scaledFont(18),
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'Joined 20 Sep, 2025',
                                    style: TextStyle(
                                      color: const Color(
                                        0xFF10B981,
                                      ), // Green accent
                                      fontSize: scaledFont(12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(10.r),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).shadowColor.withValues(alpha: 0.1),
                                    blurRadius: 6.r,
                                  ),
                                ],
                              ),
                              child: InkWell(
                                onTap: () => context.push('/profile/edit'),
                                child: Icon(
                                  Icons.edit,
                                  color: const Color(0xFF10B981),
                                  size: 18.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 30.h),

                      // Stats Cards
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Loyalty points',
                                '0',
                                Icons.star,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildStatCard(
                                'Total orders',
                                '0',
                                Icons.shopping_bag_outlined,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildStatCard(
                                'Wallet balance',
                                '0.0 DT',
                                Icons.account_balance_wallet_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Action Cards
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          children: [
                            _buildActionCard(
                              icon: Icons.lock_outline,
                              title: 'Change password',
                              onTap:
                                  () =>
                                      context.push('/profile/change-password'),
                            ),

                            SizedBox(height: 12.h),

                            _buildActionCard(
                              icon: Icons.person_remove_outlined,
                              title: 'Delete account',
                              iconColor: Colors.red,
                              onTap: () {
                                _showDeleteAccountDialog(context);
                              },
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 40.h),

                      // Version
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          final version = snapshot.data?.version ?? '1.0.0';
                          final buildNumber = snapshot.data?.buildNumber ?? '1';
                          return Text(
                            'Version: $version${buildNumber.isNotEmpty ? ' ($buildNumber)' : ''}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.4),
                              fontSize: scaledFont(12),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF10B981), size: 22.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: scaledFont(16),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: scaledFont(10),
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    Color? iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? Theme.of(context).colorScheme.onSurface,
              size: 20.sp,
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: scaledFont(14),
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Account'),
            backgroundColor: Theme.of(context).cardColor,
            content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  // 1. Clear Cart
                  ref.read(cartProvider.notifier).clearCart();

                  // 2. Clear Favorites
                  ref.read(favoritesProvider.notifier).clearAll();

                  // 3. Logout
                  ref.read(userProvider.notifier).logout();

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account deleted successfully.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  context.go('/');
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
