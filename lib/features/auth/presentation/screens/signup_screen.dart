import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:gymgen_ai/features/assessment/presentation/screens/assessment_screen.dart';
import 'package:gymgen_ai/features/dashboard/dashboard_screen.dart';
import 'package:gymgen_ai/features/auth/presentation/screens/login_screen.dart';
import 'package:gymgen_ai/providers/auth_provider.dart';
import 'package:gymgen_ai/services/local_storage_service.dart';
import 'package:gymgen_ai/core/theme/app_colors.dart';
import 'package:gymgen_ai/core/theme/app_theme.dart';
import 'package:gymgen_ai/core/widgets/animations.dart';

class SignupScreen extends StatefulWidget {
  static const routeName = '/signup';

  const SignupScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();

    await auth.signUp(
      email,
      _passwordController.text,
      name: _nameController.text.trim(),
    );

    if (!mounted) return;

    if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (auth.verificationEmailSent) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.mark_email_read_rounded,
                color: AppColors.accent,
                size: 26,
              ),
              SizedBox(width: 10),
              Text('Verify your Gmail'),
            ],
          ),
          content: Text(
            'We sent a verification link to $email. Open that email and verify the address before logging in. Check Spam if it does not arrive.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: const Text('Continue to login'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        LoginScreen.routeName,
        arguments: email,
      );
      return;
    }

    if (auth.user != null) {
      try {
        final profile = await LocalStorageService.instance
            .loadProfileForUser(auth.userId, auth.userEmail);

        if (!mounted) return;

        Navigator.of(context).pushReplacementNamed(
          profile == null
              ? AssessmentScreen.routeName
              : DashboardScreen.routeName,
        );
      } catch (error) {
        if (!mounted) return;

        final details = error is FirebaseException
            ? '${error.code}: ${error.message ?? 'No additional details.'}'
            : error.toString();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You are signed in, but your profile could not be loaded. $details',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -100,
              child: _Blob(
                color: AppColors.accent.withOpacity(0.18),
                size: 300,
              ),
            ),
            Positioned(
              bottom: -160,
              right: -120,
              child: _Blob(
                color: AppColors.energy.withOpacity(0.12),
                size: 320,
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: FadeSlideIn(
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Header(),
                            const SizedBox(height: 30),
                            _GlassCard(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  _LabeledField(
                                    controller: _nameController,
                                    label: 'Name',
                                    hint: 'John Doe',
                                    icon: Icons.person_outline_rounded,
                                    capitalization:
                                        TextCapitalization.words,
                                    autofillHints: const [
                                      AutofillHints.name
                                    ],
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Enter your name.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _LabeledField(
                                    controller: _emailController,
                                    label: 'Email',
                                    hint: 'hello@gmail.com',
                                    icon: Icons.mail_outline_rounded,
                                    keyboardType:
                                        TextInputType.emailAddress,
                                    autofillHints: const [
                                      AutofillHints.email,
                                      AutofillHints.username,
                                    ],
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Enter your email.';
                                      }
                                      final emailPattern =
                                          RegExp(r'^\S+@\S+\.\S+$');
                                      if (!emailPattern
                                          .hasMatch(value.trim())) {
                                        return 'Enter a valid email.';
                                      }
                                      if (!value
                                          .trim()
                                          .toLowerCase()
                                          .endsWith('@gmail.com')) {
                                        return 'Use a Gmail address ending in @gmail.com.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _LabeledField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    hint: 'Create password',
                                    icon: Icons.lock_outline_rounded,
                                    obscure: _obscurePassword,
                                    autofillHints: const [
                                      AutofillHints.newPassword
                                    ],
                                    suffix: IconButton(
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons
                                                .visibility_outlined
                                            : Icons
                                                .visibility_off_outlined,
                                        color: AppColors.textSecondary,
                                        size: 20,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.length < 8) {
                                        return 'Password must be at least 8 characters.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _LabeledField(
                                    controller: _confirmController,
                                    label: 'Confirm password',
                                    hint: 'Repeat password',
                                    icon: Icons.lock_outline_rounded,
                                    obscure: _obscureConfirm,
                                    autofillHints: const [
                                      AutofillHints.newPassword
                                    ],
                                    suffix: IconButton(
                                      onPressed: () => setState(
                                        () => _obscureConfirm =
                                            !_obscureConfirm,
                                      ),
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons
                                                .visibility_outlined
                                            : Icons
                                                .visibility_off_outlined,
                                        color: AppColors.textSecondary,
                                        size: 20,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value !=
                                          _passwordController.text) {
                                        return 'Passwords do not match.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 22),
                                  _SubmitButton(
                                    loading: auth.loading,
                                    onTap: _submit,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account?',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text(
                                    'Sign in',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
            Icons.person_add_alt_1_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Create your account',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Start building smarter fitness habits with AI coaching.',
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
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final Iterable<String>? autofillHints;
  final String? Function(String?) validator;

  const _LabeledField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
    this.autofillHints,
  });

  @override
  State<_LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<_LabeledField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
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
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscure,
            keyboardType: widget.keyboardType,
            textCapitalization: widget.capitalization,
            autofillHints: widget.autofillHints,
            validator: widget.validator,
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

class _SubmitButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _SubmitButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: loading ? null : AppGradients.hero,
          color: loading ? AppColors.accent.withOpacity(0.6) : null,
          borderRadius: BorderRadius.circular(100),
          boxShadow: loading ? [] : AppShadows.glow(AppColors.accent),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: loading ? null : onTap,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Create account',
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