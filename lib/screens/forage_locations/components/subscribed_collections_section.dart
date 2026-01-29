import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/collection_subscription.dart';
import 'package:flutter_forager_app/data/models/location_collection.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/screens/collections/collection_detail_page.dart';
import 'package:flutter_forager_app/screens/collections/collections_page.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Section showing user's subscribed collections in the ForageLocations page.
///
/// Displays a collapsible section with subscribed collections from friends.
/// Tapping a collection shows all its locations.
class SubscribedCollectionsSection extends ConsumerStatefulWidget {
  const SubscribedCollectionsSection({Key? key}) : super(key: key);

  @override
  ConsumerState<SubscribedCollectionsSection> createState() =>
      _SubscribedCollectionsSectionState();
}

class _SubscribedCollectionsSectionState
    extends ConsumerState<SubscribedCollectionsSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.email == null) {
      return const SizedBox.shrink();
    }

    final collectionRepo = ref.watch(collectionRepositoryProvider);

    return StreamBuilder<List<CollectionSubscriptionModel>>(
      stream: collectionRepo.streamSubscriptions(currentUser!.email!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final subscriptions = snapshot.data ?? [];

        if (subscriptions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_special,
                      color: AppTheme.secondary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Subscribed Collections',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${subscriptions.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),

            // Subscribed collections list
            if (_isExpanded)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: subscriptions.length + 1, // +1 for "See All" card
                  itemBuilder: (context, index) {
                    if (index == subscriptions.length) {
                      // "See All" card
                      return _buildSeeAllCard(context);
                    }
                    final subscription = subscriptions[index];
                    return _SubscriptionCard(
                      subscription: subscription,
                      onTap: () => _openCollection(context, subscription),
                    );
                  },
                ),
              ),

            if (_isExpanded) const SizedBox(height: 8),
            if (_isExpanded) const Divider(height: 1),
          ],
        );
      },
    );
  }

  Widget _buildSeeAllCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CollectionsPage()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primary.withOpacity(0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.grid_view,
                color: AppTheme.primary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                'See All',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCollection(
    BuildContext context,
    CollectionSubscriptionModel subscription,
  ) async {
    final collectionRepo = ref.read(collectionRepositoryProvider);

    // Fetch the actual collection from the owner
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
}

/// Card for displaying a subscribed collection
class _SubscriptionCard extends StatelessWidget {
  final CollectionSubscriptionModel subscription;
  final VoidCallback onTap;

  const _SubscriptionCard({
    required this.subscription,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image or icon
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.2),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: subscription.coverImageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          subscription.coverImageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              Icons.folder,
                              color: AppTheme.secondary,
                              size: 24,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.folder,
                          color: AppTheme.secondary,
                          size: 24,
                        ),
                      ),
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        subscription.collectionName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 10,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${subscription.markerCount}',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              subscription.ownerDisplayName,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
