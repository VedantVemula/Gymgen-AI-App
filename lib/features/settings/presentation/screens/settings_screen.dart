import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymgen_ai/core/theme/app_colors.dart';
import 'package:gymgen_ai/core/theme/app_theme.dart';
import 'package:gymgen_ai/core/widgets/animations.dart';
import 'package:gymgen_ai/models/assessment_model.dart';
import 'package:gymgen_ai/models/user_profile_model.dart';
import 'package:gymgen_ai/providers/auth_provider.dart';
import 'package:gymgen_ai/providers/profile_provider.dart';
import 'package:gymgen_ai/providers/workout_provider.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();

  static const _genders = ['Male', 'Female', 'Other'];
  static const _goals = [
    'Build muscle',
    'Lose fat',
    'Improve endurance',
    'Increase mobility',
  ];
  static const _experiences = ['Beginner', 'Intermediate', 'Advanced'];
  static const _equipmentOptions = [
    'Gym access',
    'Home equipment',
    'Bodyweight only',
    'No equipment',
  ];
  static const _diets = [
    'Balanced',
    'Low carb',
    'High protein',
    'Vegetarian'
  ];
  static const _workoutDays = [3, 4, 5, 6];

  String? _gender, _goal, _experience, _equipment, _diet;
  int _days = 4;
  bool _initialized = false, _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  String? _safe(String value, List<String> options) =>
      options.contains(value) ? value : null;

  void _initialize(UserProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _name.text = profile.name;
    _age.text = profile.age > 0 ? '${profile.age}' : '';
    _height.text = profile.heightCm > 0
        ? profile.heightCm.toStringAsFixed(profile.heightCm % 1 == 0 ? 0 : 1)
        : '';
    _weight.text =
        profile.weightKg > 0 ? profile.weightKg.toStringAsFixed(1) : '';
    _gender = _safe(profile.gender, _genders);
    _goal = _safe(profile.goal, _goals);
    _experience = _safe(profile.experience, _experiences);
    _equipment = _safe(profile.equipment, _equipmentOptions);
    _diet = _safe(profile.dietPreference, _diets);
    _days =
        _workoutDays.contains(profile.workoutDays) ? profile.workoutDays : 4;
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileProvider>();
    final auth = context.watch<AuthProvider>();
    final profile = profileState.profile;
    if (profile != null) _initialize(profile);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: profileState.loading && profile == null
          ? const Center(child: CircularProgressIndicator())
          : profile == null
              ? _EmptyProfile(error: profileState.error)
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding:
                            const EdgeInsets.fromLTRB(18, 18, 18, 32),
                        children: [
                          FadeSlideIn(
                            child: _Hero(
                              name: profile.name,
                              email: profile.email,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 80),
                            child: const _Heading(
                              'Personal details',
                              'Keep your profile and measurements up to date.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 120),
                            child: _Card(
                              child: Column(
                                children: [
                                  _textField(
                                    _name,
                                    'Full name',
                                    Icons.person_outline_rounded,
                                    capitalization:
                                        TextCapitalization.words,
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Enter your name'
                                            : null,
                                  ),
                                  const _Line(),
                                  _textField(
                                    _age,
                                    'Age',
                                    Icons.cake_outlined,
                                    keyboard: TextInputType.number,
                                    validator: (v) {
                                      final n = int.tryParse(v ?? '');
                                      return n == null || n < 13 || n > 100
                                          ? 'Enter an age from 13 to 100'
                                          : null;
                                    },
                                  ),
                                  const _Line(),
                                  _textField(
                                    _height,
                                    'Height (cm)',
                                    Icons.height_rounded,
                                    keyboard:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    validator: (v) {
                                      final n = double.tryParse(v ?? '');
                                      return n == null ||
                                              n < 80 ||
                                              n > 250
                                          ? 'Enter a valid height in cm'
                                          : null;
                                    },
                                  ),
                                  const _Line(),
                                  _textField(
                                    _weight,
                                    'Weight (kg)',
                                    Icons.monitor_weight_outlined,
                                    keyboard:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    validator: (v) {
                                      final n = double.tryParse(v ?? '');
                                      return n == null ||
                                              n < 25 ||
                                              n > 350
                                          ? 'Enter a valid weight in kg'
                                          : null;
                                    },
                                  ),
                                  const _Line(),
                                  _dropdown(
                                    'Gender',
                                    Icons.wc_outlined,
                                    _gender,
                                    _genders,
                                    (v) => setState(() => _gender = v),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 160),
                            child: const _Heading(
                              'Fitness preferences',
                              'These settings personalise your workout plan and nutrition targets.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 200),
                            child: _Card(
                              child: Column(
                                children: [
                                  _dropdown(
                                    'Fitness goal',
                                    Icons.flag_outlined,
                                    _goal,
                                    _goals,
                                    (v) => setState(() => _goal = v),
                                  ),
                                  const _Line(),
                                  _dropdown(
                                    'Experience level',
                                    Icons.trending_up_rounded,
                                    _experience,
                                    _experiences,
                                    (v) => setState(() => _experience = v),
                                  ),
                                  const _Line(),
                                  _dropdown(
                                    'Available equipment',
                                    Icons.fitness_center_rounded,
                                    _equipment,
                                    _equipmentOptions,
                                    (v) => setState(() => _equipment = v),
                                  ),
                                  const _Line(),
                                  _dropdown(
                                    'Diet preference',
                                    Icons.restaurant_menu_rounded,
                                    _diet,
                                    _diets,
                                    (v) => setState(() => _diet = v),
                                  ),
                                  const _Line(),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 14, 16, 14),
                                    child: Row(
                                      children: [
                                        const _IconTile(
                                            Icons.calendar_month_rounded),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Workout days per week',
                                                style: TextStyle(
                                                  color: AppColors
                                                      .textPrimary,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              SizedBox(height: 3),
                                              Text(
                                                'Choose a schedule you can maintain.',
                                                style: TextStyle(
                                                  color: AppColors
                                                      .textSecondary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DropdownButton<int>(
                                          value: _days,
                                          underline:
                                              const SizedBox.shrink(),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                          items: _workoutDays
                                              .map((d) => DropdownMenuItem(
                                                    value: d,
                                                    child: Text('$d days'),
                                                  ))
                                              .toList(),
                                          onChanged: (v) => setState(
                                              () => _days = v ?? 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (profileState.error != null) ...[
                            _Message(profileState.error!, error: true),
                            const SizedBox(height: 12),
                          ],
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 240),
                            child: SizedBox(
                              height: 56,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: _saving
                                      ? null
                                      : AppGradients.hero,
                                  color: _saving
                                      ? AppColors.accent
                                          .withOpacity(0.5)
                                      : null,
                                  borderRadius:
                                      BorderRadius.circular(100),
                                  boxShadow: _saving
                                      ? []
                                      : AppShadows.glow(AppColors.accent),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius:
                                        BorderRadius.circular(100),
                                    onTap: _saving
                                        ? null
                                        : () => _saveChanges(profile),
                                    child: Center(
                                      child: _saving
                                          ? const Row(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Text(
                                                  'Saving changes…',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const Row(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .check_rounded,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Save changes',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 280),
                            child: const _Heading(
                              'Account',
                              'Manage your account and app information.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 320),
                            child: _Card(
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: const _IconTile(
                                        Icons.email_outlined),
                                    title: const Text(
                                      'Email address',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      auth.userEmail.isEmpty
                                          ? profile.email
                                          : auth.userEmail,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const _Line(),
                                  ListTile(
                                    leading: const _IconTile(
                                        Icons.info_outline_rounded),
                                    title: const Text(
                                      'About GymGen AI',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: const Text(
                                      'Personalised fitness tracking and coaching',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                    onTap: _showAbout,
                                  ),
                                  const _Line(),
                                  const ListTile(
                                    leading: _IconTile(
                                        Icons.system_update_alt_rounded),
                                    title: Text(
                                      'App version',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: Text(
                                      '1.0.0',
                                      style: TextStyle(
                                        color:
                                            AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const _Line(),
                                  ListTile(
                                    leading: const _IconTile(
                                      Icons.logout_rounded,
                                      color: AppColors.error,
                                    ),
                                    title: const Text(
                                      'Sign out',
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: auth.loading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons
                                                .chevron_right_rounded,
                                            color: AppColors
                                                .textSecondary,
                                          ),
                                    onTap:
                                        auth.loading ? null : _confirmSignOut,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboard,
          textCapitalization: capitalization,
          validator: validator,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            prefixIcon: Icon(icon, color: AppColors.accent, size: 20),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );

  Widget _dropdown(
    String label,
    IconData icon,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
        child: DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            prefixIcon: Icon(icon, color: AppColors.accent, size: 20),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          items: options
              .map((item) =>
                  DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Choose $label' : null,
        ),
      );

  Future<void> _saveChanges(UserProfile current) async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null ||
        _goal == null ||
        _experience == null ||
        _equipment == null ||
        _diet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please complete all fitness preferences.')),
      );
      return;
    }

    final updated = current.copyWith(
      name: _name.text.trim(),
      age: int.parse(_age.text.trim()),
      heightCm: double.parse(_height.text.trim()),
      weightKg: double.parse(_weight.text.trim()),
      gender: _gender!,
      goal: _goal!,
      experience: _experience!,
      equipment: _equipment!,
      workoutDays: _days,
      dietPreference: _diet!,
    );
    final regenerateWorkout = current.goal != updated.goal ||
        current.experience != updated.experience ||
        current.equipment != updated.equipment ||
        current.workoutDays != updated.workoutDays;

    setState(() => _saving = true);
    try {
      await context.read<ProfileProvider>().updateProfile(updated);
      if (!mounted) return;

      if (regenerateWorkout) {
        final assessment = Assessment(
          age: updated.age,
          heightCm: updated.heightCm,
          weightKg: updated.weightKg,
          gender: updated.gender,
          goal: updated.goal,
          experience: updated.experience,
          equipment: updated.equipment,
          workoutDays: updated.workoutDays,
          dietPreference: updated.dietPreference,
          sleepHours: 7,
          injuries: '',
        );
        await context
            .read<WorkoutProvider>()
            .generatePlan(updated.uid, assessment);
      }
      if (!mounted) return;
      final saveError = context.read<ProfileProvider>().error;
      final planError = context.read<WorkoutProvider>().error;
      final message = saveError ??
          (regenerateWorkout && planError != null
              ? 'Profile saved, but workout plan refresh failed: $planError'
              : 'Changes saved. Your profile and personalised targets are updated.');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save changes: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text('Sign out?'),
        content:
            const Text('Your saved fitness data will remain on your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  void _showAbout() => showAboutDialog(
        context: context,
        applicationName: 'GymGen AI',
        applicationVersion: '1.0.0',
        applicationIcon: const Icon(
          Icons.fitness_center_rounded,
          color: AppColors.accent,
          size: 34,
        ),
        children: const [
          Text(
              'Personalised workout planning, nutrition tracking, progress insights, and AI fitness coaching.'),
        ],
      );
}

class _Hero extends StatelessWidget {
  final String name, email;
  const _Hero({required this.name, required this.email});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppGradients.hero,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.glow(AppColors.accent),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Make it yours',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$name${email.isEmpty ? '' : ' · $email'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.88),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your profile powers your personalised plan.',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Heading extends StatelessWidget {
  final String title, subtitle;
  const _Heading(this.title, this.subtitle);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border.withOpacity(.75)),
          boxShadow: AppShadows.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconTile(this.icon, {this.color = AppColors.accent});
  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(.09),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: color, size: 20),
      );
}

class _Line extends StatelessWidget {
  const _Line();
  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        color: AppColors.border.withOpacity(.6),
        indent: 16,
        endIndent: 16,
      );
}

class _Message extends StatelessWidget {
  final String message;
  final bool error;
  const _Message(this.message, {this.error = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (error ? AppColors.error : AppColors.success)
              .withOpacity(.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: error ? AppColors.error : AppColors.success,
            fontSize: 13,
          ),
        ),
      );
}

class _EmptyProfile extends StatelessWidget {
  final String? error;
  const _EmptyProfile({this.error});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_search_rounded,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              const Text(
                'Profile unavailable',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                error ?? 'Return to the dashboard and try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
}