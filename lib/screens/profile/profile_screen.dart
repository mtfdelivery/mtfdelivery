import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/responsive.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/localization/app_localizations.dart';
import '../../widgets/modals/language_modal.dart';
import '../../navigation/app_router.dart';
import '../../providers/user_provider.dart';
import '../../providers/language_provider.dart';

/// Profile screen
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final l10n = AppLocalizations.of(context);
    final currentLanguage = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          child: Column(
            children: [
              const SizedBox(height: AppDimensions.spacingLg),

              // Profile header
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingXl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 3),
                        image: DecorationImage(
                          image: NetworkImage(
                            user?.avatarUrl ??
                                'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingLg),

                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Guest User',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'Not signed in',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.phone ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Edit button
                    IconButton(
                      onPressed: () => context.push(Routes.profileDetails),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.edit,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.spacingXxl),

              // Menu sections
              context.isMobile
                  ? Column(
                    children: [
                      _buildMenuSection(context, l10n.general, [
                        _MenuItem(
                          icon: Iconsax.user,
                          title: l10n.profile,
                          onTap: () => context.push(Routes.profileDetails),
                        ),
                        // Settings removed
                        _MenuItem(
                          icon: Iconsax.map,
                          title: l10n.myAddress,
                          onTap: () => context.push(Routes.addresses),
                        ),
                        _MenuItem(
                          icon: Iconsax.receipt_2,
                          title: l10n.myOrders,
                          onTap: () => context.push(Routes.orders),
                        ),
                        _MenuItem(
                          icon: Iconsax.heart,
                          title: l10n.myFavorites,
                          onTap: () => context.push(Routes.favorites),
                        ),
                        _MenuItem(
                          icon: Iconsax.language_square,
                          title: l10n.language,
                          trailing: Text(
                            currentLanguage.name,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          onTap: () => showLanguageModal(context),
                        ),
                      ]),
                      const SizedBox(height: AppDimensions.spacingLg),
                      _buildMenuSection(context, l10n.promotionalActivity, [
                        _MenuItem(
                          icon: Iconsax.ticket,
                          title: l10n.coupon,
                          onTap: () => context.push(Routes.coupons),
                        ),
                        _MenuItem(
                          icon: Iconsax.notification,
                          title: l10n.notifications,
                          onTap: () => context.push(Routes.notifications),
                        ),
                      ]),
                      const SizedBox(height: AppDimensions.spacingLg),
                      _buildMenuSection(context, l10n.helpSupportSection, [
                        _MenuItem(
                          icon: Iconsax.message_question,
                          title: l10n.helpAssistance,
                          onTap: () => context.push(Routes.help),
                        ),
                        _MenuItem(
                          icon: Iconsax.info_circle,
                          title: l10n.aboutUs,
                          onTap: () => context.push(Routes.about),
                        ),
                        _MenuItem(
                          icon: Iconsax.document_text,
                          title: l10n.termsConditions,
                          onTap: () => context.push(Routes.terms),
                        ),
                        _MenuItem(
                          icon: Iconsax.shield_tick,
                          title: l10n.privacyPolicy,
                          onTap: () => context.push(Routes.privacy),
                        ),
                      ]),
                    ],
                  )
                  : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: context.isDesktop ? 3 : 2,
                    mainAxisSpacing: 20.h,
                    crossAxisSpacing: 20.w,
                    childAspectRatio: 1.5,
                    children: [
                      _buildMenuCard(
                        context,
                        Iconsax.user,
                        l10n.profile,
                        () => context.push(Routes.profileDetails),
                      ),
                      _buildMenuCard(
                        context,
                        Iconsax.map,
                        l10n.myAddress,
                        () => context.push(Routes.addresses),
                      ),
                      _buildMenuCard(
                        context,
                        Iconsax.receipt_2,
                        l10n.myOrders,
                        () => context.push(Routes.orders),
                      ),
                      _buildMenuCard(
                        context,
                        Iconsax.heart,
                        l10n.myFavorites,
                        () => context.push(Routes.favorites),
                      ),
                      _buildMenuCard(
                        context,
                        Iconsax.language_square,
                        l10n.language,
                        () => showLanguageModal(context),
                        trailing: currentLanguage.name,
                      ),
                      _buildMenuCard(
                        context,
                        Iconsax.ticket,
                        l10n.coupon,
                        () => context.push(Routes.coupons),
                      ),
                      _buildMenuCard(
                        context,
                        Iconsax.notification,
                        l10n.notifications,
                        () => context.push(Routes.notifications),
                      ),
                      _buildMenuCard(
                        context,
                        Iconsax.message_question,
                        l10n.helpAssistance,
                        () => context.push(Routes.help),
                      ),
                      _buildMenuCard(
                        context,
                        Iconsax.info_circle,
                        l10n.aboutUs,
                        () => context.push(Routes.about),
                      ),
                    ],
                  ),

              const SizedBox(height: AppDimensions.spacingXxl),

              // Logout button
              Center(
                child: SizedBox(
                  width: context.isMobile ? double.infinity : 300,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(userProvider.notifier).logout();
                      context.go(Routes.login);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingLg),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.logout, color: AppColors.error),
                          const SizedBox(width: AppDimensions.spacingSm),
                          Text(
                            l10n.logout,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.spacingHuge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    String title,
    List<_MenuItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppDimensions.paddingSm,
            bottom: AppDimensions.spacingSm,
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Column(
            children:
                items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == items.length - 1;

                  return Column(
                    children: [
                      _buildMenuItem(item),
                      if (!isLast)
                        const Padding(
                          padding: EdgeInsets.only(left: 56),
                          child: Divider(height: 1),
                        ),
                    ],
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    String? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (trailing != null) ...[
              const SizedBox(height: 4),
              Text(
                trailing,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (item.trailing != null) ...[
              const SizedBox(width: AppDimensions.spacingSm),
              item.trailing!,
            ],
            const SizedBox(width: AppDimensions.spacingSm),
            const Icon(
              Iconsax.arrow_right_3,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });
}
