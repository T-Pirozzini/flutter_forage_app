import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/onboarding_page_model.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// Onboarding screen that introduces new users to the app
///
/// Displays a series of pages explaining key features.
/// Can be used both for first-time onboarding and as a tutorial.
class OnboardingScreen extends StatefulWidget {
  /// Whether this is being shown as a tutorial (can be dismissed)
  final bool isTutorial;

  /// Callback when onboarding is completed
  final VoidCallback? onComplete;

  const OnboardingScreen({
    Key? key,
    this.isTutorial = false,
    this.onComplete,
  }) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < OnboardingContent.pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() {
    _complete();
  }

  void _complete() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else if (widget.isTutorial) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == OnboardingContent.pages.length - 1;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with skip/close button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.isTutorial)
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            color: AppTheme.textWhite,
                            fontSize: 16,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 80),
                    Text(
                      widget.isTutorial ? 'Tutorial' : 'Welcome',
                      style: TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (!isLastPage && !widget.isTutorial)
                      TextButton(
                        onPressed: _skip,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 80),
                  ],
                ),
              ),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: OnboardingContent.pages.length,
                  itemBuilder: (context, index) {
                    return _OnboardingPage(
                      page: OnboardingContent.pages[index],
                    );
                  },
                ),
              ),

              // Page indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    OnboardingContent.pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 32 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppTheme.secondary
                            : AppTheme.textWhite.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    if (_currentPage > 0)
                      TextButton.icon(
                        onPressed: _previousPage,
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppTheme.textWhite,
                        ),
                        label: Text(
                          'Back',
                          style: TextStyle(
                            color: AppTheme.textWhite,
                            fontSize: 16,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 100),

                    // Next/Get Started button
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: AppTheme.textWhite,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isLastPage ? 'Get Started' : 'Next',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLastPage ? Icons.check : Icons.arrow_forward,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual onboarding page widget
class _OnboardingPage extends StatelessWidget {
  final OnboardingPageModel page;

  const _OnboardingPage({
    Key? key,
    required this.page,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image/Icon placeholder
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.secondary.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                _getIconForPage(),
                size: 100,
                color: AppTheme.secondary,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textWhite.withValues(alpha: 0.9),
              fontSize: 16,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // Features list
          ...page.features.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.success,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  IconData _getIconForPage() {
    // Map page titles to icons
    switch (page.title) {
      case 'Discover Wild Foods':
        return Icons.map;
      case 'Connect with Foragers':
        return Icons.people;
      case 'Cook & Share Recipes':
        return Icons.restaurant_menu;
      case 'Foraging Tools':
        return Icons.build_outlined;
      case 'Forage Together':
        return Icons.group_add;
      case 'Track Your Progress':
        return Icons.trending_up;
      case 'Safety First':
        return Icons.health_and_safety;
      default:
        return Icons.info;
    }
  }
}
