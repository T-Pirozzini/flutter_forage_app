import 'package:flutter/material.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      appBar: AppBar(
        title: Text(
          'About Us',
          style: AppTheme.title(size: 20, color: AppTheme.textWhite),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.textWhite,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primary,
                    AppTheme.surfaceDark,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Meet the Team',
                    style: AppTheme.title(
                      size: 24,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The developers behind Forager',
                    style: AppTheme.caption(
                      size: 14,
                      color: AppTheme.textWhite.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Developer Cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Travis Card
                  _buildDeveloperCard(
                    name: 'Travis Pirozzini',
                    title: 'Full-Stack Developer',
                    subtitle: 'Mobile (Flutter) & Web (React)',
                    certifications: 'UI/UX Certified',
                    bio:
                        'Whether I\'m in the mountains, slaying an Ancient Blue Dragon with friends, or learning to code - I seek the challenge. Software Development is a continuous journey that allows me to bring my dreams to life through dedication and creative solutions... and I\'m just getting started.',
                    imagePath: 'lib/assets/images/travis_about.jpg',
                    imageAlignment: const Alignment(0, 0.4),
                    links: [
                      _SocialLink(
                        icon: FontAwesomeIcons.globe,
                        label: 'Portfolio',
                        url: 'https://portfolio-2023-1a61.fly.dev/',
                      ),
                      _SocialLink(
                        icon: FontAwesomeIcons.linkedin,
                        label: 'LinkedIn',
                        url:
                            'https://www.linkedin.com/in/travis-pirozzini-2522b5115/',
                      ),
                      _SocialLink(
                        icon: FontAwesomeIcons.github,
                        label: 'GitHub',
                        url: 'https://github.com/T-Pirozzini',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Richard Card
                  _buildDeveloperCard(
                    name: 'Richard Au',
                    title: 'Full-Stack Developer',
                    subtitle: 'Mobile & Software Development',
                    bio:
                        'Whether I\'m on the basketball court, coding at my desk, or cooking in the kitchen, I\'m always looking to experiment with new ideas. I love blending two entirely different industries together and testing what the outcome would be.\n\nBy learning software development and combining my previous knowledge in social sciences and psychology, I aim to bridge the gap between individuals and mental health clinics to be more easily accessible.',
                    imagePath: 'lib/assets/images/richard_about.jpg',
                    imageAlignment: const Alignment(0, 0.3),
                    links: [
                      _SocialLink(
                        icon: FontAwesomeIcons.linkedin,
                        label: 'LinkedIn',
                        url: 'https://www.linkedin.com/in/aurichard4/',
                      ),
                      _SocialLink(
                        icon: FontAwesomeIcons.github,
                        label: 'GitHub',
                        url: 'https://github.com/au-richard',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Contact section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 32,
                          color: AppTheme.secondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Open to Opportunities',
                          style: AppTheme.title(
                            size: 16,
                            color: AppTheme.textWhite,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We\'re currently open to employment opportunities (contract, full-time, or part-time). Please reach out if you\'re interested in working together!',
                          style: AppTheme.body(
                            size: 13,
                            color: AppTheme.textLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperCard({
    required String name,
    required String title,
    String? subtitle,
    String? certifications,
    required String bio,
    required String imagePath,
    Alignment imageAlignment = Alignment.center,
    required List<_SocialLink> links,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textLight.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Image with gradient overlay
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                Image.asset(
                  imagePath,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  alignment: imageAlignment,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: AppTheme.textLight,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.backgroundDark.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTheme.title(
                          size: 22,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: AppTheme.body(
                          size: 14,
                          weight: FontWeight.w600,
                          color: AppTheme.secondary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        Text(
                          subtitle,
                          style: AppTheme.caption(
                            size: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (certifications != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      certifications,
                      style: AppTheme.caption(
                        size: 11,
                        color: AppTheme.primary,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  bio,
                  style: AppTheme.body(
                    size: 13,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 16),

                // Social links
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: links.map((link) {
                    return InkWell(
                      onTap: () => _launchUrl(link.url),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.textLight.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              link.icon,
                              size: 14,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              link.label,
                              style: AppTheme.caption(
                                size: 12,
                                color: AppTheme.textWhite,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialLink {
  final IconData icon;
  final String label;
  final String url;

  const _SocialLink({
    required this.icon,
    required this.label,
    required this.url,
  });
}
