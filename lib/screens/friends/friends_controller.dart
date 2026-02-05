import 'package:flutter/material.dart';
import 'package:flutter_forager_app/screens/friends/tabs/discover_tab.dart';
import 'package:flutter_forager_app/screens/friends/tabs/friends_tab.dart';
import 'package:flutter_forager_app/screens/friends/tabs/requests_tab.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';

/// Controller for the Friends feature with three tabs:
/// - My Friends: List of current friends with actions
/// - Requests: Incoming/outgoing friend requests and user search
/// - Discover: Find nearby foragers who are open to connecting
class FriendsController extends StatefulWidget {
  final int currentTab;
  const FriendsController({super.key, required this.currentTab});

  @override
  State<FriendsController> createState() => _FriendsControllerState();
}

class _FriendsControllerState extends State<FriendsController> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: widget.currentTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Friends',
            style: AppTheme.heading(size: 18, color: AppTheme.textWhite),
          ),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            // Safety tips button
            IconButton(
              icon: const Icon(Icons.security, color: Colors.white),
              tooltip: 'Safety Tips',
              onPressed: () => _showSafetyTipsDialog(context),
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppTheme.secondary,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: AppTheme.caption(size: 12, weight: FontWeight.w600),
            unselectedLabelStyle: AppTheme.caption(size: 12),
            tabs: const [
              Tab(text: 'My Friends', icon: Icon(Icons.people, size: 20)),
              Tab(text: 'Requests', icon: Icon(Icons.person_add, size: 20)),
              Tab(text: 'Discover', icon: Icon(Icons.explore, size: 20)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FriendsTab(),
            RequestsTab(),
            DiscoverTab(),
          ],
        ),
      ),
    );
  }

  void _showSafetyTipsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusMedium,
        ),
        title: Row(
          children: [
            Icon(Icons.security, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text('Foraging Safety Tips', style: AppTheme.title(size: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stay safe while connecting with other foragers:',
                style: AppTheme.body(size: 14, weight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _buildSafetyTipItem(
                Icons.location_on,
                'Meet in public first',
                'Choose a trailhead, parking lot, or public area for first meetups.',
              ),
              _buildSafetyTipItem(
                Icons.share_location,
                'Share your plans',
                'Tell someone where you\'re going and when you\'ll be back.',
              ),
              _buildSafetyTipItem(
                Icons.group,
                'Forage in groups',
                'There\'s safety in numbers. Consider group foraging trips.',
              ),
              _buildSafetyTipItem(
                Icons.psychology,
                'Trust your instincts',
                'If something feels off, leave. Your safety comes first.',
              ),
              _buildSafetyTipItem(
                Icons.phone,
                'Keep your phone charged',
                'Ensure you have a way to call for help if needed.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock, size: 16, color: AppTheme.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your precise locations are only shared with Trusted Foragers. Regular friends see approximate areas (~500m radius).',
                        style: AppTheme.caption(size: 12, color: AppTheme.info),
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
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!',
                style: AppTheme.button(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTipItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppTheme.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTheme.caption(size: 13, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(description, style: AppTheme.caption(size: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
