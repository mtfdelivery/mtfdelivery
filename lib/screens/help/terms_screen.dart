import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive_utils.dart';
import '../../../core/constants/app_strings.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String termsConditions = 'Conditions Générales';

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
              '1- Livraison à domicile :',
              '${AppStrings.appName} est un service qui permet aux clients de consulter et de commander en ligne les produits proposés à la vente par nos partenaires et de bénéficier d\'une livraison à l\'endroit choisi par le client.',
            ),
            SizedBox(height: 20.h),
            _buildSection(
              context,
              '2- Commande :',
              'Le client peut accéder à la Plateforme à tout moment et consulter les offres proposées par nos partenaires. Le client doit indiquer son adresse exacte afin de déterminer les restaurants disponibles à proximité de son emplacement. Le client peut choisir le jour et l\'heure de livraison souhaités. Le montant total de la Commande et de la livraison est indiqué dans le panier. La Commande devient ferme et définitive dès la validation par le client.',
            ),
            SizedBox(height: 20.h),
            _buildSection(
              context,
              '3- Annulation de commande :',
              'Si le client souhaite annuler ou modifier une commande qu\'il a confirmée, il peut l\'annuler via la plateforme ou contacter notre service client.',
            ),
            SizedBox(height: 20.h),
            _buildSection(
              context,
              '4- Zone de livraison :',
              'Nos services sont limités aux zones de livraison spécifiées dans l\'application.',
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
