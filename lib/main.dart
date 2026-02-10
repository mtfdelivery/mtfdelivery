import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'providers/language_provider.dart';
import 'navigation/app_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  // Ensure binding is initialized first
  WidgetsFlutterBinding.ensureInitialized();

  // Use runZonedGuarded to catch uncaught errors
  runZonedGuarded(
    () async {
      // Set preferred orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      // Set system UI overlay style
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      // Production error boundary
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return Material(
          child: Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  details.exception.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      };

      runApp(const ProviderScope(child: MtfDeliveryApp()));
    },
    (error, stack) {
      debugPrint('Uncaught error: $error');
      debugPrint(stack.toString());
    },
  );
}

class MtfDeliveryApp extends ConsumerWidget {
  const MtfDeliveryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Standard mobile design size
      minTextAdapt: true,
      splitScreenMode: true,
      // Use builder only for initialization, don't wrap the entire app in it here unless necessary
      builder: (_, child) {
        final appLanguage = ref.watch(languageProvider);

        return MaterialApp.router(
          title: 'MTF Delivery',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
          locale: appLanguage.locale,
          supportedLocales: AppLanguage.values.map((l) => l.locale).toList(),
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            // Ensure we have a valid child and wrap in a scaffold-like structure for web
            return Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.sizeOf(context).width > 600
                            ? 500
                            : double.infinity,
                  ),
                  // Ensure child is not null and has a default size if needed
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
