import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive_utils.dart';
import '../../../core/constants/app_strings.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'About us',
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
            Text(
              '${AppStrings.appName} est une plateforme de livraison de repas à domicile, c\'est le moyen le plus rapide de commander vos repas en ligne, depuis votre smartphone grâce à notre application gratuite.',
              style: TextStyle(
                fontSize: scaledFont(12),
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.6,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Présent exclusivement en Tunisie, ${AppStrings.appName} vous apporte à domicile ou sur votre lieu de travail des repas provenant d\'un large choix de restaurants. Nous pensons que manger est un plaisir, et que commander un repas doit être rapide et amusant.',
              style: TextStyle(
                fontSize: scaledFont(12),
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.6,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Commander sur ${AppStrings.appName} est simple comme une recette en trois étapes :',
              style: TextStyle(
                fontSize: scaledFont(12),
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.6,
              ),
            ),
            SizedBox(height: 20.h),
            _buildStep(
              context,
              '1- Choisissez vos plats préférés :',
              'Parcourez des centaines de menus pour trouver la nourriture que vous aimez.',
            ),
            SizedBox(height: 16.h),
            _buildStep(
              context,
              '2- Livraison rapide :',
              'La nourriture est préparée et vous est livrée par le restaurant de votre choix.',
            ),
            SizedBox(height: 16.h),
            _buildStep(
              context,
              '3- Paiement à la livraison :',
              'Payez rapidement et en toute sécurité lors de la livraison.',
            ),
            SizedBox(height: 24.h),
            Text(
              'Que ce soit sur mobile, tablette ou ordinateur, l\'expérience ${AppStrings.appName} reste toujours une solution pratique !',
              style: TextStyle(
                fontSize: scaledFont(12),
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, String title, String content) {
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
        SizedBox(height: 8.h),
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
