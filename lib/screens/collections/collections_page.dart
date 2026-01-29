import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/friend.dart';
import 'package:flutter_forager_app/data/models/location_collection.dart';
import 'package:flutter_forager_app/data/models/collection_subscription.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/screens/collections/components/create_collection_dialog.dart';
import 'package:flutter_forager_app/screens/collections/collection_detail_page.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CollectionsPage extends ConsumerStatefulWidget {
  const CollectionsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends ConsumerState<CollectionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.email == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view collections')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'My Collections', icon: Icon(Icons.folder)),
            Tab(text: 'Subscribed', icon: Icon(Icons.bookmark)),
            Tab(text: 'Discover', icon: Icon(Icons.explore)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyCollectionsTab(userId: currentUser!.email!),
          _SubscribedCollectionsTab(userId: currentUser.email!),
          _DiscoverCollectionsTab(userId: currentUser.email!),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateCollectionDialog(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _showCreateCollectionDialog(BuildContext context) async {
    final result = await CreateCollectionDialog.show(context);
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Collection "${result.name}" created!')),
      );
    }
  }
}

/// Tab showing user's own collections
class _MyCollectionsTab extends ConsumerWidget {
  final String userId;

  const _MyCollectionsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionRepo = ref.watch(collectionRepositoryProvider);

    return StreamBuilder<List<LocationCollectionModel>>(
      stream: collectionRepo.streamMyCollections(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final collections = snapshot.data ?? [];

        if (collections.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: AppTheme.textLight),
                const SizedBox(height: 16),
                Text(
                  'No collections yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a collection to organize your locations',
                  style: TextStyle(color: AppTheme.textLight),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: collections.length,
          itemBuilder: (context, index) {
            final collection = collections[index];
            return _CollectionCard(
              collection: collection,
              isOwner: true,
              onTap: () => _navigateToDetail(context, collection),
              onDelete: () => _deleteCollection(context, ref, collection),
            );
          },
        );
      },
    );
  }

  void _navigateToDetail(BuildContext context, LocationCollectionModel collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionDetailPage(
          collection: collection,
          isOwner: true,
        ),
      ),
    );
  }

  Future<void> _deleteCollection(
    BuildContext context,
    WidgetRef ref,
    LocationCollectionModel collection,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Collection'),
        content: Text('Are you sure you want to delete "${collection.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final collectionRepo = ref.read(collectionRepositoryProvider);
        await collectionRepo.deleteCollection(userId, collection.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Collection deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }
}

/// Tab showing collections user has subscribed to
class _SubscribedCollectionsTab extends ConsumerWidget {
  final String userId;

  const _SubscribedCollectionsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionRepo = ref.watch(collectionRepositoryProvider);

    return StreamBuilder<List<CollectionSubscriptionModel>>(
      stream: collectionRepo.streamSubscriptions(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final subscriptions = snapshot.data ?? [];

        if (subscriptions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 64, color: AppTheme.textLight),
                const SizedBox(height: 16),
                Text(
                  'No subscriptions yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Subscribe to friends\' collections to see them here',
                  style: TextStyle(color: AppTheme.textLight),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subscriptions.length,
          itemBuilder: (context, index) {
            final subscription = subscriptions[index];
            return _SubscriptionCard(
              subscription: subscription,
              onTap: () => _navigateToSubscribedCollection(context, ref, subscription),
              onUnsubscribe: () => _unsubscribe(context, ref, subscription),
            );
          },
        );
      },
    );
  }

  Future<void> _navigateToSubscribedCollection(
    BuildContext context,
    WidgetRef ref,
    CollectionSubscriptionModel subscription,
  ) async {
    // Fetch the actual collection from the owner
    final collectionRepo = ref.read(collectionRepositoryProvider);
    final collection = await collectionRepo.getCollection(
      subscription.ownerEmail,
      subscription.collectionId,
    );

    if (collection != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CollectionDetailPage(
            collection: collection,
            isOwner: false,
          ),
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collection no longer exists')),
      );
    }
  }

  Future<void> _unsubscribe(
    BuildContext context,
    WidgetRef ref,
    CollectionSubscriptionModel subscription,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsubscribe'),
        content: Text(
          'Unsubscribe from "${subscription.collectionName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unsubscribe'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final collectionRepo = ref.read(collectionRepositoryProvider);
        await collectionRepo.unsubscribe(
          userId: userId,
          subscriptionId: subscription.id,
          ownerEmail: subscription.ownerEmail,
          collectionId: subscription.collectionId,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unsubscribed')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to unsubscribe: $e')),
          );
        }
      }
    }
  }
}

/// Tab for discovering public collections from friends
class _DiscoverCollectionsTab extends ConsumerWidget {
  final String userId;

  const _DiscoverCollectionsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendRepo = ref.watch(friendRepositoryProvider);

    return StreamBuilder<List<FriendModel>>(
      stream: friendRepo.streamFriends(userId),
      builder: (context, friendsSnapshot) {
        if (friendsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final friends = friendsSnapshot.data ?? [];

        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: AppTheme.textLight),
                const SizedBox(height: 16),
                Text(
                  'No friends yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add friends to discover their public collections',
                  style: TextStyle(color: AppTheme.textLight),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return _FriendCollectionsSection(
              friendEmail: friend.friendEmail,
              friendName: friend.displayName,
              currentUserId: userId,
            );
          },
        );
      },
    );
  }
}

