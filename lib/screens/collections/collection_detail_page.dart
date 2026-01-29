import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/location_collection.dart';
import 'package:flutter_forager_app/data/models/marker.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/screens/forage_locations/forage_location_info_page.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CollectionDetailPage extends ConsumerStatefulWidget {
  final LocationCollectionModel collection;
  final bool isOwner;

  const CollectionDetailPage({
    Key? key,
    required this.collection,
    required this.isOwner,
  }) : super(key: key);

  @override
  ConsumerState<CollectionDetailPage> createState() =>
      _CollectionDetailPageState();
}

class _CollectionDetailPageState extends ConsumerState<CollectionDetailPage> {
  late LocationCollectionModel _collection;
  List<MarkerModel> _markers = [];
  bool _isLoading = true;
  bool _isSubscribed = false;
  bool _isSubscribing = false;

  @override
  void initState() {
    super.initState();
    _collection = widget.collection;
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMarkers(),
      if (!widget.isOwner) _checkSubscription(),
    ]);
  }

  Future<void> _loadMarkers() async {
    if (_collection.markerIds.isEmpty) {
      setState(() {
        _markers = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final markerRepo = ref.read(markerRepositoryProvider);
      final markers = await markerRepo.getBookmarkedMarkers(_collection.markerIds);
      if (mounted) {
        setState(() {
          _markers = markers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading markers: $e')),
        );
      }
    }
  }

  Future<void> _checkSubscription() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.email == null) return;

    final collectionRepo = ref.read(collectionRepositoryProvider);
    final isSubscribed = await collectionRepo.isSubscribed(
      userId: currentUser!.email!,
      ownerEmail: _collection.ownerEmail,
      collectionId: _collection.id,
    );

    if (mounted) {
      setState(() => _isSubscribed = isSubscribed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_collection.name),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (widget.isOwner)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editCollection,
            ),
          if (!widget.isOwner)
            _isSubscribing
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      _isSubscribed ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    onPressed: _toggleSubscription,
                  ),
        ],
      ),
      body: Column(
        children: [
          // Collection header
          _buildHeader(),
          const Divider(height: 1),
          // Markers list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _markers.isEmpty
                    ? _buildEmptyState()
                    : _buildMarkersList(),
          ),
        ],
      ),
      floatingActionButton: widget.isOwner
          ? FloatingActionButton.extended(
              onPressed: _addMarkers,
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Locations',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surfaceLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_collection.description != null &&
              _collection.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _collection.description!,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textMedium,
                ),
              ),
            ),
          Row(
            children: [
              _buildInfoChip(
                Icons.location_on,
                '${_collection.markerIds.length} locations',
              ),
              const SizedBox(width: 12),
              if (_collection.isPublic)
                _buildInfoChip(
                  Icons.public,
                  'Public',
                  color: AppTheme.success,
                )
              else
                _buildInfoChip(
                  Icons.lock,
                  'Private',
                  color: AppTheme.textLight,
                ),
              if (_collection.subscriberCount > 0) ...[
                const SizedBox(width: 12),
                _buildInfoChip(
                  Icons.people,
                  '${_collection.subscriberCount} subscribers',
                ),
              ],
            ],
          ),
          if (!widget.isOwner) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text(
                  'By ${_collection.ownerDisplayName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? AppTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No locations in this collection',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textMedium,
            ),
          ),
          if (widget.isOwner) ...[
            const SizedBox(height: 8),
            Text(
              'Tap the button below to add locations',
              style: TextStyle(color: AppTheme.textLight),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMarkersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _markers.length,
      itemBuilder: (context, index) {
        final marker = _markers[index];
        return _MarkerListTile(
          marker: marker,
          onTap: () => _viewMarker(marker),
          onRemove: widget.isOwner ? () => _removeMarker(marker) : null,
        );
      },
    );
  }

  void _viewMarker(MarkerModel marker) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForageLocationInfo(
          name: marker.name,
          description: marker.description,
          lat: marker.latitude,
          lng: marker.longitude,
          imageUrls: marker.imageUrls,
          timestamp: marker.timestamp.toString(),
          type: marker.type,
          markerOwner: marker.markerOwner,
          markerId: marker.id,
          status: marker.currentStatus,
          comments: marker.comments.map((c) => c.toMap()).toList(),
          statusHistory: marker.statusHistory.map((s) => s.toMap()).toList(),
        ),
      ),
    );
  }

  Future<void> _removeMarker(MarkerModel marker) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Location'),
        content: Text('Remove "${marker.name}" from this collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final collectionRepo = ref.read(collectionRepositoryProvider);
      await collectionRepo.removeMarkerFromCollection(
        userId: _collection.ownerEmail,
        collectionId: _collection.id,
        markerId: marker.id,
      );

      setState(() {
        _markers.removeWhere((m) => m.id == marker.id);
        _collection = _collection.copyWith(
          markerIds: _collection.markerIds.where((id) => id != marker.id).toList(),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location removed from collection')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e')),
        );
      }
    }
  }

  Future<void> _addMarkers() async {
    // Show a dialog to select markers to add
    final result = await _showAddMarkersDialog();
    if (result != null && result.isNotEmpty) {
      await _loadMarkers();
    }
  }

  Future<List<String>?> _showAddMarkersDialog() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.email == null) return null;

    final markerRepo = ref.read(markerRepositoryProvider);
    final userMarkers = await markerRepo.getByUserId(currentUser!.email!);

    // Filter out markers already in the collection
    final availableMarkers = userMarkers
        .where((m) => !_collection.markerIds.contains(m.id))
        .toList();

    if (availableMarkers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No more locations to add')),
        );
      }
      return null;
    }

    final selectedIds = <String>[];

    return showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Locations'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: availableMarkers.length,
              itemBuilder: (context, index) {
                final marker = availableMarkers[index];
                final isSelected = selectedIds.contains(marker.id);
                return CheckboxListTile(
                  title: Text(marker.name),
                  subtitle: Text(marker.type),
                  value: isSelected,
                  onChanged: (value) {
                    setDialogState(() {
                      if (value == true) {
                        selectedIds.add(marker.id);
                      } else {
                        selectedIds.remove(marker.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedIds.isEmpty
                  ? null
                  : () async {
                      // Add selected markers to collection
                      final collectionRepo = ref.read(collectionRepositoryProvider);
                      for (final markerId in selectedIds) {
                        await collectionRepo.addMarkerToCollection(
                          userId: _collection.ownerEmail,
                          collectionId: _collection.id,
                          markerId: markerId,
                        );
                      }

                      // Update local state
                      setState(() {
                        _collection = _collection.copyWith(
                          markerIds: [..._collection.markerIds, ...selectedIds],
                        );
                      });

                      if (context.mounted) {
                        Navigator.pop(context, selectedIds);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: Text('Add (${selectedIds.length})'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editCollection() async {
    final nameController = TextEditingController(text: _collection.name);
    final descController = TextEditingController(text: _collection.description ?? '');
    bool isPublic = _collection.isPublic;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Collection'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Public'),
                  value: isPublic,
                  onChanged: (value) => setDialogState(() => isPublic = value),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name is required')),
                  );
                  return;
                }

                final collectionRepo = ref.read(collectionRepositoryProvider);
                await collectionRepo.updateCollection(
                  userId: _collection.ownerEmail,
                  collectionId: _collection.id,
                  name: nameController.text.trim(),
                  description: descController.text.trim().isNotEmpty
                      ? descController.text.trim()
                      : null,
                  isPublic: isPublic,
                );

                setState(() {
                  _collection = _collection.copyWith(
                    name: nameController.text.trim(),
                    description: descController.text.trim().isNotEmpty
                        ? descController.text.trim()
                        : null,
                    isPublic: isPublic,
                  );
                });

                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collection updated')),
      );
    }
  }

  Future<void> _toggleSubscription() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.email == null) return;

    setState(() => _isSubscribing = true);

    try {
      final collectionRepo = ref.read(collectionRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      if (_isSubscribed) {
        // Get subscription to unsubscribe
        final subscription = await collectionRepo.getSubscriptionByCollectionId(
          userId: currentUser!.email!,
          ownerEmail: _collection.ownerEmail,
          collectionId: _collection.id,
        );

        if (subscription != null) {
          await collectionRepo.unsubscribe(
            userId: currentUser.email!,
            subscriptionId: subscription.id,
            ownerEmail: _collection.ownerEmail,
            collectionId: _collection.id,
          );
        }

        if (mounted) {
          setState(() {
            _isSubscribed = false;
            _isSubscribing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unsubscribed')),
          );
        }
      } else {
        // Subscribe
        final userData = await userRepo.getById(currentUser!.email!);

        await collectionRepo.subscribe(
          userId: currentUser.email!,
          ownerEmail: _collection.ownerEmail,
          collectionId: _collection.id,
          collectionName: _collection.name,
          collectionDescription: _collection.description,
          ownerDisplayName: _collection.ownerDisplayName,
          markerCount: _collection.markerIds.length,
          coverImageUrl: _collection.coverImageUrl,
        );

        if (mounted) {
          setState(() {
            _isSubscribed = true;
            _isSubscribing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscribed!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubscribing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

/// List tile for displaying a marker in the collection
class _MarkerListTile extends StatelessWidget {
  final MarkerModel marker;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _MarkerListTile({
    required this.marker,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: marker.imageUrls.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    marker.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.location_on,
                      color: AppTheme.primary,
                    ),
                  ),
                )
              : const Icon(
                  Icons.location_on,
                  color: AppTheme.primary,
                ),
        ),
        title: Text(marker.name),
        subtitle: Text(marker.type),
        trailing: onRemove != null
            ? IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: AppTheme.error,
                onPressed: onRemove,
              )
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
