import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/shellfish.dart';
import 'package:flutter_forager_app/screens/shellfish/components/ruler_overlay.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// Shellfish collecting tracker for Nanaimo, BC
/// Allows users to track their shellfish harvest with counters for each species
class ShellfishTrackerPage extends StatefulWidget {
  const ShellfishTrackerPage({super.key});

  @override
  State<ShellfishTrackerPage> createState() => _ShellfishTrackerPageState();
}

class _ShellfishTrackerPageState extends State<ShellfishTrackerPage> {
  // Counter for each shellfish species (temporary, session-based)
  final Map<String, int> _counts = {};

  @override
  void initState() {
    super.initState();
    // Initialize counts to 0 for all species
    for (var species in NanaimoShellfish.species) {
      _counts[species.name] = 0;
    }
  }

  void _increment(String speciesName) {
    setState(() {
      _counts[speciesName] = (_counts[speciesName] ?? 0) + 1;
    });
  }

  void _decrement(String speciesName) {
    setState(() {
      final current = _counts[speciesName] ?? 0;
      if (current > 0) {
        _counts[speciesName] = current - 1;
      }
    });
  }

  void _resetAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
        title: Row(
          children: [
            Icon(Icons.restart_alt, color: AppTheme.accent),
            const SizedBox(width: AppTheme.space8),
            Text('Empty Bucket?', style: AppTheme.title(size: 16)),
          ],
        ),
        content: Text(
          'This will reset all your counts to zero. Are you sure?',
          style: AppTheme.body(size: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textMedium)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: AppTheme.textWhite,
            ),
            onPressed: () {
              setState(() {
                for (var key in _counts.keys) {
                  _counts[key] = 0;
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Bucket emptied! Ready for a new harvest.'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            child: const Text('Reset All'),
          ),
        ],
      ),
    );
  }

  void _showRuler() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RulerOverlay(),
        fullscreenDialog: true,
      ),
    );
  }

  int get _totalCount => _counts.values.fold(0, (sum, count) => sum + count);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Shellfish Tracker',
            style: AppTheme.heading(size: 20, color: AppTheme.textWhite),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.textWhite),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // Ruler button
            IconButton(
              icon: Icon(Icons.straighten, color: AppTheme.secondary),
              tooltip: 'Show Ruler',
              onPressed: _showRuler,
            ),
            // Reset all button
            IconButton(
              icon: Icon(Icons.restart_alt, color: AppTheme.accent),
              tooltip: 'Empty Bucket',
              onPressed: _totalCount > 0 ? _resetAll : null,
            ),
          ],
        ),
        body: Column(
          children: [
            // Header info card
            Container(
              margin: const EdgeInsets.all(AppTheme.space16),
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.2),
                borderRadius: AppTheme.borderRadiusMedium,
                border: Border.all(color: AppTheme.secondary, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_basket,
                          color: AppTheme.secondary, size: 28),
                      const SizedBox(width: AppTheme.space12),
                      Text(
                        'Today\'s Bucket',
                        style: AppTheme.heading(
                            size: 18, color: AppTheme.textWhite),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    '$_totalCount shellfish collected',
                    style: AppTheme.stats(size: 24, color: AppTheme.secondary),
                  ),
                  const SizedBox(height: AppTheme.space12),
                  Text(
                    'Nanaimo, BC • Valid BC License Required',
                    textAlign: TextAlign.center,
                    style: AppTheme.caption(
                        size: 11, color: AppTheme.textWhite.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),

            // Warning banner
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                borderRadius: AppTheme.borderRadiusSmall,
                border: Border.all(color: AppTheme.accent, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppTheme.accent, size: 20),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Text(
                      'Check DFO closures before harvesting. Sizes and limits enforced.',
                      style: AppTheme.caption(size: 11, color: AppTheme.textDark),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.space16),

            // Shellfish list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                itemCount: NanaimoShellfish.species.length,
                itemBuilder: (context, index) {
                  final species = NanaimoShellfish.species[index];
                  final count = _counts[species.name] ?? 0;
                  final isOverLimit = count > species.dailyLimit;

                  return Card(
                    margin:
                        const EdgeInsets.only(bottom: AppTheme.space12),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.borderRadiusMedium,
                      side: isOverLimit
                          ? BorderSide(color: AppTheme.error, width: 2)
                          : BorderSide.none,
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.space12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row with name and counter
                          Row(
                            children: [
                              // Icon
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.water_drop,
                                  color: AppTheme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppTheme.space12),

                              // Name and scientific name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      species.name,
                                      style: AppTheme.title(
                                          size: 16,
                                          weight: FontWeight.bold,
                                          color: AppTheme.textDark),
                                    ),
                                    Text(
                                      species.scientificName,
                                      style: AppTheme.caption(
                                          size: 11,
                                          color: AppTheme.textMedium),
                                    ),
                                  ],
                                ),
                              ),

                              // Counter controls
                              Container(
                                decoration: BoxDecoration(
                                  color: count > 0
                                      ? AppTheme.primary.withValues(alpha: 0.1)
                                      : AppTheme.backgroundLight,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.remove_circle_outline),
                                      color: count > 0
                                          ? AppTheme.primary
                                          : AppTheme.textMedium,
                                      onPressed:
                                          count > 0 ? () => _decrement(species.name) : null,
                                      constraints: const BoxConstraints(
                                          minWidth: 40, minHeight: 40),
                                    ),
                                    Container(
                                      constraints:
                                          const BoxConstraints(minWidth: 35),
                                      child: Text(
                                        '$count',
                                        textAlign: TextAlign.center,
                                        style: AppTheme.stats(
                                          size: 20,
                                          color: count > 0
                                              ? AppTheme.primary
                                              : AppTheme.textMedium,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add_circle_outline),
                                      color: AppTheme.primary,
                                      onPressed: () => _increment(species.name),
                                      constraints: const BoxConstraints(
                                          minWidth: 40, minHeight: 40),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppTheme.space12),

                          // Description
                          Text(
                            species.description,
                            style: AppTheme.body(
                                size: 13, color: AppTheme.textDark),
                          ),

                          const SizedBox(height: AppTheme.space12),

                          // Info chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildInfoChip(
                                icon: Icons.straighten,
                                label: 'Size',
                                value: '${species.minSize} - ${species.maxSize}',
                                color: AppTheme.primary,
                              ),
                              _buildInfoChip(
                                icon: Icons.rule,
                                label: 'Legal Min',
                                value: species.legalLimit,
                                color: AppTheme.accent,
                              ),
                              _buildInfoChip(
                                icon: Icons.shopping_basket_outlined,
                                label: 'Daily Limit',
                                value: '${species.dailyLimit}',
                                color: isOverLimit
                                    ? AppTheme.error
                                    : AppTheme.secondary,
                              ),
                              _buildInfoChip(
                                icon: Icons.calendar_today,
                                label: 'Season',
                                value: species.season,
                                color: AppTheme.success,
                              ),
                            ],
                          ),

                          // Over limit warning
                          if (isOverLimit)
                            Container(
                              margin: const EdgeInsets.only(top: AppTheme.space12),
                              padding: const EdgeInsets.all(AppTheme.space8),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.1),
                                borderRadius: AppTheme.borderRadiusSmall,
                                border: Border.all(color: AppTheme.error, width: 1),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning,
                                      color: AppTheme.error, size: 16),
                                  const SizedBox(width: AppTheme.space8),
                                  Expanded(
                                    child: Text(
                                      'Over daily limit! Release ${count - species.dailyLimit} shellfish.',
                                      style: AppTheme.caption(
                                          size: 11, color: AppTheme.error),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: AppTheme.caption(
                size: 11, weight: FontWeight.w600, color: AppTheme.textDark),
          ),
          Text(
            value,
            style: AppTheme.caption(size: 11, color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }
}