/// Section showing public collections from a single friend
class _FriendCollectionsSection extends ConsumerWidget {
  final String friendEmail;
  final String friendName;
  final String currentUserId;

  const _FriendCollectionsSection({
    required this.friendEmail,
    required this.friendName,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionRepo = ref.watch(collectionRepositoryProvider);

    return StreamBuilder<List<LocationCollectionModel>>(
      stream: collectionRepo.streamPublicCollections(friendEmail),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final collections = snapshot.data ?? [];

        if (collections.isEmpty) {
          return const SizedBox.shrink(); // Don't show friends with no public collections
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Friend header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primaryLight.withOpacity(0.3),
                    child: Text(
                      friendName.isNotEmpty ? friendName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    friendName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${collections.length} public collection${collections.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            // Collections list
            ...collections.map((collection) => _DiscoverCollectionCard(
                  collection: collection,
                  currentUserId: currentUserId,
                  onTap: () => _navigateToCollection(context, collection),
                )),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _navigateToCollection(BuildContext context, LocationCollectionModel collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionDetailPage(
          collection: collection,
          isOwner: false,
        ),
      ),
    );
  }
}

/// Card for a discoverable collection
class _DiscoverCollectionCard extends ConsumerStatefulWidget {
  final LocationCollectionModel collection;
  final String currentUserId;
  final VoidCallback onTap;

  const _DiscoverCollectionCard({
    required this.collection,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  ConsumerState<_DiscoverCollectionCard> createState() =>
      _DiscoverCollectionCardState();
}

class _DiscoverCollectionCardState
    extends ConsumerState<_DiscoverCollectionCard> {
  bool _isSubscribed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    final collectionRepo = ref.read(collectionRepositoryProvider);
    final isSubscribed = await collectionRepo.isSubscribed(
      userId: widget.currentUserId,
      ownerEmail: widget.collection.ownerEmail,
      collectionId: widget.collection.id,
    );

    if (mounted) {
      setState(() {
        _isSubscribed = isSubscribed;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSubscription() async {
    setState(() => _isLoading = true);

    try {
      final collectionRepo = ref.read(collectionRepositoryProvider);

      if (_isSubscribed) {
        // Unsubscribe
        final subscription = await collectionRepo.getSubscriptionByCollectionId(
          userId: widget.currentUserId,
          ownerEmail: widget.collection.ownerEmail,
          collectionId: widget.collection.id,
        );

        if (subscription != null) {
          await collectionRepo.unsubscribe(
            userId: widget.currentUserId,
            subscriptionId: subscription.id,
            ownerEmail: widget.collection.ownerEmail,
            collectionId: widget.collection.id,
          );
        }

        if (mounted) {
          setState(() {
            _isSubscribed = false;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unsubscribed')),
          );
        }
      } else {
        // Subscribe
        await collectionRepo.subscribe(
          userId: widget.currentUserId,
          ownerEmail: widget.collection.ownerEmail,
          collectionId: widget.collection.id,
          collectionName: widget.collection.name,
          collectionDescription: widget.collection.description,
          ownerDisplayName: widget.collection.ownerDisplayName,
          markerCount: widget.collection.markerIds.length,
          coverImageUrl: widget.collection.coverImageUrl,
        );

        if (mounted) {
          setState(() {
            _isSubscribed = true;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscribed!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.folder,
                  color: AppTheme.info,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.collection.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.collection.markerIds.length} locations',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              // Subscribe button
              _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: Icon(
                        _isSubscribed
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: _isSubscribed
                            ? AppTheme.secondary
                            : AppTheme.textLight,
                      ),
                      onPressed: _toggleSubscription,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card for displaying a collection
class _CollectionCard extends StatelessWidget {
  final LocationCollectionModel collection;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _CollectionCard({
    required this.collection,
    required this.isOwner,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Cover image or icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: collection.coverImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          collection.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.folder,
                            color: AppTheme.primary,
                            size: 30,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.folder,
                        color: AppTheme.primary,
                        size: 30,
                      ),
              ),
              const SizedBox(width: 16),
              // Collection info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            collection.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (collection.isPublic)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Public',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.success,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (collection.description != null &&
                        collection.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          collection.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMedium,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${collection.markerIds.length} locations',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textLight,
                          ),
                        ),
                        if (collection.subscriberCount > 0) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.people,
                            size: 16,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${collection.subscriberCount} subscribers',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              if (isOwner && onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppTheme.textLight,
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card for displaying a subscription
class _SubscriptionCard extends StatelessWidget {
  final CollectionSubscriptionModel subscription;
  final VoidCallback onTap;
  final VoidCallback onUnsubscribe;

  const _SubscriptionCard({
    required this.subscription,
    required this.onTap,
    required this.onUnsubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Cover image or icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: subscription.coverImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          subscription.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.bookmark,
                            color: AppTheme.secondary,
                            size: 30,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.bookmark,
                        color: AppTheme.secondary,
                        size: 30,
                      ),
              ),
              const SizedBox(width: 16),
              // Subscription info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.collectionName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subscription.collectionDescription != null &&
                        subscription.collectionDescription!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subscription.collectionDescription!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMedium,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          subscription.ownerDisplayName,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${subscription.markerCount} locations',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Unsubscribe button
              IconButton(
                icon: const Icon(Icons.bookmark_remove_outlined),
                color: AppTheme.textLight,
                onPressed: onUnsubscribe,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
