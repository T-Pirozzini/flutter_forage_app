import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/models/forage_request.dart';
import 'package:flutter_forager_app/data/repositories/repository_providers.dart';
import 'package:flutter_forager_app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'components/respond_to_request_dialog.dart';
import 'components/contact_exchange_dialog.dart';
import 'components/notify_emergency_contact_dialog.dart';

/// Page for managing forage requests (incoming and outgoing).
///
/// Features:
/// - View incoming requests with ability to accept/decline
/// - View outgoing requests with ability to cancel
/// - View accepted requests pending contact exchange
/// - View completed connections
class ForageRequestsPage extends ConsumerStatefulWidget {
  const ForageRequestsPage({super.key});

  @override
  ConsumerState<ForageRequestsPage> createState() => _ForageRequestsPageState();
}

class _ForageRequestsPageState extends ConsumerState<ForageRequestsPage>
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
        body: Center(child: Text('Please sign in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Forage Requests',
          style: AppTheme.heading(size: 20, color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Incoming'),
            Tab(text: 'Outgoing'),
            Tab(text: 'Connections'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _IncomingRequestsTab(userEmail: currentUser!.email!),
          _OutgoingRequestsTab(userEmail: currentUser.email!),
          _ConnectionsTab(userEmail: currentUser.email!),
        ],
      ),
    );
  }
}

/// Tab for incoming forage requests
class _IncomingRequestsTab extends ConsumerWidget {
  final String userEmail;

