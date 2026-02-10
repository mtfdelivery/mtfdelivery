import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/responsive_utils.dart';
import '../../core/constants/app_colors.dart';

class CouponScreen extends StatelessWidget {
  const CouponScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20.sp,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Coupon',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: scaledFont(18),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coupon disponible',
              style: TextStyle(
                fontSize: scaledFont(16),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 20.h),
            _buildCouponCard(
              context,
              amount: '3.0',
              currency: 'د.ت',
              title: 'REDUCTION',
              subtitle: 'Sur tous les partenaires !',
              code: 'FIRST',
              validity: '22 Nov 2025 à 31 Dec 2025',
              minPurchase: '0.0',
              primaryColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard(
    BuildContext context, {
    required String amount,
    required String currency,
    required String title,
    required String subtitle,
    required String code,
    required String validity,
    required String minPurchase,
    required Color primaryColor,
  }) {
    return Container(
      height: 150.h,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            children: [
              // Left side
              Expanded(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        color: primaryColor,
                        size: 24.sp,
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            amount,
                            style: TextStyle(
                              fontSize: scaledFont(20),
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            currency,
                            style: TextStyle(
                              fontSize: scaledFont(12),
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: scaledFont(11),
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 0.3.w,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: scaledFont(9),
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Dashed line
              CustomPaint(
                size: const Size(1, double.infinity),
                painter: DashedLinePainter(
                  color: Theme.of(context).dividerColor,
                ),
              ),

              // Right side
              Expanded(
                flex: 6,
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _DashedContainer(
                        color: primaryColor,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 12.w),
                            Text(
                              code,
                              style: TextStyle(
                                fontSize: scaledFont(14),
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: code));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Code copié !')),
                                );
                              },
                              child: Icon(
                                Icons.copy_rounded,
                                size: 18.sp,
                                color: primaryColor,
                              ),
                            ),
                            SizedBox(width: 12.w),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        validity,
                        style: TextStyle(
                          fontSize: scaledFont(9),
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '*Achat minimum ',
                            style: TextStyle(
                              fontSize: scaledFont(9),
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$minPurchase $currency',
                            style: TextStyle(
                              fontSize: scaledFont(9),
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Cutouts at the bottom middle (where the cards meet)
          Positioned(
            left: (1.sw - 40.r) * 0.4 - 10.r,
            bottom: -10.r,
            child: Container(
              width: 20.r,
              height: 20.r,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // White background for the card cutouts to look like holes
          Positioned(
            bottom: -1.r,
            left: (1.sw - 40.r) * 0.4 - 10.r,
            child: Container(
              width: 20.r,
              height: 1.r,
              color: Theme.of(context).cardColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedContainer extends StatelessWidget {
  final Widget child;
  final Color color;

  const _DashedContainer({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPaddingPainter(color: color),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: child,
      ),
    );
  }
}

class _DashedPaddingPainter extends CustomPainter {
  final Color color;
  _DashedPaddingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    final path =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            const Radius.circular(20),
          ),
        );

    double dashWidth = 5, dashSpace = 3, distance = 0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 0;
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
