import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../providers/auth_provider.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../../../assessment/presentation/screens/assessment_screen.dart';
import '../../../dashboard/dashboard_screen.dart';
import '../../../../services/local_storage_service.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _emailLoaded = false;
  String? _loginMessage;

  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail;
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    try {
      if (!mounted) return;
      setState(() => _emailLoaded = true);
    } catch (_) {
      if (mounted) setState(() => _emailLoaded = true);
    }
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _loginMessage = null);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      _shakeCtrl.forward(from: 0);
      _showMessage('Please enter your email address.');
      _emailFocusNode.requestFocus();
      return;
    }

    if (password.isEmpty) {
      _shakeCtrl.forward(from: 0);
      _showMessage('Please enter your password.');
      _passwordFocusNode.requestFocus();
      return;
    }

    final auth = context.read<AuthProvider>();
    await auth.signIn(email, password);
    if (!mounted) return;

    if (auth.error != null) {
      if (auth.shouldOfferSignUp) {
        await _showSignUpPrompt(email, auth.lastSignInErrorCode);
        return;
      }
      _shakeCtrl.forward(from: 0);
      _showMessage(auth.error!);
      return;
    }

    if (auth.isLoggedIn) {
      try {
        final savedProfile = await LocalStorageService.instance
            .loadProfileForUser(auth.userId, auth.userEmail);
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          savedProfile == null
              ? AssessmentScreen.routeName
              : DashboardScreen.routeName,
        );
      } catch (error) {
        if (!mounted) return;
        final details = error is FirebaseException
            ? '${error.code}: ${error.message ?? 'No additional details.'}'
            : error.toString();
        _showMessage(
          'You are signed in, but your profile could not be loaded. $details',
        );
      }
    } else {
      _showMessage(
        'Sign-in did not complete. Check your email, password, and Firebase Authentication settings.',
      );
    }
  }

  Future<void> _showSignUpPrompt(String email, String? errorCode) async {
    final accountDefinitelyMissing = errorCode == 'user-not-found';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          accountDefinitelyMissing ? 'Account not found' : 'Unable to sign in',
        ),
        content: Text(
          accountDefinitelyMissing
              ? 'There is no account registered with $email. Would you like to sign up?'
              : 'The email or password may be incorrect. If you don\'t have an account with this email, you can sign up now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Try again'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushNamed(
                context,
                SignupScreen.routeName,
                arguments: email,
              );
            },
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }

  Future<void> _loginWithGoogle() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final isNewAccount = await auth.signInWithGoogle();
    if (!mounted) return;

    if (auth.error != null) {
      _showMessage(auth.error!);
      return;
    }
    if (!auth.isLoggedIn) {
      _showMessage(
        auth.error ??
            'Google sign-in did not finish. Please try again, or check the Android Firebase OAuth configuration.',
      );
      return;
    }

    if (isNewAccount) {
      final continueSignup = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Account does not exist'),
          content: Text(
            'There is no GymGen account for ${auth.userEmail}. Please sign up to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sign Up'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (continueSignup != true) {
        await auth.cancelGoogleSignUp();
        if (mounted && auth.error != null) _showMessage(auth.error!);
        return;
      }
      auth.clearGoogleSignUpRequired();
      Navigator.pushReplacementNamed(context, AssessmentScreen.routeName);
      return;
    }

    try {
      final profile = await LocalStorageService.instance
          .loadProfileForUser(auth.userId, auth.userEmail);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        profile == null
            ? AssessmentScreen.routeName
            : DashboardScreen.routeName,
      );
    } catch (error) {
      if (!mounted) return;
      final details = error is FirebaseException
          ? '${error.code}: ${error.message ?? 'No additional details.'}'
          : error.toString();
      _showMessage(
        'You are signed in, but your profile could not be loaded. $details',
      );
    }
  }

  void _showMessage(String message) {
    if (mounted) setState(() => _loginMessage = message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final loading = auth.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Stack(
              children: [
                // Background blobs
                Positioned(
                  top: -120,
                  right: -100,
                  child: _Blob(
                    color: AppColors.accent.withOpacity(0.18),
                    size: 300,
                  ),
                ),
                Positioned(
                  bottom: -160,
                  left: -120,
                  child: _Blob(
                    color: AppColors.energy.withOpacity(0.12),
                    size: 320,
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: FadeSlideIn(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Header(),
                            const SizedBox(height: 36),
                            AnimatedBuilder(
                              animation: _shakeCtrl,
                              builder: (context, child) {
                                final shake = _shakeCtrl.isAnimating
                                    ? (1 - _shakeCtrl.value) *
                                        14 *
                                        _sine(_shakeCtrl.value)
                                    : 0.0;
                                return Transform.translate(
                                  offset: Offset(shake, 0),
                                  child: child,
                                );
                              },
                              child: _GlassCard(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _LabeledField(
                                      controller: _emailController,
                                      focusNode: _emailFocusNode,
                                      label: 'Email',
                                      hint: 'you@gmail.com',
                                      icon: Icons.mail_outline_rounded,
                                      enabled: !loading,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      onSubmitted: (_) =>
                                          _passwordFocusNode.requestFocus(),
                                    ),
                                    const SizedBox(height: 18),
                                    _LabeledField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocusNode,
                                      label: 'Password',
                                      hint: 'Enter your password',
                                      icon: Icons.lock_outline_rounded,
                                      enabled: !loading,
                                      obscure: _obscurePassword,
                                      onSubmitted: (_) {
                                        if (!loading) _login();
                                      },
                                      suffix: IconButton(
                                        onPressed: loading
                                            ? null
                                            : () => setState(
                                                  () => _obscurePassword =
                                                      !_obscurePassword,
                                                ),
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons
                                                  .visibility_off_outlined,
                                          color: AppColors.textSecondary,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: loading
                                            ? null
                                            : () => Navigator.pushNamed(
                                                  context,
                                                  ForgotPasswordScreen
                                                      .routeName,
                                                ),
                                        child: const Text(
                                          'Forgot password?',
                                          style: TextStyle(
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _LoginButton(
                                      loading: loading,
                                      onTap: _login,
                                    ),
                                    if (_loginMessage != null) ...[
                                      const SizedBox(height: 14),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.error
                                              .withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: AppColors.error
                                                .withOpacity(0.25),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.info_outline_rounded,
                                              color: AppColors.error,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                _loginMessage!,
                                                style: const TextStyle(
                                                  color: AppColors.error,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 18),
                                    const _OrDivider(),
                                    const SizedBox(height: 18),
                                    _GoogleButton(
                                      loading: loading,
                                      onTap: _loginWithGoogle,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 26),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an account?",
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                TextButton(
                                  onPressed: loading
                                      ? null
                                      : () => Navigator.pushNamed(
                                            context,
                                            SignupScreen.routeName,
                                            arguments: _emailController.text
                                                .trim(),
                                          ),
                                  child: const Text(
                                    'Sign up',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (!_emailLoaded)
                              const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── FULL-SCREEN AUTHENTICATING OVERLAY ───
          IgnorePointer(
            ignoring: !loading,
            child: AnimatedOpacity(
              opacity: loading ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: loading
                  ? const _AuthenticatingOverlay()
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  double _sine(double t) => (t * 6.28318 * 2).remainder(6.28318);
}

// ─── Full-screen overlay while signing in ──────────────────────────────────
class _AuthenticatingOverlay extends StatefulWidget {
  const _AuthenticatingOverlay();

  @override
  State<_AuthenticatingOverlay> createState() =>
      _AuthenticatingOverlayState();
}

class _AuthenticatingOverlayState extends State<_AuthenticatingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.55),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, t, child) {
            return Transform.scale(
              scale: 0.85 + 0.15 * t,
              child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
            );
          },
          child: Container(
            width: 260,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer rotating arc
                      AnimatedBuilder(
                        animation: _spin,
                        builder: (context, _) {
                          return Transform.rotate(
                            angle: _spin.value * 6.28318,
                            child: SizedBox(
                              width: 76,
                              height: 76,
                              child: CircularProgressIndicator(
                                value: 0.75,
                                strokeWidth: 4,
                                strokeCap: StrokeCap.round,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  AppColors.accent,
                                ),
                                backgroundColor:
                                    AppColors.accent.withOpacity(0.15),
                              ),
                            ),
                          );
                        },
                      ),
                      // Inner gradient icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppGradients.hero,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.lock_person_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Authenticating…',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Verifying your credentials',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                // Bouncing dots
                const _BouncingDots(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = (_c.value - i * 0.15) % 1.0;
            final scale = 0.6 + (1 - (phase - 0.5).abs() * 2) * 0.4;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.4 + scale * 0.6),
                shape: BoxShape.circle,
              ),
              transform: Matrix4.identity()..scale(scale),
            );
          }),
        );
      },
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: AppGradients.hero,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppShadows.glow(AppColors.accent),
          ),
          child: const Icon(
            Icons.fitness_center_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Welcome back',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign in to continue your fitness journey',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.elevated,
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
      ),
      child: child,
    );
  }
}

class _LabeledField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final bool enabled;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  const _LabeledField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.enabled = true,
    this.suffix,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  State<_LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<_LabeledField> {
  late bool _focused = widget.focusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocus);
  }

  void _handleFocus() {
    if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _focused && widget.enabled
                ? [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            obscureText: widget.obscure,
            keyboardType: widget.keyboardType,
            onSubmitted: widget.onSubmitted,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: Icon(
                widget.icon,
                color: _focused ? AppColors.accent : AppColors.textMuted,
                size: 20,
              ),
              suffixIcon: widget.suffix,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _LoginButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: loading ? null : AppGradients.hero,
          color: loading ? AppColors.accent.withOpacity(0.7) : null,
          borderRadius: BorderRadius.circular(100),
          boxShadow: loading ? [] : AppShadows.glow(AppColors.accent),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: loading ? null : onTap,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(scale: anim, child: child),
                ),
                child: loading
                    ? const Row(
                        key: ValueKey('loading'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Authenticating…',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        key: ValueKey('idle'),
                        'Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.border)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: AppColors.border)),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _GoogleButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: loading ? 0.5 : 1,
      child: BouncyTap(
        onTap: loading ? null : onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Continue with Google',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0.0)]),
      ),
    );
  }
}