import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/core/utils/forage_type_utils.dart';
import 'package:flutter_forager_app/data/models/friend.dart';
import 'package:flutter_forager_app/data/models/location_collection.dart';
import 'package:flutter_forager_app/data/models/collection_subscription.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/screens/collections/components/create_collection_dialog.dart';
import 'package:flutter_forager_app/screens/collections/collection_detail_page.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Tab for managing collections with sub-tabs: My | Subscribed | Discover
class CollectionsTab extends ConsumerStatefulWidget {
  final String userId;

  const CollectionsTab({Key? key, required this.userId}) : super(key: key);

  @override
  ConsumerState<CollectionsTab> createState() => _CollectionsTabState();
}

class _CollectionsTabState extends ConsumerState<CollectionsTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  Future<void> _showCreateCollectionDialog() async {
    final result = await CreateCollectionDialog.show(context);
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Collection "${result.name}" created!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sub-tabs
        Container(
          color: AppTheme.surfaceLight,
          child: TabBar(
            controller: _subTabController,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 2,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textMedium,
            labelStyle: AppTheme.caption(size: 12, weight: FontWeight.w600),
            unselectedLabelStyle: AppTheme.caption(size: 12),
            tabs: const [
              Tab(text: 'My'),
              Tab(text: 'Subscribed'),
              Tab(text: 'Discover'),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              _MyCollectionsSubTab(userId: widget.userId),
              _SubscribedSubTab(userId: widget.userId),
              _DiscoverSubTab(userId: widget.userId),
            ],
          ),
        ),

        // Create button
        Container(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showCreateCollectionDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Collection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Sub-tab showing user's own collections
class _MyCollectionsSubTab extends ConsumerWidget {
  final String userId;

  const _MyCollectionsSubTab({required this.userId});

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
                Icon(Icons.folder_open, size: 48, color: AppTheme.textLight),
                const SizedBox(height: 12),
                Text(
                  'No collections yet',
                  style: AppTheme.heading(size: 16, color: AppTheme.textMedium),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create a collection to organize\nyour locations',
                  textAlign: TextAlign.center,
                  style: AppTheme.body(size: 13, color: AppTheme.textLight),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: collections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
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
        content: Text('Delete "${collection.name}"? This cannot be undone.'),
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

/// Sub-tab showing subscribed collections
class _SubscribedSubTab extends ConsumerWidget {
  final String userId;

  const _SubscribedSubTab({required this.userId});

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
                Icon(Icons.bookmark_border, size: 48, color: AppTheme.textLight),
                const SizedBox(height: 12),
                Text(
                  'No subscriptions yet',
                  style: AppTheme.heading(size: 16, color: AppTheme.textMedium),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subscribe to collections in Discover\nto see them here',
                  textAlign: TextAlign.center,
                  style: AppTheme.body(size: 13, color: AppTheme.textLight),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: subscriptions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final subscription = subscriptions[index];
            return _SubscriptionCard(
              subscription: subscription,
              onTap: () => _navigateToSubscribed(context, ref, subscription),
              onUnsubscribe: () => _unsubscribe(context, ref, subscription),
            );
          },
        );
      },
    );
  }

  Future<void> _navigateToSubscribed(
    BuildContext context,
    WidgetRef ref,
    CollectionSubscriptionModel subscription,
  ) async {
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
        content: Text('Unsubscribe from "${subscription.collectionName}"?'),
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
            SnackBar(content: Text('Failed: $e')),
          );
        }
      }
    }
  }
}

/// Sub-tab for discovering ALL public collections with filtering
class _DiscoverSubTab extends ConsumerStatefulWidget {
  final String userId;

  const _DiscoverSubTab({required this.userId});

  @override
  ConsumerState<_DiscoverSubTab> createState() => _DiscoverSubTabState();
}

