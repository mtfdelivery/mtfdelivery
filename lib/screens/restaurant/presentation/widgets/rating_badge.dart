import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Premium rating badge component
class RatingBadge extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final bool showReviewCount;

  const RatingBadge({
    super.key,
    required this.rating,
    this.reviewCount = 0,
    this.showReviewCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSm.w,
        vertical: AppDimensions.paddingXs.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound.r),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: AppColors.starFilled, size: 16.sp),
          SizedBox(width: 4.w),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (showReviewCount && reviewCount > 0) ...[
            SizedBox(width: 4.w),
            Text(
              '($reviewCount+)',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
