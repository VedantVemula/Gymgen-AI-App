import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kIsWeb, TargetPlatform;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'firebase_options.dart';
import 'package:gymgen_ai/core/theme/app_theme.dart';
import 'package:gymgen_ai/core/widgets/galaxy_background.dart';
import 'package:gymgen_ai/providers/auth_provider.dart';
import 'package:gymgen_ai/providers/assessment_provider.dart';
import 'package:gymgen_ai/providers/profile_provider.dart';
import 'package:gymgen_ai/providers/workout_provider.dart';
import 'package:gymgen_ai/providers/nutrition_provider.dart';
import 'package:gymgen_ai/providers/coach_provider.dart';
import 'package:gymgen_ai/providers/progress_provider.dart';
import 'package:gymgen_ai/routes/app_router.dart';
import 'package:gymgen_ai/features/auth/presentation/screens/splash_screen.dart';

// Public reCAPTCHA Enterprise site key for the production web app.
const _webRecaptchaSiteKey = String.fromEnvironment(
  'APP_CHECK_WEB_RECAPTCHA_SITE_KEY',
);

// Windows App Check debug token (private dev builds only).
const _windowsAppCheckDebugToken = String.fromEnvironment(
  'APP_CHECK_WINDOWS_DEBUG_TOKEN',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kIsWeb) {
    if (kDebugMode) {
      await FirebaseAppCheck.instance.activate(
        providerWeb: WebDebugProvider(),
      );
    } else {
      if (_webRecaptchaSiteKey.isEmpty) {
        throw StateError(
          'Missing APP_CHECK_WEB_RECAPTCHA_SITE_KEY. Set the public reCAPTCHA '
          'Enterprise site key when building the production web app.',
        );
      }

      await FirebaseAppCheck.instance.activate(
        providerWeb: ReCaptchaEnterpriseProvider(_webRecaptchaSiteKey),
      );
    }
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    // FIXED: Always use Debug Provider so it works on physical devices for the demo.
    // Play Integrity only works if downloaded from the Play Store.
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidDebugProvider(),
    );
  } else if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    await FirebaseAppCheck.instance.activate(
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  } else if (defaultTargetPlatform == TargetPlatform.windows) {
    if (!kDebugMode) {
      throw UnsupportedError(
        'Firebase App Check has no production attestation provider for Windows. '
        'Use a secure server-side AI proxy for a public Windows release.',
      );
    }

    if (_windowsAppCheckDebugToken.isEmpty) {
      throw StateError(
        'Set APP_CHECK_WINDOWS_DEBUG_TOKEN to a Windows debug token registered '
        'under this Windows app in Firebase Console > App Check.',
      );
    }

    await FirebaseAppCheck.instance.activate(
      providerWindows:
          WindowsDebugProvider(debugToken: _windowsAppCheckDebugToken),
    );
  }

  runApp(const GymGenApp());
}

class GymGenApp extends StatelessWidget {
  const GymGenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AssessmentProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => NutritionProvider()),
        ChangeNotifierProvider(create: (_) => CoachProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
      ],
      child: const GymGenAppMaterial(),
    );
  }
}

class GymGenAppMaterial extends StatelessWidget {
  const GymGenAppMaterial({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'GymGen AI',
          // Make the default scaffold transparent so the galaxy shows through.
          theme: AppTheme.light().copyWith(
            scaffoldBackgroundColor: Colors.transparent,
            canvasColor: Colors.transparent,
          ),
          // The builder ensures the galaxy paints behind *every* screen.
          builder: (context, child) {
            return Stack(
              children: [
                // 1. The animated galaxy background
                const Positioned.fill(
                  child: GalaxyBackground(),
                ),
                // 2. The actual app screens
                if (child != null) Positioned.fill(child: child),
              ],
            );
          },
          onGenerateRoute: AppRouter.generate,
          initialRoute: SplashScreen.routeName,
        );
      },
    );
  }
}