import 'package:flutter/material.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      appBar: AppBar(
        title: Text(
          'App Info',
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
            // Header with logo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primary,
                    AppTheme.primary.withValues(alpha: 0.8),
                    AppTheme.surfaceDark,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/forager_logo_3.png',
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to Forager!',
                    style: AppTheme.title(
                      size: 24,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your wild foraging companion',
                    style: AppTheme.caption(
                      size: 14,
                      color: AppTheme.textWhite.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Feature cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFeatureCard(
                    icon: Icons.explore,
                    title: 'Explore & Discover',
                    description:
                        'Our app fosters a deeper bond with nature, encouraging exploration and discovery of wild forageables. It\'s a platform for sharing findings, igniting adventure, and appreciating nature.',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    icon: Icons.map,
                    title: 'Interactive Map',
                    description:
                        'Our interactive map offers an exciting journey, tracking your path and revealing unique discoveries. Personalize markers, capture moments with photos, and save these special memories.',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    icon: Icons.people,
                    title: 'Connect with Others',
                    description:
                        'Link up with friends and explorers to share locations and uncover hidden gems, enhancing camaraderie and adventure.',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    icon: Icons.lock,
                    title: 'Privacy Controls',
                    description:
                        'Protect your discoveries while adding to the adventure. Choose to keep special spots private or share them with the community to inspire fellow nature lovers.',
                  ),
                  const SizedBox(height: 24),

                  // Community message
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.2),
                          AppTheme.secondary.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.forest,
                          size: 40,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Our goal is to create a community of nature enthusiasts who value sustainability, conservation, and the joy of unearthing hidden natural treasures.',
                          style: AppTheme.body(
                            size: 14,
                            color: AppTheme.textWhite,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'We hope you enjoy your journey with Forager!',
                          style: AppTheme.title(
                            size: 16,
                            color: AppTheme.secondary,
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

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textLight.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 24,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.body(
                    size: 16,
                    weight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: AppTheme.body(
                    size: 13,
                    color: AppTheme.textLight,
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
