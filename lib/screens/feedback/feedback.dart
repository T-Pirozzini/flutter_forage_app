import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/components/ad_mob_service.dart';
import 'package:flutter_forager_app/components/screen_heading.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage>
    with SingleTickerProviderStateMixin {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  final _feedbackController = TextEditingController();
  final _messageController = TextEditingController();
  final _progressController = TextEditingController();
  final _timeFormat = DateFormat('MMM d, yyyy h:mm a');

  int currentUserCount = 0;
  String? _username;
  String? _userProfilePic;
  late TabController _tabController;

  static const String _ownerEmail = 'travis@forager.com';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUserData();
    _fetchCurrentUserCount();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _feedbackController.dispose();
    _messageController.dispose();
    _progressController.dispose();
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

  Future<void> _fetchCurrentUserCount() async {
    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('Users').get();
      if (mounted) {
        setState(() {
          currentUserCount = usersSnapshot.docs.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user count: $e');
    }
  }

  Future<DocumentReference> _submitData(SubmissionConfig config) async {
    final text = config.controller.text.trim();
    if (text.isEmpty)
      return FirebaseFirestore.instance.collection(config.collection).doc();

    try {
      final docRef =
          await FirebaseFirestore.instance.collection(config.collection).add({
        'userId': _currentUser.uid,
        'userEmail': _currentUser.email!,
        'username': _username ?? _currentUser.email!.split('@')[0],
        'profilePic': _userProfilePic ?? '',
        config.field: text,
        'timestamp': FieldValue.serverTimestamp(),
        if (config.collection == 'Feedback') ...{
          'likes': 0,
          'likedBy': <String>[],
          'comments': <Map<String, dynamic>>[],
        },
      });

      config.controller.clear();
      if (mounted) {
        _showSnackBar(config.successMessage);
      }
      return docRef;
    } catch (e) {
      if (mounted) {
        _showSnackBar('${config.errorMessage}: $e');
      }
      return FirebaseFirestore.instance.collection(config.collection).doc();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              const ScreenHeading(title: 'Feedback'),
              _IntroSection(
                  onSupportPressed: () =>
                      _showSnackBar('Buy Me a Coffee link coming soon!'),
                  currentUserCount: currentUserCount),
              _CustomTabBar(controller: _tabController),
              _TabContent(
                tabController: _tabController,
                feedbackController: _feedbackController,
                messageController: _messageController,
                progressController: _progressController,
                userProfilePic: _userProfilePic,
                timeFormat: _timeFormat,
                onFeedbackSubmit: () =>
                    _submitData(SubmissionConfig.feedback(_feedbackController)),
                onMessageSubmit: () =>
                    _submitData(SubmissionConfig.message(_messageController)),
                onProgressSubmit: () =>
                    _submitData(SubmissionConfig.progress(_progressController)),
                isOwner: _currentUser.email == _ownerEmail,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubmissionConfig {
  final String collection;
  final String field;
  final TextEditingController controller;
  final String successMessage;
  final String errorMessage;

  const SubmissionConfig({
    required this.collection,
    required this.field,
    required this.controller,
    required this.successMessage,
    required this.errorMessage,
  });

  factory SubmissionConfig.feedback(TextEditingController controller) {
    return SubmissionConfig(
      collection: 'Feedback',
      field: 'feedback',
      controller: controller,
      successMessage: 'Feedback submitted successfully!',
      errorMessage: 'Failed to submit feedback',
    );
  }

  factory SubmissionConfig.message(TextEditingController controller) {
    return SubmissionConfig(
      collection: 'Messages',
      field: 'message',
      controller: controller,
      successMessage: 'Message posted successfully!',
      errorMessage: 'Failed to post message',
    );
  }

  factory SubmissionConfig.progress(TextEditingController controller) {
    return SubmissionConfig(
      collection: 'Progress',
      field: 'item',
      controller: controller,
      successMessage: 'Progress item added successfully!',
      errorMessage: 'Failed to add progress item',
    );
  }
}

class _IntroSection extends StatefulWidget {
  final VoidCallback onSupportPressed;
  final int currentUserCount;

  const _IntroSection(
      {required this.onSupportPressed, required this.currentUserCount});

  @override
  State<_IntroSection> createState() => _IntroSectionState();
}

class _IntroSectionState extends State<_IntroSection> {
  bool _isExpanded = false;
  final Uri buyMeACoffeeLink = Uri.parse('https://buymeacoffee.com/tpirozzini');

  Future<void> _launchURL() async {
    if (await canLaunchUrl(buyMeACoffeeLink)) {
      await launchUrl(buyMeACoffeeLink);
    } else {
      throw 'Could not launch $buyMeACoffeeLink';
    }
  }

  Future<void> _watchInterstitialAd() async {
    if (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      AdMobService.showInterstitialAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.titleBarColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: StyledHeadingSmall('Welcome Back to Forager!',
                color: AppColors.textColor),
          ),
          const SizedBox(height: 8),
          StyledTextSmall(
              "I'm sorry! Our foraging community is growing rapidly, but we haven't pulled our weight.",
              color: AppColors.textColor),
          const SizedBox(height: 8),
          StyledTextSmall('Current User Count: ${widget.currentUserCount}',
              color: AppColors.textColor.withOpacity(0.8)),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.secondaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppColors.secondaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StyledTextSmall(
                            'Our commitment to the improvement of Forager:',
                            color: AppColors.secondaryColor,
                          ),
                        ),
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.secondaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isExpanded ? null : 0,
                  child: _isExpanded
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(
                                color:
                                    AppColors.secondaryColor.withOpacity(0.3),
                                height: 1,
                              ),
                              const SizedBox(height: 12),
                              StyledTextSmall(
                                "I sincerely apologize for the lack of updates—life got in the way, but I'm back and committed to this vision. "
                                "I want to create something special: an app where we can forage together, share discoveries, and build a community that makes the world a little better.",
                                color: AppColors.textColor.withOpacity(0.9),
                              ),
                              const SizedBox(height: 8),
                              StyledTextSmall(
                                "Here's what I need from you:",
                                color: AppColors.secondaryColor,
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    StyledTextSmall(
                                      "• Share your ideas and feedback below—I'll implement them!",
                                      color:
                                          AppColors.textColor.withOpacity(0.9),
                                    ),
                                    const SizedBox(height: 2),
                                    StyledTextSmall(
                                      "• Help grow our community by sharing locations and finds",
                                      color:
                                          AppColors.textColor.withOpacity(0.9),
                                    ),
                                    const SizedBox(height: 2),
                                    StyledTextSmall(
                                      "• Post photos of meals made from your foraged discoveries",
                                      color:
                                          AppColors.textColor.withOpacity(0.9),
                                    ),
                                    const SizedBox(height: 2),
                                    StyledTextSmall(
                                      "• Engage with and support fellow foragers",
                                      color:
                                          AppColors.textColor.withOpacity(0.9),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.secondaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: StyledTextSmall(
                                  "Note: Support the future of this application with feedback, engagement, watching ads or treating us to a coffee.",
                                  color: AppColors.textColor.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: ElevatedButton.icon(
                                        onPressed: _launchURL,
                                        label: StyledTextMedium(
                                            'Buy us a coffee ☕'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.textColor
                                              .withOpacity(0.9),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FittedBox(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: ElevatedButton.icon(
                                        onPressed: _watchInterstitialAd,
                                        label:
                                            StyledTextMedium('Watch an Ad 📺'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.textColor
                                              .withOpacity(0.9),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomTabBar extends StatelessWidget {
  final TabController controller;

  const _CustomTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppColors.secondaryColor,
        ),
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        labelColor: AppColors.textColor,
        unselectedLabelColor: AppColors.secondaryColor.withOpacity(0.7),
        indicatorSize: TabBarIndicatorSize.tab,
        splashFactory: InkRipple.splashFactory,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        tabs: const [
          Tab(text: 'Feedback'),
          Tab(text: 'Community'),
          Tab(text: 'In Progress')
        ],
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  final TabController tabController;
  final TextEditingController feedbackController;
  final TextEditingController messageController;
  final TextEditingController progressController;
  final String? userProfilePic;
  final DateFormat timeFormat;
  final VoidCallback onFeedbackSubmit;
  final VoidCallback onMessageSubmit;
  final VoidCallback onProgressSubmit;
  final bool isOwner;

  const _TabContent({
    required this.tabController,
    required this.feedbackController,
    required this.messageController,
    required this.progressController,
    required this.userProfilePic,
    required this.timeFormat,
    required this.onFeedbackSubmit,
    required this.onMessageSubmit,
    required this.onProgressSubmit,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Estimate height for non-TabBarView content (ScreenHeading, IntroSection, TabBar)
        final reservedHeight = 250.0; // Adjust based on your layout
        final tabBarViewHeight =
            MediaQuery.of(context).size.height - reservedHeight;
        return SizedBox(
          height:
              tabBarViewHeight > 0 ? tabBarViewHeight : 400, // Fallback height
          child: TabBarView(
            controller: tabController,
            children: [
              _FeedbackTab(
                controller: feedbackController,
                userProfilePic: userProfilePic,
                timeFormat: timeFormat,
                onSubmit: onFeedbackSubmit,
              ),
              _MessagesTab(
                controller: messageController,
                userProfilePic: userProfilePic,
                timeFormat: timeFormat,
                onSubmit: onMessageSubmit,
              ),
              _ProgressTab(
                controller: progressController,
                userProfilePic: userProfilePic,
                timeFormat: timeFormat,
                onSubmit: onProgressSubmit,
                isOwner: isOwner,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeedbackTab extends StatelessWidget {
  final TextEditingController controller;
  final String? userProfilePic;
  final DateFormat timeFormat;
  final VoidCallback onSubmit;

  const _FeedbackTab({
    required this.controller,
    required this.userProfilePic,
    required this.timeFormat,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _InputSection(
            title: 'Share Your Feedback',
            hint: 'What features would you like to see?',
            controller: controller,
            userProfilePic: userProfilePic,
            onSubmit: onSubmit,
            buttonText: 'Submit Feedback',
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          _StreamContent<FeedbackItem>(
            collection: 'Feedback',
            itemBuilder: (data) =>
                FeedbackItem(data: data, timeFormat: timeFormat),
            emptyMessage: 'No feedback yet. Be the first to share!',
          ),
          const SizedBox(height: 200),
        ],
      ),
    );
  }
}

class _MessagesTab extends StatelessWidget {
  final TextEditingController controller;
  final String? userProfilePic;
  final DateFormat timeFormat;
  final VoidCallback onSubmit;

  const _MessagesTab({
    required this.controller,
    required this.userProfilePic,
    required this.timeFormat,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _InputSection(
            title: 'Community Message Board',
            hint: 'Post a message to the community...',
            controller: controller,
            userProfilePic: userProfilePic,
            onSubmit: onSubmit,
            buttonText: 'Post Message',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _StreamContent<MessageItem>(
            collection: 'Messages',
            itemBuilder: (data) =>
                MessageItem(data: data, timeFormat: timeFormat),
            emptyMessage: 'No messages yet. Start the conversation!',
          ),
          const SizedBox(height: 200),
        ],
      ),
    );
  }
}

class _ProgressTab extends StatelessWidget {
  final TextEditingController controller;
  final String? userProfilePic;
  final DateFormat timeFormat;
  final VoidCallback onSubmit;
  final bool isOwner;

  const _ProgressTab({
    required this.controller,
    required this.userProfilePic,
    required this.timeFormat,
    required this.onSubmit,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (isOwner)
            _InputSection(
              title: 'Add In Progress Item',
              hint: 'What are you working on for the next update?',
              controller: controller,
              userProfilePic: userProfilePic,
              onSubmit: onSubmit,
              buttonText: 'Add Item',
              maxLines: 2,
            ),
          const SizedBox(height: 16),
          _StreamContent<ProgressItem>(
            collection: 'Progress',
            itemBuilder: (data) =>
                ProgressItem(data: data, timeFormat: timeFormat),
            emptyMessage: 'No items in progress yet.',
          ),
          const SizedBox(height: 200),
        ],
      ),
    );
  }
}

class _StreamContent<T extends Widget> extends StatelessWidget {
  final String collection;
  final T Function(Map<String, dynamic>) itemBuilder;
  final String emptyMessage;

  const _StreamContent({
    required this.collection,
    required this.itemBuilder,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.secondaryColor),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 32.0),
              child: StyledText(emptyMessage),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs
              .map((doc) => itemBuilder({
                    ...doc.data() as Map<String, dynamic>,
                    'docId': doc.id, // Add document ID to the data map
                  }))
              .toList(),
        );
      },
    );
  }
}

class _InputSection extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController controller;
  final String? userProfilePic;
  final VoidCallback onSubmit;
  final String buttonText;
  final int maxLines;

  const _InputSection({
    required this.title,
    required this.hint,
    required this.controller,
    required this.userProfilePic,
    required this.onSubmit,
    required this.buttonText,
    this.maxLines = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: StyledHeadingLarge(title, color: AppColors.textColor)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _UserAvatar(profilePic: userProfilePic),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle:
                      TextStyle(color: AppColors.textColor.withOpacity(0.6)),
                  filled: true,
                  fillColor: AppColors.primaryAccent.withOpacity(0.3),
                ),
                style: TextStyle(color: AppColors.textColor),
                maxLines: maxLines,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryColor,
              foregroundColor: AppColors.textColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: StyledTextMedium(buttonText, color: AppColors.textColor),
          ),
        ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String? profilePic;

  const _UserAvatar({this.profilePic});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.secondaryColor.withOpacity(0.2),
      foregroundImage: profilePic != null && profilePic!.isNotEmpty
          ? AssetImage('lib/assets/images/${profilePic}')
          : null,
      child: profilePic == null || profilePic!.isEmpty
          ? Icon(Icons.person, size: 20, color: AppColors.secondaryColor)
          : null,
    );
  }
}

abstract class _BaseItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final DateFormat timeFormat;

  const _BaseItem({required this.data, required this.timeFormat});

  String get displayName =>
      data['username'] ?? data['userEmail']?.split('@')[0] ?? 'Anonymous';

  String get profilePic => data['profilePic'] ?? '';

  Timestamp? get timestamp => data['timestamp'] as Timestamp?;

  Widget buildContent();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      color: AppColors.primaryAccent.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UserAvatar(profilePic: profilePic),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StyledText(
                            displayName,
                            color: AppColors.secondaryColor,
                          ),
                          if (timestamp != null)
                            StyledTextSmall(
                              timeFormat.format(timestamp!.toDate()),
                              color: AppColors.textColor.withOpacity(0.7),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      buildContent(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MessageItem extends _BaseItem {
  const MessageItem({required super.data, required super.timeFormat});

  @override
  Widget buildContent() {
    return StyledText(data['message'] ?? '', color: AppColors.textColor);
  }
}

class ProgressItem extends _BaseItem {
  const ProgressItem({required super.data, required super.timeFormat});

  @override
  Widget buildContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ', style: TextStyle(fontSize: 16, color: AppColors.textColor)),
        Expanded(
          child: StyledTextSmall(
            data['item'] ?? '',
            color: AppColors.textColor,
          ),
        ),
      ],
    );
  }
}

class FeedbackItem extends StatefulWidget {
  final Map<String, dynamic> data;
  final DateFormat timeFormat;

  const FeedbackItem({required this.data, required this.timeFormat});

  @override
  State<FeedbackItem> createState() => _FeedbackItemState();
}

class _FeedbackItemState extends State<FeedbackItem> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.data['likes'] ?? 0;
    final likedByDynamic = widget.data['likedBy'] as List<dynamic>?;
    _isLiked = (likedByDynamic
            ?.map((e) => e.toString())
            .contains(FirebaseAuth.instance.currentUser!.uid) ??
        false);
  }

  @override
  void didUpdateWidget(covariant FeedbackItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _likeCount = widget.data['likes'] ?? 0;
      final likedByDynamic = widget.data['likedBy'] as List<dynamic>?;
      _isLiked = (likedByDynamic
              ?.map((e) => e.toString())
              .contains(FirebaseAuth.instance.currentUser!.uid) ??
          false);
    }
  }

  Future<void> _toggleLike() async {
    final docId = widget.data['docId'] as String;
    final docRef = FirebaseFirestore.instance.collection('Feedback').doc(docId);
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final likedBy = (widget.data['likedBy'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    setState(() {
      if (_isLiked) {
        _likeCount--;
        likedBy.remove(currentUserId);
      } else {
        _likeCount++;
        likedBy.add(currentUserId);
      }
      _isLiked = !_isLiked;
    });

    try {
      await docRef.update({
        'likes': _likeCount,
        'likedBy': likedBy,
      });
    } catch (e) {
      print('Error updating like: $e');
    }
  }

  Future<void> _addComment() async {
    final docId = widget.data['docId'] as String;
    final docRef = FirebaseFirestore.instance.collection('Feedback').doc(docId);
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final currentUsername = widget.data['username'] ??
        FirebaseAuth.instance.currentUser!.email!.split('@')[0];
    final currentTime = Timestamp.fromDate(DateTime.now());
    final currentProfilePic =
        widget.data['profilePic'] ?? ''; // Adjust based on your data source

    final newComment = {
      'userId': currentUserId,
      'username': currentUsername,
      'comment': _commentController.text.trim(),
      'timestamp': currentTime,
      'profilePic': currentProfilePic,
    };

    setState(() {
      _commentController.clear();
    });

    try {
      await docRef.update({
        'comments': FieldValue.arrayUnion([newComment]),
      });
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  String get displayName =>
      widget.data['username'] ??
      widget.data['userEmail']?.split('@')[0] ??
      'Anonymous';

  Timestamp? get timestamp => widget.data['timestamp'] as Timestamp?;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> _comments =
        List<Map<String, dynamic>>.from(widget.data['comments'] ?? []);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      color: AppColors.primaryAccent.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UserAvatar(profilePic: widget.data['profilePic']),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StyledText(
                            displayName,
                            color: AppColors.secondaryColor,
                          ),
                          if (timestamp != null)
                            StyledTextSmall(
                              widget.timeFormat.format(timestamp!.toDate()),
                              color: AppColors.textColor.withOpacity(0.7),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      StyledText(widget.data['feedback'] ?? '',
                          color: AppColors.textColor),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.thumb_up,
                              size: 18,
                              color: _isLiked
                                  ? AppColors.secondaryColor
                                  : AppColors.textColor.withOpacity(0.7),
                            ),
                            onPressed: _toggleLike,
                            color: AppColors.textColor.withOpacity(0.7),
                          ),
                          StyledText('$_likeCount',
                              color: AppColors.textColor.withOpacity(0.7)),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.comment_outlined, size: 18),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: StyledText('Comments',
                                      color: AppColors.secondaryColor),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ..._comments.map((comment) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _UserAvatar(
                                                    profilePic:
                                                        comment['profilePic']),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          StyledText(
                                                            comment['username'] ??
                                                                'Anonymous',
                                                            color: AppColors
                                                                .secondaryColor,
                                                          ),
                                                          StyledTextSmall(
                                                            widget.timeFormat
                                                                .format((comment[
                                                                            'timestamp']
                                                                        as Timestamp)
                                                                    .toDate()),
                                                            color: AppColors
                                                                .textColor
                                                                .withOpacity(
                                                                    0.7),
                                                          ),
                                                        ],
                                                      ),
                                                      StyledText(
                                                          comment['comment'],
                                                          color: AppColors
                                                              .textColor),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _commentController,
                                        decoration: InputDecoration(
                                          hintText: 'Add a comment...',
                                          hintStyle: TextStyle(
                                              color: AppColors.textColor
                                                  .withOpacity(0.6)),
                                          filled: true,
                                          fillColor: AppColors.primaryAccent
                                              .withOpacity(0.3),
                                        ),
                                        style: TextStyle(
                                            color: AppColors.textColor),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        _addComment();
                                        Navigator.pop(context);
                                      },
                                      child: StyledText('Submit',
                                          color: AppColors.secondaryColor),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: StyledText('Cancel',
                                          color: AppColors.secondaryColor),
                                    ),
                                  ],
                                ),
                              );
                            },
                            color: AppColors.textColor.withOpacity(0.7),
                          ),
                        ],
                      ),
                      if (_comments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _comments
                              .map((comment) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _UserAvatar(
                                            profilePic: comment['profilePic']),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  StyledText(
                                                    comment['username'] ??
                                                        'Anonymous',
                                                    color: AppColors
                                                        .secondaryColor,
                                                  ),
                                                  StyledTextSmall(
                                                    widget.timeFormat.format(
                                                        (comment['timestamp']
                                                                as Timestamp)
                                                            .toDate()),
                                                    color: AppColors.textColor
                                                        .withOpacity(0.7),
                                                  ),
                                                ],
                                              ),
                                              StyledText(comment['comment'],
                                                  color: AppColors.textColor),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
