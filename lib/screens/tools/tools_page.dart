import 'package:flutter/material.dart';
import 'package:flutter_forager_app/shared/screen_heading.dart';
import 'package:flutter_forager_app/screens/shellfish/shellfish_tracker_page.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// Tools page with grid of foraging tools
class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ScreenHeading(title: 'Tools'),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            color: AppTheme.primary.withValues(alpha: 0.1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StyledTextMedium(
                  'Helpful tools for your foraging adventures',
                  color: AppTheme.textDark,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
                children: [
                  _ToolCard(
                    icon: Icons.water_drop,
                    title: 'Shellfish Tracker',
                    description: 'Track your shellfish harvest with legal limits',
                    color: AppTheme.primary,
                    enabled: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShellfishTrackerPage(),
                        ),
                      );
                    },
                  ),
                  _ToolCard(
                    icon: Icons.eco,
                    title: 'Plant ID',
                    description: 'Identify plants and mushrooms',
                    color: AppTheme.success,
                    enabled: false,
                    onTap: null,
                  ),
                  _ToolCard(
                    icon: Icons.wb_sunny,
                    title: 'Weather',
                    description: 'Local foraging conditions',
                    color: AppTheme.secondary,
                    enabled: false,
                    onTap: null,
                  ),
                  _ToolCard(
                    icon: Icons.calendar_today,
                    title: 'Seasonal Guide',
                    description: 'What to forage each season',
                    color: AppTheme.accent,
                    enabled: false,
                    onTap: null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: enabled ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      color: enabled ? Colors.white : Colors.grey[100],
      child: InkWell(
        borderRadius: AppTheme.borderRadiusMedium,
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: AppTheme.borderRadiusMedium,
            border: enabled
                ? Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: enabled ? color.withValues(alpha: 0.1) : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: enabled ? color : Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTheme.title(
                  size: 14,
                  weight: FontWeight.bold,
                  color: enabled ? AppTheme.textDark : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTheme.caption(
                  size: 11,
                  color: enabled ? AppTheme.textMedium : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!enabled) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: AppTheme.caption(
                      size: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
