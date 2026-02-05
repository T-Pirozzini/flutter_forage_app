import 'package:flutter/material.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// Dialog for sharing contact information after a forage request is accepted.
///
/// Allows the user to select their preferred contact method and enter their info.
class ContactExchangeDialog extends StatefulWidget {
  const ContactExchangeDialog({super.key});

  @override
  State<ContactExchangeDialog> createState() => _ContactExchangeDialogState();
}

class _ContactExchangeDialogState extends State<ContactExchangeDialog> {
  String _selectedMethod = 'email';
  final TextEditingController _infoController = TextEditingController();

  static const List<_ContactMethod> _methods = [
    _ContactMethod('email', 'Email', Icons.email, Color(0xFF4285F4)),
    _ContactMethod('facebook', 'Facebook', Icons.facebook, Color(0xFF1877F2)),
    _ContactMethod('discord', 'Discord', Icons.chat, Color(0xFF5865F2)),
    _ContactMethod('phone', 'Phone', Icons.phone, Color(0xFF34A853)),
    _ContactMethod('other', 'Other', Icons.link, Colors.grey),
  ];

  @override
  void dispose() {
    _infoController.dispose();
    super.dispose();
  }

  String _getHintText() {
    switch (_selectedMethod) {
      case 'email':
        return 'your.email@example.com';
      case 'facebook':
        return 'facebook.com/yourprofile';
      case 'discord':
        return 'YourUsername#1234';
      case 'phone':
        return '+1 (555) 123-4567';
      default:
        return 'Enter your contact info';
    }
  }

  String _getLabelText() {
    switch (_selectedMethod) {
      case 'email':
        return 'Email address';
      case 'facebook':
        return 'Facebook profile URL or username';
      case 'discord':
        return 'Discord username';
      case 'phone':
        return 'Phone number';
      default:
        return 'Contact info';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      title: Row(
        children: [
          Icon(Icons.share, color: AppTheme.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Share Contact Info',
              style: AppTheme.title(size: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How would you like to connect?',
              style: AppTheme.body(size: 14),
            ),

            const SizedBox(height: 16),

            // Contact method selection
            Text(
              'Select platform',
              style: AppTheme.caption(size: 12, color: AppTheme.textMedium),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _methods.map((method) {
                final isSelected = _selectedMethod == method.id;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMethod = method.id;
                      _infoController.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? method.color.withValues(alpha: 0.15)
                          : AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? method.color
                            : AppTheme.textMedium.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          method.icon,
                          size: 18,
                          color: isSelected ? method.color : AppTheme.textMedium,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          method.label,
                          style: AppTheme.caption(
                            size: 13,
                            weight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? method.color : AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Contact info input
            Text(
              _getLabelText(),
              style: AppTheme.caption(size: 12, color: AppTheme.textMedium),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _infoController,
              decoration: InputDecoration(
                hintText: _getHintText(),
                hintStyle: AppTheme.body(
                  size: 14,
                  color: AppTheme.textMedium.withValues(alpha: 0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(
                  _methods.firstWhere((m) => m.id == _selectedMethod).icon,
                  color: _methods.firstWhere((m) => m.id == _selectedMethod).color,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            // Safety note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security, size: 16, color: AppTheme.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only share contact info you\'re comfortable with. Remember to meet in public for first meetups.',
                      style: AppTheme.caption(size: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('Cancel', style: AppTheme.body(color: AppTheme.textMedium)),
        ),
        ElevatedButton(
          onPressed: _infoController.text.trim().isEmpty
              ? null
              : () {
                  Navigator.of(context).pop({
                    'method': _selectedMethod,
                    'info': _infoController.text.trim(),
                  });
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
            foregroundColor: Colors.white,
          ),
          child: const Text('Share'),
        ),
      ],
    );
  }
}

class _ContactMethod {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const _ContactMethod(this.id, this.label, this.icon, this.color);
}