class _DiscoverSubTabState extends ConsumerState<_DiscoverSubTab> {
  String? _filterByType; // null = all types
  bool _showMyCollections = false;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _getUserPosition();
  }

  Future<void> _getUserPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _userPosition = position);
      }
    } catch (e) {
      // Location not available - proximity filtering won't work
    }
  }

  @override
  Widget build(BuildContext context) {
    final collectionRepo = ref.watch(collectionRepositoryProvider);

    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: AppTheme.surfaceLight,
          child: Row(
            children: [
              // Type filter
              Expanded(
                child: PopupMenuButton<String?>(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppTheme.borderRadiusSmall,
                      border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, size: 18, color: AppTheme.textMedium),
                        const SizedBox(width: 8),
                        Text(
                          _filterByType ?? 'All Types',
                          style: AppTheme.body(size: 13, color: AppTheme.textDark),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_drop_down, color: AppTheme.textMedium),
                      ],
                    ),
                  ),
                  onSelected: (value) => setState(() => _filterByType = value),
                  itemBuilder: (context) => [
                    PopupMenuItem<String?>(
                      value: null,
                      child: Text(
                        'All Types',
                        style: TextStyle(
                          fontWeight: _filterByType == null ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    ...ForageTypeUtils.allTypes.map((type) => PopupMenuItem<String>(
                          value: type,
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: ForageTypeUtils.getTypeColor(type).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: ImageIcon(
                                  AssetImage('lib/assets/images/${type.toLowerCase()}_marker.png'),
                                  size: 16,
                                  color: ForageTypeUtils.getTypeColor(type),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                type,
                                style: TextStyle(
                                  fontWeight: _filterByType == type ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Show mine toggle
              FilterChip(
                label: Text(
                  'Show mine',
                  style: AppTheme.caption(
                    size: 11,
                    color: _showMyCollections ? AppTheme.primary : AppTheme.textMedium,
                  ),
                ),
                selected: _showMyCollections,
                onSelected: (value) => setState(() => _showMyCollections = value),
                selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                checkmarkColor: AppTheme.primary,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: _showMyCollections ? AppTheme.primary : AppTheme.textLight.withValues(alpha: 0.3),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),

        // Collections list
        Expanded(
          child: StreamBuilder<List<LocationCollectionModel>>(
            stream: collectionRepo.streamAllPublicCollections(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              var collections = snapshot.data ?? [];

              // Filter out user's own collections unless "Show mine" is enabled
              if (!_showMyCollections) {
                collections = collections.where((c) => c.ownerEmail != widget.userId).toList();
              }

              // Filter by type if selected
              if (_filterByType != null) {
                collections = collections.where((c) {
                  // Check if collection has markers of the selected type
                  // This would require the collection model to track predominant type
                  // For now, we'll just show all - this needs backend support
                  return true;
                }).toList();
              }

              if (collections.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.explore_off, size: 48, color: AppTheme.textLight),
                      const SizedBox(height: 12),
                      Text(
                        'No collections found',
                        style: AppTheme.heading(size: 16, color: AppTheme.textMedium),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _showMyCollections
                            ? 'No public collections available yet'
                            : 'Enable "Show mine" to see your\npublic collections',
                        textAlign: TextAlign.center,
                        style: AppTheme.body(size: 13, color: AppTheme.textLight),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: collections.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final collection = collections[index];
                  return _DiscoverCollectionCard(
                    collection: collection,
                    currentUserId: widget.userId,
                    onTap: () => _navigateToCollection(context, collection),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToCollection(BuildContext context, LocationCollectionModel collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionDetailPage(
          collection: collection,
          isOwner: collection.ownerEmail == widget.userId,
        ),
      ),
    );
  }
}

/// Card for a discoverable collection with subscribe button
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
  ConsumerState<_DiscoverCollectionCard> createState() => _DiscoverCollectionCardState();
}

class _DiscoverCollectionCardState extends ConsumerState<_DiscoverCollectionCard> {
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
    final isOwnCollection = widget.collection.ownerEmail == widget.currentUserId;

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: AppTheme.borderRadiusMedium,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.2),
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                child: widget.collection.coverImageUrl != null
                    ? ClipRRect(
                        borderRadius: AppTheme.borderRadiusSmall,
                        child: Image.network(
                          widget.collection.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.folder,
                            color: AppTheme.info,
                            size: 24,
                          ),
                        ),
                      )
                    : const Icon(
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.collection.name,
                            style: AppTheme.heading(size: 14, color: AppTheme.textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOwnCollection)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'You',
                              style: AppTheme.caption(size: 10, color: AppTheme.primary),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 12, color: AppTheme.textLight),
                        const SizedBox(width: 2),
                        Text(
                          widget.collection.ownerDisplayName,
                          style: AppTheme.caption(size: 11, color: AppTheme.textLight),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textLight),
                        const SizedBox(width: 2),
                        Text(
                          '${widget.collection.markerIds.length}',
                          style: AppTheme.caption(size: 11, color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Subscribe button (only if not own collection)
              if (!isOwnCollection)
                _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: Icon(
                          _isSubscribed ? Icons.bookmark : Icons.bookmark_border,
                          color: _isSubscribed ? AppTheme.secondary : AppTheme.textLight,
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
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.borderRadiusMedium,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover image or icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.2),
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                child: collection.coverImageUrl != null
                    ? ClipRRect(
                        borderRadius: AppTheme.borderRadiusSmall,
                        child: Image.network(
                          collection.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.folder,
                            color: AppTheme.primary,
                            size: 24,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.folder,
                        color: AppTheme.primary,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 12),
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
                            style: AppTheme.heading(size: 14, color: AppTheme.textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (collection.isPublic)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Public',
                              style: AppTheme.caption(size: 10, color: AppTheme.success),
                            ),
                          ),
                      ],
                    ),
                    if (collection.description != null && collection.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          collection.description!,
                          style: AppTheme.body(size: 12, color: AppTheme.textMedium),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: AppTheme.textLight),
                        const SizedBox(width: 2),
                        Text(
                          '${collection.markerIds.length} locations',
                          style: AppTheme.caption(size: 11, color: AppTheme.textLight),
                        ),
                        if (collection.subscriberCount > 0) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.people, size: 14, color: AppTheme.textLight),
                          const SizedBox(width: 2),
                          Text(
                            '${collection.subscriberCount}',
                            style: AppTheme.caption(size: 11, color: AppTheme.textLight),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Delete button
              if (isOwner && onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: AppTheme.textLight),
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
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.borderRadiusMedium,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover image or icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.2),
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                child: subscription.coverImageUrl != null
                    ? ClipRRect(
                        borderRadius: AppTheme.borderRadiusSmall,
                        child: Image.network(
                          subscription.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.bookmark,
                            color: AppTheme.secondary,
                            size: 24,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.bookmark,
                        color: AppTheme.secondary,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 12),
              // Subscription info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.collectionName,
                      style: AppTheme.heading(size: 14, color: AppTheme.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subscription.collectionDescription != null &&
                        subscription.collectionDescription!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subscription.collectionDescription!,
                          style: AppTheme.body(size: 12, color: AppTheme.textMedium),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: AppTheme.textLight),
                        const SizedBox(width: 2),
                        Text(
                          subscription.ownerDisplayName,
                          style: AppTheme.caption(size: 11, color: AppTheme.textLight),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.location_on, size: 14, color: AppTheme.textLight),
                        const SizedBox(width: 2),
                        Text(
                          '${subscription.markerCount}',
                          style: AppTheme.caption(size: 11, color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Unsubscribe button
              IconButton(
                icon: Icon(Icons.bookmark_remove_outlined, color: AppTheme.textLight),
                onPressed: onUnsubscribe,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
