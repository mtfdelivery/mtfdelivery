import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'primary_home_screen.dart';
import '../../core/constants/app_colors.dart';
import 'domain/home_service.dart';
import '../../providers/ai_assistant_provider.dart';
import '../../widgets/ai_chat_bottom_sheet.dart';
import '../../core/utils/responsive.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(homeServicesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 20.sp,
          ),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'All Services',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
            color: textColor,
          ),
        ),
      ),
      body: servicesAsync.when(
        data: (services) {
          return GridView.builder(
            padding: EdgeInsets.all(20.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.w,
              childAspectRatio: 0.85,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return _buildServiceGridItem(context, service, textColor);
            },
          );
        },
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        error: (err, stack) => Center(child: Text('Error loading services')),
      ),
      floatingActionButton:
          ref.watch(aiAssistantEnabledProvider)
              ? Container(
                margin: EdgeInsets.only(bottom: context.isMobile ? 80.h : 20.h),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useRootNavigator: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const AiChatBottomSheet(),
                    );
                  },
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildServiceGridItem(
    BuildContext context,
    HomeService service,
    Color textColor,
  ) {
    return GestureDetector(
      onTap:
          service.isAvailable && service.route != null
              ? () => context.push(service.route!)
              : null,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFF1F3F5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  service.localAssetPath,
                  width: 40.w,
                  height: 40.w,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.room_service_outlined,
                      color: Colors.grey.withValues(alpha: 0.5),
                      size: 28.sp,
                    );
                  },
                ),
                if (service.hasPromo)
                  Positioned(
                    top: -8.h,
                    right: -12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        'Promo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              service.label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
                color: textColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!service.isAvailable)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
