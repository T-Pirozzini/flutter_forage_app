import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/screens/feedback/tabs/contact_tab.dart';
import 'package:flutter_forager_app/screens/feedback/tabs/feedback_tab.dart';
import 'package:flutter_forager_app/screens/feedback/tabs/roadmap_tab.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Redesigned Feedback & Support page with 3 tabs:
/// - Feedback: Public feature requests with likes/comments
/// - Contact Us: Private messaging to admin
/// - Roadmap: Timeline of completed/in-progress/planned features
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage>
    with SingleTickerProviderStateMixin {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  late TabController _tabController;
  String? _username;
  String? _userProfilePic;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(_currentUser.email)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          _username = userDoc.data()?['username'];
          _userProfilePic = userDoc.data()?['profilePic'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Compact header with support button
            _buildHeader(),
            // Tab bar
            _buildTabBar(),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  FeedbackTab(
                    username: _username,
                    userProfilePic: _userProfilePic,
                  ),
                  ContactTab(
                    username: _username,
                    userProfilePic: _userProfilePic,
                  ),
                  const RoadmapTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.primary.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Row(
        children: [
          // Icon and title
          Icon(Icons.eco, color: AppTheme.secondary, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Help Shape Forager\'s Future',
                  style: AppTheme.title(
                    size: 16,
                    color: AppTheme.textWhite,
                  ),
                ),
                Text(
                  'Your feedback drives our development',
                  style: AppTheme.caption(
                    size: 12,
                    color: AppTheme.textWhite.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          // Support button
          _buildSupportButton(),
        ],
      ),
    );
  }

  Widget _buildSupportButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _launchCoffeeLink,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.secondary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Support Us',
                style: AppTheme.caption(
                  size: 12,
                  weight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(width: 4),
              Text('☕', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surfaceLight,
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.primary,
              width: 3,
            ),
          ),
        ),
        labelStyle: AppTheme.body(
          size: 14,
          weight: FontWeight.w600,
        ),
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.textMedium,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(
            icon: Icon(Icons.lightbulb_outline, size: 20),
            text: 'Feedback',
            iconMargin: EdgeInsets.only(bottom: 4),
          ),
          Tab(
            icon: Icon(Icons.mail_outline, size: 20),
            text: 'Contact Us',
            iconMargin: EdgeInsets.only(bottom: 4),
          ),
          Tab(
            icon: Icon(Icons.timeline, size: 20),
            text: 'Roadmap',
            iconMargin: EdgeInsets.only(bottom: 4),
          ),
        ],
      ),
    );
  }

  Future<void> _launchCoffeeLink() async {
    final uri = Uri.parse('https://buymeacoffee.com/tpirozzini');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }
}
