/// Model representing a single onboarding page
class OnboardingPageModel {
  final String title;
  final String description;
  final String imagePath;
  final List<String> features;

  const OnboardingPageModel({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.features,
  });
}

/// Onboarding content for the app
class OnboardingContent {
  static const List<OnboardingPageModel> pages = [
    OnboardingPageModel(
      title: 'Discover Wild Foods',
      description:
          'Find and map wild edibles, mushrooms, berries, and herbs in your area.',
      imagePath: 'assets/onboarding/discover.png',
      features: [
        'Pin locations on interactive map',
        'Add photos and detailed notes',
        'Track seasonal availability',
      ],
    ),
    OnboardingPageModel(
      title: 'Connect with Foragers',
      description:
          'Join a community of foragers sharing knowledge and discoveries.',
      imagePath: 'assets/onboarding/community.png',
      features: [
        'Share your findings with friends',
        'Comment on community posts',
        'Learn from experienced foragers',
      ],
    ),
    OnboardingPageModel(
      title: 'Cook & Share Recipes',
      description:
          'Turn your foraged ingredients into delicious meals and share recipes.',
      imagePath: 'assets/onboarding/recipes.png',
      features: [
        'Browse wild food recipes',
        'Create your own recipe collection',
        'Share cooking tips and techniques',
      ],
    ),
    OnboardingPageModel(
      title: 'Foraging Tools',
      description:
          'Use built-in tools to help track and manage your foraging sessions.',
      imagePath: 'assets/onboarding/tools.png',
      features: [
        'Shellfish tracker for tide-based foraging',
        'Filter markers by type on the map',
        'Switch between terrain and satellite views',
      ],
    ),
    OnboardingPageModel(
      title: 'Forage Together',
      description:
          'Find nearby foragers and safely connect for group outings.',
      imagePath: 'assets/onboarding/forage_together.png',
      features: [
        'Discover foragers open to meetups',
        'Send forage requests with a short intro',
        'Designate emergency contacts for safety',
      ],
    ),
    OnboardingPageModel(
      title: 'Track Your Progress',
      description:
          'Monitor your foraging journey with streaks, achievements, and levels.',
      imagePath: 'assets/onboarding/progress.png',
      features: [
        'Earn points for discoveries',
        'Unlock achievements',
        'Compete on leaderboards',
      ],
    ),
    OnboardingPageModel(
      title: 'Safety First',
      description:
          'Always verify identification before consuming any wild foods.',
      imagePath: 'assets/onboarding/safety.png',
      features: [
        'Cross-reference with field guides',
        'Consult experienced foragers',
        'When in doubt, throw it out!',
      ],
    ),
  ];
}
