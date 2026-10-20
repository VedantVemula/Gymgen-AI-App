import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymgen_ai/core/theme/app_colors.dart';
import 'package:gymgen_ai/core/theme/app_text_styles.dart';
import 'package:gymgen_ai/core/theme/app_theme.dart';
import 'package:gymgen_ai/core/widgets/animations.dart';
import 'package:gymgen_ai/models/assessment_model.dart';
import 'package:gymgen_ai/providers/workout_provider.dart';
import 'package:gymgen_ai/features/dashboard/dashboard_screen.dart';
import 'package:gymgen_ai/features/auth/presentation/screens/login_screen.dart';
import 'package:gymgen_ai/providers/assessment_provider.dart';
import 'package:gymgen_ai/providers/auth_provider.dart';

class AssessmentScreen extends StatefulWidget {
  static const routeName = '/assessment';

  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final sleepController = TextEditingController();
  final injuriesController = TextEditingController();
  String gender = '';
  String goal = '';
  String experience = '';
  String equipment = '';
  int workoutDays = 0;
  String dietPreference = '';

  @override
  void dispose() {
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    sleepController.dispose();
    injuriesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final assessment = Assessment(
      age: int.parse(ageController.text.trim()),
      heightCm: double.parse(heightController.text.trim()),
      weightKg: double.parse(weightController.text.trim()),
      gender: gender,
      goal: goal,
      experience: experience,
      equipment: equipment,
      workoutDays: workoutDays,
      dietPreference: dietPreference,
      sleepHours: int.parse(sleepController.text.trim()),
      injuries: injuriesController.text.trim(),
    );

    final auth = context.read<AuthProvider>();
    final provider = context.read<AssessmentProvider>();
    await provider.submitAssessment(
      assessment,
      auth.userId,
      name: auth.userName,
      email: auth.userEmail,
    );
    if (!mounted) return;

    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (provider.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assessment saved successfully.')),
      );
      final workoutProvider = context.read<WorkoutProvider>();
      await workoutProvider.generatePlan(auth.userId, assessment);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(DashboardScreen.routeName);
    }
  }

  Widget _buildNumberInput(
      String label, String hint, IconData icon, TextEditingController controller) {
    return _LabeledField(
      label: label,
      icon: icon,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Required';
          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    IconData icon,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return _LabeledField(
      label: label,
      icon: icon,
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: value.isEmpty ? null : value,
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          hint: const Text(
            'Choose',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          items: options
              .map((option) =>
                  DropdownMenuItem(value: option, child: Text(option)))
              .toList(),
          validator: (selected) => selected == null ? 'Required' : null,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to login',
          onPressed: () => Navigator.of(context)
              .pushReplacementNamed(LoginScreen.routeName),
        ),
        title: Text('Fitness assessment', style: AppTextStyles.heading3),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideIn(
                  child: _HeroBanner(),
                ),
                const SizedBox(height: 22),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: _SectionHeader(
                    title: 'Body metrics',
                    subtitle: 'Used to personalize your plan',
                    icon: Icons.monitor_heart_outlined,
                  ),
                ),
                const SizedBox(height: 10),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: _GroupCard(children: [
                    _buildNumberInput(
                      'Age',
                      'e.g. 25',
                      Icons.cake_outlined,
                      ageController,
                    ),
                    const _Line(),
                    _buildNumberInput(
                      'Height (cm)',
                      'e.g. 175',
                      Icons.height_rounded,
                      heightController,
                    ),
                    const _Line(),
                    _buildNumberInput(
                      'Weight (kg)',
                      'e.g. 72',
                      Icons.monitor_weight_outlined,
                      weightController,
                    ),
                    const _Line(),
                    _buildDropdown(
                      'Gender',
                      Icons.wc_outlined,
                      gender,
                      ['Male', 'Female', 'Other'],
                      (value) {
                        if (value != null) {
                          setState(() => gender = value);
                        }
                      },
                    ),
                  ]),
                ),
                const SizedBox(height: 22),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: _SectionHeader(
                    title: 'Fitness preferences',
                    subtitle: 'Shape your training program',
                    icon: Icons.flag_outlined,
                  ),
                ),
                const SizedBox(height: 10),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: _GroupCard(children: [
                    _buildDropdown(
                      'Goal',
                      Icons.flag_rounded,
                      goal,
                      [
                        'Build muscle',
                        'Lose fat',
                        'Improve endurance',
                        'Increase mobility'
                      ],
                      (value) {
                        if (value != null) {
                          setState(() => goal = value);
                        }
                      },
                    ),
                    const _Line(),
                    _buildDropdown(
                      'Experience',
                      Icons.trending_up_rounded,
                      experience,
                      ['Beginner', 'Intermediate', 'Advanced'],
                      (value) {
                        if (value != null) {
                          setState(() => experience = value);
                        }
                      },
                    ),
                    const _Line(),
                    _buildDropdown(
                      'Equipment',
                      Icons.fitness_center_rounded,
                      equipment,
                      [
                        'Gym access',
                        'Home equipment',
                        'Bodyweight only',
                        'No equipment'
                      ],
                      (value) {
                        if (value != null) {
                          setState(() => equipment = value);
                        }
                      },
                    ),
                    const _Line(),
                    _buildDropdown(
                      'Workout days',
                      Icons.calendar_month_rounded,
                      workoutDays == 0 ? '' : workoutDays.toString(),
                      ['3', '4', '5', '6'],
                      (value) {
                        if (value != null) {
                          setState(() => workoutDays = int.parse(value));
                        }
                      },
                    ),
                  ]),
                ),
                const SizedBox(height: 22),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 240),
                  child: _SectionHeader(
                    title: 'Lifestyle',
                    subtitle: 'Recovery and nutrition context',
                    icon: Icons.spa_outlined,
                  ),
                ),
                const SizedBox(height: 10),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 280),
                  child: _GroupCard(children: [
                    _buildDropdown(
                      'Diet preference',
                      Icons.restaurant_rounded,
                      dietPreference,
                      [
                        'Balanced',
                        'Low carb',
                        'High protein',
                        'Vegetarian'
                      ],
                      (value) {
                        if (value != null) {
                          setState(() => dietPreference = value);
                        }
                      },
                    ),
                    const _Line(),
                    _buildNumberInput(
                      'Sleep hours',
                      'e.g. 8',
                      Icons.bedtime_outlined,
                      sleepController,
                    ),
                    const _Line(),
                    _LabeledField(
                      label: 'Injuries / limitations',
                      icon: Icons.healing_outlined,
                      child: TextFormField(
                        controller: injuriesController,
                        minLines: 2,
                        maxLines: 4,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Optional',
                          hintStyle: TextStyle(
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 30),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 320),
                  child: SizedBox(
                    height: 58,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      decoration: BoxDecoration(
                        gradient: AppGradients.hero,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: provider.loading
                            ? []
                            : AppShadows.glow(AppColors.accent),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(100),
                          onTap: provider.loading ? null : _submit,
                          child: Center(
                            child: provider.loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Save & generate plan',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build your plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Complete your profile to unlock tailored training and nutrition.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final List<Widget> children;
  const _GroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(children: children),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accent, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();
  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        color: AppColors.border.withOpacity(0.6),
        indent: 60,
        endIndent: 16,
      );
}