import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/responsive_utils.dart';
import '../../core/constants/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Labels (Hardcoded as l10n is not currently set up)
    const String helpAssistance = 'Aide & Assistance';
    const String howCanWeHelp = 'Comment pouvons-nous vous aider ?';
    const String tellUsProblem = 'Dites-nous votre problème';
    const String addressLabel = 'Adresse';
    const String callLabel = 'Appeler';
    const String sendEmailLabel = 'Envoyer un e-mail';

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: scaledFont(20),
                    ),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      helpAssistance,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: scaledFont(18),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 48.w),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Title and subtitle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  Text(
                    howCanWeHelp,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: scaledFont(18),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    tellUsProblem,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: scaledFont(14),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Contact options cards
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).scaffoldBackgroundColor
                          : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.r),
                    topRight: Radius.circular(30.r),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Column(
                    children: [
                      // Address Card
                      _buildContactCard(
                        context,
                        icon: Icons.location_on,
                        iconColor: AppColors.primary,
                        title: addressLabel,
                        subtitle: 'Sousse, Tunisie',
                        onTap: () {
                          // Could open maps here
                        },
                      ),

                      SizedBox(height: 16.h),

                      // Call and Email cards in a row
                      Row(
                        children: [
                          Expanded(
                            child: _buildContactCard(
                              context,
                              icon: Icons.phone,
                              iconColor: AppColors.primary,
                              title: callLabel,
                              subtitle: '+216 12 345 678',
                              onTap: () => _launchPhone('+21612345678'),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: _buildContactCard(
                              context,
                              icon: Icons.email,
                              iconColor: AppColors.primary,
                              title: sendEmailLabel,
                              subtitle: 'support@mtfdelivery.com',
                              onTap:
                                  () => _launchEmail('support@mtfdelivery.com'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: const Color(0xFFFFB84D),
            width: 1.5.w,
          ), // Keeping the orange border from user code
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: scaledFont(24)),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: scaledFont(14),
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: scaledFont(11),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
