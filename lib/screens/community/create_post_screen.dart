import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/core/utils/forage_type_utils.dart';
import 'package:flutter_forager_app/data/models/gamification_constants.dart';
import 'package:flutter_forager_app/data/models/marker.dart';
import 'package:flutter_forager_app/data/models/post.dart';
import 'package:flutter_forager_app/data/models/post_draft.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/shared/gamification/gamification_helper.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Screen for creating a community post from a forage location
///
/// Features:
/// - Select from user's locations
/// - Add community-specific description (separate from private notes)
/// - Preview points earned
/// - Save as draft, schedule, or post immediately
class CreatePostScreen extends ConsumerStatefulWidget {
  /// Optional pre-selected marker
  final MarkerModel? preselectedMarker;

  const CreatePostScreen({
    this.preselectedMarker,
    super.key,
  });

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _descriptionController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser!;

  MarkerModel? _selectedMarker;
  List<MarkerModel> _userMarkers = [];
  bool _isLoading = true;
  bool _isPosting = false;
  DateTime? _scheduledDate;

  @override
  void initState() {
    super.initState();
    _selectedMarker = widget.preselectedMarker;
    _loadUserMarkers();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserMarkers() async {
    try {
      final markers = await ref
          .read(markerRepositoryProvider)
          .getByUserId(_currentUser.email!);

      // Filter out markers that are already public (already shared)
      final unsharedMarkers = markers.where((m) => !m.isPublic).toList();

      setState(() {
        _userMarkers = unsharedMarkers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading locations: $e')),
        );
      }
    }
  }

  Future<void> _saveDraft() async {
    if (_selectedMarker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location first')),
      );
      return;
    }

    try {
      await ref.read(postDraftRepositoryProvider).createDraft(
            userId: _currentUser.email!,
            markerId: _selectedMarker!.id,
            markerName: _selectedMarker!.name,
            markerType: _selectedMarker!.type,
            communityDescription: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft saved!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving draft: $e')),
        );
      }
    }
  }

  Future<void> _schedulePost() async {
    if (_selectedMarker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location first')),
      );
      return;
    }

    // Show date/time picker
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null || !mounted) return;

    final scheduledDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    try {
      await ref.read(postDraftRepositoryProvider).createDraft(
            userId: _currentUser.email!,
            markerId: _selectedMarker!.id,
            markerName: _selectedMarker!.name,
            markerType: _selectedMarker!.type,
            communityDescription: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            scheduledFor: scheduledDateTime,
          );

      if (mounted) {
        final formattedDate =
            DateFormat('MMM d, h:mm a').format(scheduledDateTime);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post scheduled for $formattedDate')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scheduling post: $e')),
        );
      }
    }
  }

  Future<void> _shareNow() async {
    if (_selectedMarker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location first')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      final postRepo = ref.read(postRepositoryProvider);

      // Create the post with community description
      final communityDescription = _descriptionController.text.trim().isEmpty
          ? _selectedMarker!.description
          : _descriptionController.text.trim();

      final post = PostModel(
        id: '', // Will be auto-generated
        name: _selectedMarker!.name,
        description: communityDescription,
        type: _selectedMarker!.type,
        imageUrls: _selectedMarker!.imageUrls,
        userEmail: _currentUser.email!,
        postTimestamp: DateTime.now(),
        latitude: _selectedMarker!.latitude,
        longitude: _selectedMarker!.longitude,
        likeCount: 0,
        likedBy: [],
        bookmarkCount: 0,
        bookmarkedBy: [],
        commentCount: 0,
        originalMarkerOwner: _selectedMarker!.markerOwner,
        comments: [],
        currentStatus: _selectedMarker!.currentStatus,
        statusHistory:
            _selectedMarker!.statusHistory.map((s) => s.toMap()).toList(),
      );

      await postRepo.create(post);

      // Update marker visibility to public
      await ref.read(markerRepositoryProvider).updateVisibility(
            markerId: _selectedMarker!.id,
            visibility: MarkerVisibility.public,
          );

      // Award points
      if (mounted) {
        await GamificationHelper.awardLocationShared(
          context: context,
          ref: ref,
          userId: _currentUser.email!,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Posted! +${PointRewards.shareLocation} points'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      appBar: AppBar(
        title: Text(
          'Share a Find',
          style: AppTheme.title(size: 20, color: AppTheme.textWhite),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.textWhite,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Points preview banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.success.withValues(alpha: 0.2),
                          AppTheme.accent.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: AppTheme.secondary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Earn ${PointRewards.shareLocation} points!',
                                style: AppTheme.body(
                                  size: 15,
                                  weight: FontWeight.w600,
                                  color: AppTheme.textWhite,
                                ),
                              ),
                              Text(
                                'Share your find with the community',
                                style: AppTheme.caption(
                                  size: 12,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Location selector
                  Text(
                    'Select a Location',
                    style: AppTheme.body(
                      size: 16,
                      weight: FontWeight.w600,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_userMarkers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.textLight.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 48,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No unshared locations',
                            style: AppTheme.body(
                              size: 14,
                              color: AppTheme.textLight,
                            ),
                          ),
                          Text(
                            'Create a marker on the map first!',
                            style: AppTheme.caption(
                              size: 12,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.textLight.withValues(alpha: 0.2),
                        ),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _userMarkers.length,
                        itemBuilder: (context, index) {
                          final marker = _userMarkers[index];
                          final isSelected = _selectedMarker?.id == marker.id;

                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: ForageTypeUtils.getTypeColor(marker.type)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Image.asset(
                                  'lib/assets/images/${marker.type.toLowerCase()}_marker.png',
                                  width: 24,
                                  height: 24,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.location_on,
                                    color: ForageTypeUtils.getTypeColor(
                                        marker.type),
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              marker.name,
                              style: TextStyle(
                                color: AppTheme.textWhite,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              '${marker.type} • ${DateFormat('MMM d').format(marker.timestamp)}',
                              style: TextStyle(
                                color: AppTheme.textLight,
                                fontSize: 12,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle,
                                    color: AppTheme.accent)
                                : Icon(Icons.circle_outlined,
                                    color: AppTheme.textLight),
                            selected: isSelected,
                            selectedTileColor:
                                AppTheme.accent.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            onTap: () {
                              setState(() => _selectedMarker = marker);
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Community description
                  Text(
                    'Community Description (Optional)',
                    style: AppTheme.body(
                      size: 16,
                      weight: FontWeight.w600,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add a public-facing description different from your private notes',
                    style: AppTheme.caption(
                      size: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: TextStyle(color: AppTheme.textWhite),
                    decoration: InputDecoration(
                      hintText:
                          'Share tips, directions, or what makes this spot special...',
                      hintStyle: TextStyle(color: AppTheme.textLight),
                      filled: true,
                      fillColor: AppTheme.backgroundDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.textLight.withValues(alpha: 0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.textLight.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.accent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saveDraft,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save Draft'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textLight,
                            side: BorderSide(color: AppTheme.textLight),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _schedulePost,
                          icon: const Icon(Icons.schedule),
                          label: const Text('Schedule'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accent,
                            side: BorderSide(color: AppTheme.accent),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isPosting || _selectedMarker == null
                          ? null
                          : _shareNow,
                      icon: _isPosting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(_isPosting ? 'Sharing...' : 'Share Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
