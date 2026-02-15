import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

import '../../widgets/modals/language_modal.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_settings_provider.dart';
import '../../providers/ai_assistant_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingLg),
        children: [
          _buildSectionHeader(context, 'Preferences'),
          _buildToggleTile(
            context,
            'Notifications',
            Icons.notifications,
            ref.watch(notificationSettingsProvider),
            (value) {
              ref.read(notificationSettingsProvider.notifier).state = value;
            },
          ),
          _buildToggleTile(
            context,
            'AI Assistant',
            Icons.auto_awesome,
            ref.watch(aiAssistantEnabledProvider),
            (value) {
              ref.read(aiAssistantEnabledProvider.notifier).state = value;
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final currentLanguage = ref.watch(languageProvider);
              return _buildTile(
                context,
                'Language',
                Icons.language,
                () => showLanguageModal(context),
                trailing: Text(
                  currentLanguage.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppDimensions.spacingLg),
          const Divider(),
          const SizedBox(height: AppDimensions.spacingLg),

          _buildSectionHeader(context, 'Support'),
          _buildTile(
            context,
            'About',
            Icons.info,
            () => context.push('/about'),
          ),
          _buildTile(context, 'Help', Icons.help, () => context.push('/help')),
          _buildTile(
            context,
            'Privacy Policy',
            Icons.privacy_tip,
            () => context.push('/privacy'),
          ),
          _buildTile(
            context,
            'Terms of Service',
            Icons.description,
            () => context.push('/terms'),
          ),

          const SizedBox(height: AppDimensions.spacingXxl),

          // Version info
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.paddingSm,
        bottom: AppDimensions.spacingSm,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        trailing:
            trailing ??
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textTertiary,
            ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),
    );
  }

  Widget _buildToggleTile(
    BuildContext context,
    String title,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),
    );
  }
}
