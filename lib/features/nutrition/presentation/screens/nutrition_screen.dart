import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymgen_ai/core/theme/app_colors.dart';
import 'package:gymgen_ai/core/theme/app_theme.dart';
import 'package:gymgen_ai/core/widgets/app_widgets.dart';
import 'package:gymgen_ai/core/widgets/animations.dart';
import 'package:gymgen_ai/providers/nutrition_provider.dart';
import 'package:gymgen_ai/models/nutrition_models.dart';

class NutritionScreen extends StatelessWidget {
  static const routeName = '/nutrition';

  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nutrition = context.watch<NutritionProvider>();
    final today = nutrition.today;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Nutrition',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddFoodSheet(context),
            icon: const Icon(Icons.add_rounded, color: AppColors.accent),
            tooltip: 'Log food',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideIn(child: _CalorieHero(today: today)),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: _MacrosCard(today: today),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: _WaterCard(
                    today: today,
                    onAdd: (litres) => nutrition.addWater(litres),
                  ),
                ),
                const SizedBox(height: 22),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: SectionTitle(
                    title: "Today's Food Log",
                    action: '+ Add',
                    onAction: () => _showAddFoodSheet(context),
                  ),
                ),
                const SizedBox(height: 12),
                if (today.entries.isEmpty)
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 240),
                    child: const _EmptyLog(),
                  )
                else
                  ..._groupEntriesByMeal(today.entries).entries.map((group) {
                    return FadeSlideIn(
                      delay: const Duration(milliseconds: 240),
                      child: _MealGroup(
                        mealType: group.key,
                        entries: group.value,
                        onDelete: (id) => nutrition.removeEntry(id),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFoodSheet(context),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add),
        label: const Text(
          'Log Food',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Map<String, List<NutritionEntry>> _groupEntriesByMeal(
      List<NutritionEntry> entries) {
    final Map<String, List<NutritionEntry>> grouped = {};
    for (final e in entries) {
      grouped.putIfAbsent(e.mealType, () => []).add(e);
    }
    return grouped;
  }

  void _showAddFoodSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddFoodSheet(),
    );
  }
}

class _CalorieHero extends StatelessWidget {
  final DailyNutrition today;
  const _CalorieHero({required this.today});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppShadows.glow(AppColors.accent),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daily Calories',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  AnimatedRing(
                    progress: today.calorieProgress,
                    size: 130,
                    stroke: 12,
                    color: Colors.white,
                    background: Colors.white.withOpacity(0.2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedCounter(
                          value: today.totalCalories,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'kcal eaten',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      children: [
                        _CalStat(
                          label: 'Goal',
                          value: '${today.targetCalories}',
                          icon: Icons.flag_rounded,
                        ),
                        const SizedBox(height: 10),
                        _CalStat(
                          label: 'Remaining',
                          value: '${today.remainingCalories}',
                          icon: Icons.bolt_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CalStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacrosCard extends StatelessWidget {
  final DailyNutrition today;
  const _MacrosCard({required this.today});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pie_chart_outline_rounded,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Macronutrients',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MacroProgressRow(
            label: 'Protein',
            value:
                '${today.totalProtein.toStringAsFixed(0)}g / ${today.targetProtein.toStringAsFixed(0)}g',
            progress: today.proteinProgress,
            color: AppColors.success,
          ),
          MacroProgressRow(
            label: 'Carbohydrates',
            value:
                '${today.totalCarbs.toStringAsFixed(0)}g / ${today.targetCarbs.toStringAsFixed(0)}g',
            progress: today.carbsProgress,
            color: AppColors.accent,
          ),
          MacroProgressRow(
            label: 'Fats',
            value:
                '${today.totalFat.toStringAsFixed(0)}g / ${today.targetFat.toStringAsFixed(0)}g',
            progress: today.fatProgress,
            color: const Color(0xFFFF9A3D),
          ),
        ],
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  final DailyNutrition today;
  final ValueChanged<double> onAdd;

  const _WaterCard({required this.today, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.water_drop_rounded,
                color: Color(0xFF4A9BFF),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Water Intake',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${today.waterLitres.toStringAsFixed(1)} / ${today.targetWaterLitres.toStringAsFixed(1)} L',
                style: const TextStyle(
                  color: Color(0xFF4A9BFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: today.waterProgress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 10,
                backgroundColor: const Color(0xFFE8EDF5),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF4A9BFF),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _WaterButton(label: '+250ml', onTap: () => onAdd(0.25)),
              const SizedBox(width: 10),
              _WaterButton(label: '+500ml', onTap: () => onAdd(0.5)),
              const SizedBox(width: 10),
              _WaterButton(label: '+1L', onTap: () => onAdd(1.0)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _WaterButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BouncyTap(
        onTap: onTap,
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF4A9BFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF4A9BFF),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyLog extends StatelessWidget {
  const _EmptyLog();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: const Column(
        children: [
          Icon(Icons.restaurant_menu_rounded,
              color: AppColors.textSecondary, size: 42),
          SizedBox(height: 10),
          Text(
            'No food logged yet today.\nTap + Add to log your meals.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealGroup extends StatelessWidget {
  final String mealType;
  final List<NutritionEntry> entries;
  final Function(String) onDelete;

  const _MealGroup({
    required this.mealType,
    required this.entries,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final totalCals = entries.fold(0, (sum, e) => sum + e.calories);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                mealType,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$totalCals kcal',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        ...entries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'P: ${entry.protein.toStringAsFixed(0)}g  C: ${entry.carbs.toStringAsFixed(0)}g  F: ${entry.fat.toStringAsFixed(0)}g',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${entry.calories}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textSecondary),
                  onPressed: () => onDelete(entry.id),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Add Food Bottom Sheet ─────────────────────────────────────────────────────

class _AddFoodSheet extends StatefulWidget {
  const _AddFoodSheet();

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  String _mealType = 'Breakfast';

  final _quickFoods = [
    {'name': 'Grilled Chicken (100g)', 'cal': 165, 'p': 31.0, 'c': 0.0, 'f': 3.6},
    {'name': 'Brown Rice (1 cup)', 'cal': 216, 'p': 5.0, 'c': 45.0, 'f': 1.8},
    {'name': 'Banana', 'cal': 89, 'p': 1.1, 'c': 23.0, 'f': 0.3},
    {'name': 'Egg (1 large)', 'cal': 78, 'p': 6.0, 'c': 0.6, 'f': 5.0},
    {'name': 'Greek Yogurt (150g)', 'cal': 100, 'p': 10.0, 'c': 6.0, 'f': 3.5},
    {'name': 'Oats (100g)', 'cal': 389, 'p': 17.0, 'c': 66.0, 'f': 7.0},
    {'name': 'Salmon (100g)', 'cal': 208, 'p': 20.0, 'c': 0.0, 'f': 13.0},
    {'name': 'Sweet Potato (100g)', 'cal': 86, 'p': 1.6, 'c': 20.0, 'f': 0.1},
    {'name': 'Almonds (30g)', 'cal': 174, 'p': 6.0, 'c': 6.0, 'f': 15.0},
    {'name': 'Protein Shake', 'cal': 120, 'p': 25.0, 'c': 5.0, 'f': 2.0},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _fillQuickFood(Map<String, dynamic> food) {
    _nameController.text = food['name'] as String;
    _caloriesController.text = food['cal'].toString();
    _proteinController.text = food['p'].toString();
    _carbsController.text = food['c'].toString();
    _fatController.text = food['f'].toString();
    setState(() {});
  }

  Future<void> _add() async {
    if (_nameController.text.isEmpty || _caloriesController.text.isEmpty) {
      return;
    }

    final entry = NutritionEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      calories: int.tryParse(_caloriesController.text) ?? 0,
      protein: double.tryParse(_proteinController.text) ?? 0,
      carbs: double.tryParse(_carbsController.text) ?? 0,
      fat: double.tryParse(_fatController.text) ?? 0,
      mealType: _mealType,
      time: DateTime.now(),
    );

    await context.read<NutritionProvider>().addEntry(entry);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Log Food',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Quick Add',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickFoods.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final food = _quickFoods[i];
                  return BouncyTap(
                    onTap: () => _fillQuickFood(food),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Center(
                        child: Text(
                          food['name'] as String,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _mealType,
              decoration: const InputDecoration(labelText: 'Meal Type'),
              items: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _mealType = v ?? 'Snack'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Food Name',
                hintText: 'e.g. Chicken Breast',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Calories (kcal)',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _proteinController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Protein (g)'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _carbsController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Carbs (g)'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _fatController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Fat (g)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppGradients.hero,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: AppShadows.glow(AppColors.accent),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: _add,
                    child: const Center(
                      child: Text(
                        'Add to Log',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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