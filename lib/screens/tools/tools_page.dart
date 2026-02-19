import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/screens/shellfish/shellfish_tracker_page.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// Tools page with grid of foraging tools
class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  final _suggestionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _suggestionController.dispose();
    super.dispose();
  }

  Future<void> _submitSuggestion() async {
    final text = _suggestionController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('ToolSuggestions').add({
        'suggestion': text,
        'userId': user?.email ?? 'anonymous',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _suggestionController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Thanks for your suggestion!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to submit. Please try again.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryLight,
            AppTheme.primaryLight.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              color: AppTheme.primary.withValues(alpha: 0.08),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  _ToolCard(
                    icon: Icons.water_drop,
                    title: 'Shellfish Tracker',
                    description:
                        'Track your shellfish harvest with legal limits',
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
            // Suggest a tool section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.borderRadiusMedium,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline,
                              color: AppTheme.secondary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Suggest a Tool',
                            style: AppTheme.title(
                              size: 15,
                              weight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'What tool would make your foraging easier?',
                        style: AppTheme.caption(
                          size: 12,
                          color: AppTheme.textMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _suggestionController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 2,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'e.g. Tide chart, mushroom journal...',
                          hintStyle: TextStyle(
                            color: AppTheme.textMedium.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: AppTheme.primaryLight.withValues(alpha: 0.3),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: _isSubmitting
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(Icons.send_rounded,
                                      color: AppTheme.primary, size: 22),
                                  onPressed: _submitSuggestion,
                                ),
                        ),
                        onSubmitted: (_) => _submitSuggestion(),
                      ),
                    ],
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
                  color:
                      enabled ? color.withValues(alpha: 0.1) : Colors.grey[200],
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
