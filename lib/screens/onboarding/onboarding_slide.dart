import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/onboarding_model.dart';

/// Onboarding slide widget
class OnboardingSlideWidget extends StatelessWidget {
  final OnboardingSlide slide;

  const OnboardingSlideWidget({super.key, required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          SizedBox(height: 320.h, child: _buildIllustration(context)),

          SizedBox(height: 16.h), // Spacer
          // Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.urbanist(
              fontSize: 28.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),

          SizedBox(height: 16.h),

          // Description
          Text(
            slide.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration(BuildContext context) {
    if (slide.hasAnimation && slide.lottieUrl != null) {
      return Lottie.asset(slide.lottieUrl!, fit: BoxFit.contain, repeat: true);
    }

    if (slide.hasImage && slide.imageUrl != null) {
      return Image.network(
        slide.imageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              value:
                  loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
            ),
          );
        },
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 280.w,
      height: 280.w,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6), // Light gray placeholder
        borderRadius: BorderRadius.circular(16.r),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 48.sp,
        color: AppColors.textSecondary,
      ),
    );
  }
}
