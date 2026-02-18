import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/data/models/post.dart';
import 'package:flutter_forager_app/providers/community/community_filter_provider.dart';
import 'package:flutter_forager_app/screens/community/components/community_filter_bar.dart';
import 'package:flutter_forager_app/screens/community/components/post_card.dart';
import 'package:flutter_forager_app/shared/gamification/gamification_helper.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

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

      // Award points for commenting
      if (mounted) {
        await GamificationHelper.awardPostComment(
          context: context,
          ref: ref,
          userId: currentUser.email!,
        );
      }
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

      // Award points when liking (not unliking)
      if (!isCurrentlyLiked && mounted) {
        await GamificationHelper.awardPostLiked(
          context: context,
          ref: ref,
          userId: currentUser.email!,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update like: $e')),
        );
      }
    }
  }

  Future<void> toggleBookmark(String postId, bool isCurrentlyBookmarked, PostModel post) async {
    try {
      final postRepo = ref.read(postRepositoryProvider);
      final bookmarkRepo = ref.read(bookmarkRepositoryProvider);

      // Update the post's bookmark count/array
      await postRepo.toggleBookmark(
        postId: postId,
        userEmail: currentUser.email!,
        isCurrentlyBookmarked: isCurrentlyBookmarked,
      );

      // Also update user's Bookmarks subcollection for My Foraging tab
      if (isCurrentlyBookmarked) {
        // Remove from user's bookmarks - find by matching post data
        await bookmarkRepo.removeBookmarkByLocation(
          currentUser.email!,
          post.latitude,
          post.longitude,
        );
      } else {
        // Add to user's bookmarks subcollection
        await bookmarkRepo.addBookmarkFromData(
          userId: currentUser.email!,
          markerId: postId, // Use post ID as marker reference
          markerOwner: post.originalMarkerOwner,
          markerName: post.name,
          markerDescription: post.description,
          latitude: post.latitude,
          longitude: post.longitude,
          type: post.type,
          imageUrl: post.imageUrls.isNotEmpty ? post.imageUrls.first : null,
        );
      }

      // TODO: Add video ad here later
      // if (!isCurrentlyBookmarked && mounted) {
      //   await Future.delayed(const Duration(seconds: 1));
      //   AdMobService.showInterstitialAd();
      // }
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

  /// Get the appropriate post stream based on the selected filter
  Stream<List<PostModel>> _getFilteredStream(CommunityFilter filter) {
    final postRepo = ref.read(postRepositoryProvider);

    switch (filter) {
      case CommunityFilter.all:
      case CommunityFilter.recent:
        // Both use all posts, sorted by recent (default order)
        return postRepo.streamAllPosts();

      case CommunityFilter.friends:
        // Get friends list and filter posts
        return ref.read(friendRepositoryProvider).streamFriends(currentUser.email!).asyncMap((friends) async {
          final friendEmails = friends.map((f) => f.friendEmail).toList();
          if (friendEmails.isEmpty) return <PostModel>[];

          // Use the filtered stream
          return await postRepo.streamFriendsPosts(friendEmails).first;
        });

      case CommunityFilter.following:
        // Get following list and filter posts
        return ref.read(followingRepositoryProvider).streamFollowing(currentUser.email!).asyncMap((following) async {
          final followingEmails = following.map((f) => f.followedEmail).toList();
          if (followingEmails.isEmpty) return <PostModel>[];

          // Use the filtered stream
          return await postRepo.streamFollowingPosts(followingEmails).first;
        });

      case CommunityFilter.nearby:
        // Get current location and filter by radius
        return _getNearbyPostsStream();
    }
  }

  Stream<List<PostModel>> _getNearbyPostsStream() async* {
    final postRepo = ref.read(postRepositoryProvider);
    final radius = ref.read(communityRadiusProvider);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      yield* postRepo.streamNearbyPosts(
        position.latitude,
        position.longitude,
        radius,
      );
    } catch (e) {
      // If location fails, return all posts
      debugPrint('Location error for nearby filter: $e');
      yield* postRepo.streamAllPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFilter = ref.watch(communityFilterProvider);

    return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: Column(
          children: [
            // Filter bar
            const CommunityFilterBar(),
            Expanded(
              child: StreamBuilder<List<PostModel>>(
              stream: _getFilteredStream(currentFilter),
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 80,
                            color: AppTheme.primary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No posts yet',
                            style: AppTheme.heading(
                                size: 20, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to share your amazing finds with the community!',
                            textAlign: TextAlign.center,
                            style: AppTheme.body(
                                size: 14, color: AppTheme.textMedium),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: AppTheme.borderRadiusMedium,
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lightbulb_outline,
                                        color: AppTheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'How to share:',
                                      style: AppTheme.heading(
                                          size: 14, color: AppTheme.primary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text('1. Create a marker on the map', style: AppTheme.body(size: 13, color: AppTheme.textMedium)),
                                const SizedBox(height: 4),
                                Text('2. Open your location details', style: AppTheme.body(size: 13, color: AppTheme.textMedium)),
                                const SizedBox(height: 4),
                                Text('3. Tap "Share with Community"', style: AppTheme.body(size: 13, color: AppTheme.textMedium)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star,
                                  color: AppTheme.success, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Earn 15 points per share!',
                                style: AppTheme.caption(
                                  size: 13,
                                  color: AppTheme.success,
                                  weight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final posts = snapshot.data!;

                return ListView.separated(
                    itemCount: posts.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
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
                        onToggleBookmark: () => toggleBookmark(
                            post.id,
                            post.bookmarkedBy.contains(currentUser.email),
                            post),
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
