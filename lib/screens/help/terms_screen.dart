import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive_utils.dart';
import '../../../core/constants/app_strings.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String termsConditions = 'Terms & Conditions';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          termsConditions,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: scaledFont(16),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              '1- Home Delivery:',
              '${AppStrings.appName} is a service that allows customers to view and order products offered for sale by our partners online and benefit from delivery at the location chosen by the customer.',
            ),
            SizedBox(height: 20.h),
            _buildSection(
              context,
              '2- Ordering:',
              'The customer can access the Platform at any time and consult the offers proposed by our partners. The customer must indicate their exact address to determine the restaurants available near their location. The customer can choose the desired delivery day and time. The total amount of the Order and delivery is indicated in the cart. The Order becomes firm and final upon validation by the customer.',
            ),
            SizedBox(height: 20.h),
            _buildSection(
              context,
              '3- Order Cancellation:',
              'If the customer wishes to cancel or modify a confirmed order, they can cancel it via the platform or contact our customer service.',
            ),
            SizedBox(height: 20.h),
            _buildSection(
              context,
              '4- Delivery Zone:',
              'Our services are limited to the delivery zones specified in the application.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: scaledFont(14),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          content,
          style: TextStyle(
            fontSize: scaledFont(12),
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
