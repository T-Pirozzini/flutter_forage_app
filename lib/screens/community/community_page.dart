import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/services/ad_mob_service.dart';
import 'package:flutter_forager_app/shared/screen_heading.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/data/models/post.dart';
import 'package:flutter_forager_app/screens/community/components/post_card.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  String? username;
  final Map<String, bool> _expandedPosts = {};
  final Map<String, TextEditingController> _commentControllers = {};
  final Map<String, TextEditingController> _statusNoteControllers = {};

  @override
  void initState() {
    super.initState();
    fetchUsername();
  }

  @override
  void dispose() {
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    for (var controller in _statusNoteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> fetchUsername() async {
    final userRepo = ref.read(userRepositoryProvider);
    final user = await userRepo.getById(currentUser.email!);

    if (user != null) {
      setState(() {
        username = user.username;
      });
    }
  }

  void toggleExpand(String postId) {
    setState(() {
      _expandedPosts[postId] = !(_expandedPosts[postId] ?? false);
    });
  }

  Future<void> addComment(String postId, String comment) async {
    if (comment.isEmpty) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to comment')),
          );
        }
        return;
      }

      final postRepo = ref.read(postRepositoryProvider);
      await postRepo.addComment(
        postId: postId,
        userId: currentUser.uid,
        userEmail: currentUser.email!,
        username: username ?? currentUser.email!.split('@')[0],
        text: comment,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: ${e.toString()}')),
        );
      }
      debugPrint('Error adding comment: $e');
    }
  }

  Future<void> updateStatus(String postId, String status, String? notes) async {
    try {
      final postRepo = ref.read(postRepositoryProvider);
      await postRepo.updateStatus(
        postId: postId,
        status: status,
        userId: currentUser.uid,
        userEmail: currentUser.email!,
        username: username ?? currentUser.email!.split('@')[0],
        notes: notes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Future<void> toggleFavorite(String postId, bool isCurrentlyLiked) async {
    try {
      final postRepo = ref.read(postRepositoryProvider);
      await postRepo.toggleLike(
        postId: postId,
        userEmail: currentUser.email!,
        isCurrentlyLiked: isCurrentlyLiked,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update like: $e')),
        );
      }
    }
  }

  Future<void> toggleBookmark(String postId, bool isCurrentlyBookmarked) async {
    try {
      final postRepo = ref.read(postRepositoryProvider);
      await postRepo.toggleBookmark(
        postId: postId,
        userEmail: currentUser.email!,
        isCurrentlyBookmarked: isCurrentlyBookmarked,
      );

      // Show ad after bookmarking (not unbookmarking)
      if (!isCurrentlyBookmarked && mounted) {
        await Future.delayed(const Duration(seconds: 1));
        AdMobService.showInterstitialAd();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update bookmark: $e')),
        );
      }
    }
  }

  Future<void> deletePost(String postId, String postOwner) async {
    if (postOwner != currentUser.email) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only delete your own posts')),
        );
      }
      return;
    }

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Post'),
            content: const Text('Are you sure you want to delete this post?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldDelete) {
      try {
        final postRepo = ref.read(postRepositoryProvider);
        await postRepo.deletePost(
          postId: postId,
          currentUserEmail: currentUser.email!,
          postOwnerEmail: postOwner,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete post: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ScreenHeading(title: 'Community'),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            color: AppTheme.primary.withValues(alpha: 0.1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: StyledTextMedium(
                      "Care to share your secret spots with us?",
                      color: AppTheme.textDark),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: StyledTextMedium(
                      'Like and/or bookmark forage locations and go explore!',
                      color: AppTheme.textDark),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: StyledTextMedium(
                      '* A short Ad will appear after bookmarking a location. Thank you for your support!',
                      color: AppTheme.textDark),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<PostModel>>(
              stream: ref.read(postRepositoryProvider).streamAllPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading posts: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No posts yet. Be the first to share!'));
                }

                final posts = snapshot.data!;

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    _commentControllers.putIfAbsent(
                        post.id, () => TextEditingController());
                    _statusNoteControllers.putIfAbsent(
                        post.id, () => TextEditingController());

                    return PostCard(
                      post: post,
                      isFavorite: post.likedBy.contains(currentUser.email),
                      isBookmarked:
                          post.bookmarkedBy.contains(currentUser.email),
                      onToggleFavorite: () => toggleFavorite(
                          post.id, post.likedBy.contains(currentUser.email)),
                      onToggleBookmark: () => toggleBookmark(post.id,
                          post.bookmarkedBy.contains(currentUser.email)),
                      onDelete: () => deletePost(post.id, post.userEmail),
                      commentController: _commentControllers[post.id]!,
                      statusNoteController: _statusNoteControllers[post.id]!,
                      onAddComment: (comment) => addComment(post.id, comment),
                      onUpdateStatus: (status, notes) =>
                          updateStatus(post.id, status, notes),
                      currentUserEmail: currentUser.email!,
                      username: username,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> getLocationWithFlag(double latitude, double longitude) async {
  try {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(latitude, longitude);

    if (placemarks.isNotEmpty) {
      Placemark placemark = placemarks[0];
      String? countryCode = placemark.isoCountryCode;
      String flagEmoji = countryCode != null
          ? _countryCodeToFlagEmoji(countryCode)
          : '🌐'; // Fallback to globe emoji

      return '${placemark.locality ?? placemark.subLocality}, ${placemark.country} $flagEmoji';
    }
  } catch (e) {
    print('Error: $e');
  }
  return null;
}

// Helper: Convert ISO country code (e.g., "US") to flag emoji (🇺🇸)
String _countryCodeToFlagEmoji(String countryCode) {
  final int firstChar = countryCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
  final int secondChar = countryCode.codeUnitAt(1) - 0x41 + 0x1F1E6;
  return String.fromCharCode(firstChar) + String.fromCharCode(secondChar);
}