  const _IncomingRequestsTab({required this.userEmail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forageRequestRepo = ref.watch(forageRequestRepositoryProvider);

    return StreamBuilder<List<ForageRequest>>(
      stream: forageRequestRepo.streamIncomingRequests(userEmail),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return _buildEmptyState(
            Icons.inbox,
            'No incoming requests',
            'When someone wants to forage with you, their request will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _IncomingRequestCard(request: requests[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppTheme.textMedium.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(title, style: AppTheme.title(size: 18, color: AppTheme.textMedium)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTheme.body(size: 14, color: AppTheme.textMedium),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card for displaying an incoming request
class _IncomingRequestCard extends ConsumerWidget {
  final ForageRequest request;

  const _IncomingRequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    request.fromUsername.isNotEmpty
                        ? request.fromUsername[0].toUpperCase()
                        : '?',
                    style: AppTheme.title(color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.fromUsername,
                        style: AppTheme.title(size: 16),
                      ),
                      Text(
                        'Wants to forage with you',
                        style: AppTheme.caption(size: 12, color: AppTheme.success),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(request.createdAt),
                  style: AppTheme.caption(size: 11, color: AppTheme.textMedium),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                request.message,
                style: AppTheme.body(size: 14),
              ),
            ),

            const SizedBox(height: 14),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineRequest(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: BorderSide(color: AppTheme.error),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptRequest(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptRequest(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => RespondToRequestDialog(
        senderUsername: request.fromUsername,
        isAccepting: true,
      ),
    );

    if (result != null) {
      try {
        final forageRequestRepo = ref.read(forageRequestRepositoryProvider);
        await forageRequestRepo.acceptRequest(
          requestId: request.id,
          responseMessage: result['message'],
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Request accepted! Share your contact info to connect.'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _declineRequest(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => RespondToRequestDialog(
        senderUsername: request.fromUsername,
        isAccepting: false,
      ),
    );

    if (result != null) {
      try {
        final forageRequestRepo = ref.read(forageRequestRepositoryProvider);
        await forageRequestRepo.declineRequest(
          requestId: request.id,
          responseMessage: result['message'],
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Request declined.'),
              backgroundColor: AppTheme.info,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}

/// Tab for outgoing forage requests
class _OutgoingRequestsTab extends ConsumerWidget {
  final String userEmail;

  const _OutgoingRequestsTab({required this.userEmail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forageRequestRepo = ref.watch(forageRequestRepositoryProvider);

    return StreamBuilder<List<ForageRequest>>(
      stream: forageRequestRepo.streamOutgoingRequests(userEmail),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return _buildEmptyState(
            Icons.send,
            'No outgoing requests',
            'Requests you send to other foragers will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _OutgoingRequestCard(
              request: requests[index],
              userEmail: userEmail,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppTheme.textMedium.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(title, style: AppTheme.title(size: 18, color: AppTheme.textMedium)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTheme.body(size: 14, color: AppTheme.textMedium),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card for displaying an outgoing request
class _OutgoingRequestCard extends ConsumerWidget {
  final ForageRequest request;
  final String userEmail;

  const _OutgoingRequestCard({
    required this.request,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    request.toUsername.isNotEmpty
                        ? request.toUsername[0].toUpperCase()
                        : '?',
                    style: AppTheme.title(color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.toUsername,
                        style: AppTheme.title(size: 16),
                      ),
                      Row(
                        children: [
                          Icon(Icons.pending, size: 14, color: AppTheme.warning),
                          const SizedBox(width: 4),
                          Text(
                            'Pending response',
                            style: AppTheme.caption(size: 12, color: AppTheme.warning),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(request.createdAt),
                  style: AppTheme.caption(size: 11, color: AppTheme.textMedium),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Message sent
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your message:',
                    style: AppTheme.caption(size: 11, color: AppTheme.textMedium),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.message,
                    style: AppTheme.body(size: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _cancelRequest(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: BorderSide(color: AppTheme.error),
                ),
                child: const Text('Cancel Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelRequest(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: Text('Are you sure you want to cancel your request to ${request.toUsername}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final forageRequestRepo = ref.read(forageRequestRepositoryProvider);
        await forageRequestRepo.cancelRequest(request.id, userEmail);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request cancelled.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}

/// Tab for accepted connections (pending and completed contact exchange)
class _ConnectionsTab extends ConsumerWidget {
  final String userEmail;

  const _ConnectionsTab({required this.userEmail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forageRequestRepo = ref.watch(forageRequestRepositoryProvider);

    return StreamBuilder<List<ForageRequest>>(
      stream: forageRequestRepo.streamPendingContactExchange(userEmail),
      builder: (context, pendingSnapshot) {
        return StreamBuilder<List<ForageRequest>>(
          stream: forageRequestRepo.streamCompletedConnections(userEmail),
          builder: (context, completedSnapshot) {
            if (pendingSnapshot.connectionState == ConnectionState.waiting ||
                completedSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final pending = pendingSnapshot.data ?? [];
            final completed = completedSnapshot.data ?? [];

            if (pending.isEmpty && completed.isEmpty) {
              return _buildEmptyState(
                Icons.handshake,
                'No connections yet',
                'When you and another forager both accept, you\'ll be able to exchange contact info here.',
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (pending.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Pending Contact Exchange',
                      style: AppTheme.title(size: 14, color: AppTheme.textMedium),
                    ),
                  ),
                  ...pending.map((r) => _ConnectionCard(
                        request: r,
                        userEmail: userEmail,
                        isPendingExchange: true,
                      )),
                ],
                if (completed.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Connected',
                      style: AppTheme.title(size: 14, color: AppTheme.textMedium),
                    ),
                  ),
                  ...completed.map((r) => _ConnectionCard(
                        request: r,
                        userEmail: userEmail,
                        isPendingExchange: false,
                      )),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppTheme.textMedium.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(title, style: AppTheme.title(size: 18, color: AppTheme.textMedium)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTheme.body(size: 14, color: AppTheme.textMedium),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card for displaying a connection
class _ConnectionCard extends ConsumerWidget {
  final ForageRequest request;
  final String userEmail;
  final bool isPendingExchange;

  const _ConnectionCard({
    required this.request,
    required this.userEmail,
    required this.isPendingExchange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUsername = request.getOtherUsername(userEmail);
    final isSender = request.fromEmail == userEmail;

    // Get contact info for display
    final myContactMethod = isSender ? request.fromContactMethod : request.toContactMethod;
    final myContactInfo = isSender ? request.fromContactInfo : request.toContactInfo;
    final theirContactMethod = isSender ? request.toContactMethod : request.fromContactMethod;
    final theirContactInfo = isSender ? request.toContactInfo : request.fromContactInfo;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.success,
                  child: Text(
                    otherUsername.isNotEmpty ? otherUsername[0].toUpperCase() : '?',
                    style: AppTheme.title(color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(otherUsername, style: AppTheme.title(size: 16)),
                      Row(
                        children: [
                          Icon(
                            isPendingExchange ? Icons.pending : Icons.check_circle,
                            size: 14,
                            color: isPendingExchange ? AppTheme.warning : AppTheme.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPendingExchange ? 'Exchange contact info' : 'Connected',
                            style: AppTheme.caption(
                              size: 12,
                              color: isPendingExchange ? AppTheme.warning : AppTheme.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (isPendingExchange) ...[
              // Show button to share contact info
              if (myContactInfo == null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showContactExchangeDialog(context, ref),
                    icon: const Icon(Icons.share),
                    label: const Text('Share Your Contact Info'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: AppTheme.success, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'You shared: $myContactMethod',
                        style: AppTheme.caption(color: AppTheme.success),
                      ),
                    ],
                  ),
                ),

              if (theirContactInfo == null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_empty, color: AppTheme.warning, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Waiting for $otherUsername to share their info',
                        style: AppTheme.caption(color: AppTheme.warning),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              // Show contact info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$otherUsername\'s contact:',
                      style: AppTheme.caption(size: 11, color: AppTheme.textMedium),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _getContactIcon(theirContactMethod ?? ''),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            theirContactInfo ?? 'Not shared',
                            style: AppTheme.body(size: 14, weight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Notify Emergency Contacts button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showNotifyEmergencyContactDialog(context, otherUsername),
                  icon: Icon(Icons.security, size: 18, color: AppTheme.warning),
                  label: const Text('Notify Emergency Contacts'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warning,
                    side: BorderSide(color: AppTheme.warning),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _getContactIcon(String method) {
    IconData icon;
    Color color;

    switch (method.toLowerCase()) {
      case 'facebook':
        icon = Icons.facebook;
        color = const Color(0xFF1877F2);
        break;
      case 'discord':
        icon = Icons.chat;
        color = const Color(0xFF5865F2);
        break;
      case 'email':
        icon = Icons.email;
        color = AppTheme.info;
        break;
      case 'phone':
        icon = Icons.phone;
        color = AppTheme.success;
        break;
      default:
        icon = Icons.link;
        color = AppTheme.textMedium;
    }

    return Icon(icon, size: 20, color: color);
  }

  Future<void> _showContactExchangeDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => const ContactExchangeDialog(),
    );

    if (result != null) {
      try {
        final forageRequestRepo = ref.read(forageRequestRepositoryProvider);
        final isSender = request.fromEmail == userEmail;

        if (isSender) {
          await forageRequestRepo.updateSenderContact(
            requestId: request.id,
            contactMethod: result['method']!,
            contactInfo: result['info']!,
          );
        } else {
          await forageRequestRepo.updateRecipientContact(
            requestId: request.id,
            contactMethod: result['method']!,
            contactInfo: result['info']!,
          );
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Contact info shared!'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  Future<void> _showNotifyEmergencyContactDialog(BuildContext context, String partnerUsername) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => NotifyEmergencyContactDialog(
        partnerUsername: partnerUsername,
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Emergency contacts notified!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }
}
