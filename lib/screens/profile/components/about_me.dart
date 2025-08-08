import 'package:flutter/material.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme.dart';

class AboutMe extends StatelessWidget {
  const AboutMe({required this.bio, required this.username, super.key});

  final bio;
  final username;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[50], // Light subtle background
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ABOUT ME:',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 24),
              StyledHeading(username.isNotEmpty ? username : 'Username',
                  color: Colors.black54),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bio.isNotEmpty ? bio : 'No bio yet...',
            style: TextStyle(
              fontSize: 10,
              height: 1.4, // Better line spacing
              color: Colors.grey[800],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  // Optional: Expand to full bio view
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Center(
                        child: StyledTitleSmall('More About Me',
                            color: AppColors.textColor),
                      ),
                      content: SingleChildScrollView(
                        child:
                            StyledTextMedium(bio, color: AppColors.textColor),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child:
                              StyledText('Close', color: AppColors.textColor),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  'Read more',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
