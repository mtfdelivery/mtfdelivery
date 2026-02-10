import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class PremiumMtfLoader extends StatefulWidget {
  const PremiumMtfLoader({super.key});

  @override
  State<PremiumMtfLoader> createState() => _PremiumMtfLoaderState();
}

class _PremiumMtfLoaderState extends State<PremiumMtfLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _controller,
            child: Container(
              width: 80.r,
              height: 80.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 3.r,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(2.r),
                child: CircularProgressIndicator(
                  strokeWidth: 2.r,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          Icon(
            Icons.restaurant, // You can replace this with your app logo icon
            color: AppColors.primary,
            size: 30.sp,
          ),
        ],
      ),
    );
  }
}
