import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive_utils.dart';
import '../../../core/constants/app_strings.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String privacyPolicy = 'Privacy Policy';

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
          privacyPolicy,
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
              'Last updated: January 2026',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: scaledFont(12),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              '${AppStrings.appName} ("nous", "notre" ou "nos") s\'engage à protéger votre vie privée. Cette politique de confidentialité explique comment nous collectons, utilisons et protégeons vos informations lorsque vous utilisez notre application mobile.',
              style: TextStyle(
                fontSize: scaledFont(12),
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.6,
              ),
            ),
            SizedBox(height: 24.h),
            _buildSection(
              context,
              '1. Informations que nous collectons',
              'Nous collectons les informations suivantes pour fournir nos services de livraison de repas :\n\n'
                  '• **Informations personnelles** : Votre nom, numéro de téléphone et adresse e-mail lorsque vous créez un compte.\n\n'
                  '• **Données de localisation** : La localisation de votre appareil est consultée uniquement pendant que vous utilisez l\'application pour identifier les restaurants à proximité et permettre une livraison précise.\n\n'
                  '• **Historique des commandes** : L\'enregistrement de vos commandes passées pour améliorer votre expérience et permettre le suivi des commandes.',
            ),
            SizedBox(height: 20.h),
            _buildSection(
              context,
              '2. Comment nous utilisons vos informations',
              'Nous utilisons vos informations aux fins suivantes :\n\n'
                  '• Pour traiter et livrer vos commandes de repas.\n\n'
                  '• Pour vous envoyer des notifications sur l\'état de votre commande (ex : commande confirmée, en cours de livraison).\n\n'
                  '• Pour améliorer nos services et personnaliser votre expérience.\n\n'
                  '• Pour communiquer avec vous concernant les demandes de support client.',
            ),
            SizedBox(height: 20.h),
            _buildSection(
              context,
              '3. Utilisation des données de localisation',
              'Nous accédons à vos données de localisation uniquement lorsque l\'application est en cours d\'utilisation. Cela est nécessaire pour :\n\n'
                  '• Vous montrer les restaurants proches de votre emplacement actuel.\n\n'
                  '• Assurer une livraison précise à l\'adresse choisie.\n\n'
                  'Nous ne suivons pas votre position en arrière-plan lorsque l\'application est fermée. Vous pouvez désactiver l\'accès à la localisation à tout moment dans les paramètres de votre appareil.',
            ),
            SizedBox(height: 20.h),
            _buildSection(
              context,
              '4. Partage des données',
              'Nous ne vendons, n\'échangeons ni ne partageons vos informations personnelles avec des tiers à des fins de marketing.\n\n'
                  'Vos informations peuvent être partagées avec :\n\n'
                  '• **Restaurants partenaires** : Votre adresse de livraison et les détails de votre commande sont partagés avec les restaurants pour préparer vos commandes.\n\n'
                  '• **Personnel de livraison** : Votre adresse et votre numéro de téléphone sont partagés avec les livreurs pour effectuer la livraison.',
            ),
            SizedBox(height: 20.h),
            _buildSection(
              context,
              '5. Sécurité des données',
              'Nous mettons en œuvre des mesures de sécurité conformes aux normes de l\'industrie pour protéger vos informations personnelles. Votre compte est sécurisé par authentification, et toutes les données sont transmises via des connexions cryptées (HTTPS).',
            ),
            SizedBox(height: 20.h),
            _buildSection(
              context,
              '6. Vos droits',
              'Vous avez le droit de :\n\n'
                  '• **Accès** : Demander une copie des données personnelles que nous détenons à votre sujet.\n\n'
                  '• **Correction** : Mettre à jour ou corriger les informations inexactes dans les paramètres de votre compte.\n\n'
                  '• **Suppression** : Demander la suppression de votre compte et des données associées en contactant notre équipe de support.',
            ),
            SizedBox(height: 20.h),
            _buildSection(
              context,
              '7. Paiements',
              'Les paiements sont gérés en externe par des prestataires de paiement tiers ou en espèces à la livraison. Nous ne stockons pas vos informations de carte de crédit ou bancaires.',
            ),
            SizedBox(height: 20.h),
            _buildSection(
              context,
              '8. Informations de contact',
              'Si vous avez des questions ou des préoccupations concernant cette politique de confidentialité, veuillez nous contacter :\n\n'
                  '• **E-mail** : support@mtfdelivery.com\n\n'
                  '• **Téléphone** : +216 31 383 378',
            ),
            SizedBox(height: 30.h),
            Center(
              child: Text(
                '© 2026 ${AppStrings.appName}. Tous droits réservés.',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: scaledFont(12),
                ),
              ),
            ),
            SizedBox(height: 20.h),
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
