import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/responsive_utils.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/promo_code_provider.dart';
import '../../data/models/promo_code_model.dart';

class CouponScreen extends ConsumerWidget {
  const CouponScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promoCodesAsync = ref.watch(promoCodesProvider);

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
      body: promoCodesAsync.when(
        data: (promoCodes) {
          if (promoCodes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 64.sp,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Aucun coupon disponible',
                    style: TextStyle(
                      fontSize: scaledFont(16),
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(promoCodesProvider.notifier).refresh(),
            child: ListView.separated(
              padding: EdgeInsets.all(20.r),
              itemCount: promoCodes.length,
              separatorBuilder: (context, index) => SizedBox(height: 20.h),
              itemBuilder: (context, index) {
                final promo = promoCodes[index];
                return _buildCouponCard(
                  context,
                  promo: promo,
                  primaryColor: AppColors.primary,
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, stack) => Center(
              child: Text(
                'Erreur lors du chargement des coupons',
                style: TextStyle(color: Colors.red, fontSize: scaledFont(14)),
              ),
            ),
      ),
    );
  }

  Widget _buildCouponCard(
    BuildContext context, {
    required PromoCodeModel promo,
    required Color primaryColor,
  }) {
    final amountText =
        promo.discountType == 'percentage'
            ? '${promo.discountValue.toInt()}%'
            : promo.discountType == 'free_delivery'
            ? 'OFFERT'
            : '${promo.discountValue.toInt()}';

    final currencyText =
        promo.discountType == 'percentage'
            ? ''
            : promo.discountType == 'free_delivery'
            ? ''
            : 'د.ت';
    final subtitle = promo.description ?? 'Sur tous les partenaires !';
    final validity =
        promo.validUntil != null
            ? 'Valide jusqu\'au ${DateFormat('dd MMM yyyy').format(promo.validUntil!)}'
            : 'Valid for unlimited duration';
    final minPurchase = promo.minOrderAmount?.toString() ?? '0.0';

    return Container(
      constraints: BoxConstraints(minHeight: 140.h),
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
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          promo.discountType == 'free_delivery'
                              ? Icons.moped_outlined
                              : Icons.payments_outlined,
                          color: primaryColor,
                          size: 24.sp,
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              amountText,
                              style: TextStyle(
                                fontSize: scaledFont(20),
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (currencyText.isNotEmpty) ...[
                              SizedBox(width: 4.w),
                              Text(
                                currencyText,
                                style: TextStyle(
                                  fontSize: scaledFont(12),
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          promo.discountType == 'free_delivery'
                              ? 'LIVRAISON'
                              : 'REDUCTION',
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                                promo.code,
                                style: TextStyle(
                                  fontSize: scaledFont(14),
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: promo.code),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Code copied!'),
                                    ),
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
                          textAlign: TextAlign.center,
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
                              '$minPurchase د.ت',
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
