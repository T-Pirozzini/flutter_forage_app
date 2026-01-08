import 'package:flutter/material.dart';
import 'package:flutter_forager_app/data/services/migration_service.dart';

/// Debug screen to run database migrations
///
/// Add this to your app temporarily to run the migration:
/// 1. Add a route to this screen
/// 2. Navigate to it
/// 3. Run dry run first
/// 4. Run actual migration
/// 5. Remove this screen after migration is complete
class MigrationScreen extends StatefulWidget {
  const MigrationScreen({super.key});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  final MigrationService _migrationService = MigrationService();
  bool _isRunning = false;
  MigrationResult? _lastResult;
  int? _markerCount;

  @override
  void initState() {
    super.initState();
    _countMarkers();
  }

  Future<void> _countMarkers() async {
    final count = await _migrationService.countMarkersToMigrate();
    setState(() {
      _markerCount = count;
    });
  }

  Future<void> _runMigration({required bool dryRun}) async {
    setState(() {
      _isRunning = true;
      _lastResult = null;
    });

    try {
      final result = await _migrationService.migrateMarkersToRootCollection(
        dryRun: dryRun,
      );

      setState(() {
        _lastResult = result;
        _isRunning = false;
      });

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(dryRun
                  ? 'Dry run complete! Would migrate ${result.migratedMarkers} markers'
                  : 'Migration complete! Migrated ${result.migratedMarkers} markers'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Migration failed with ${result.errorCount} errors'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isRunning = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Migration'),
        backgroundColor: Colors.orange,
      ),
      body: _isRunning
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Migration in progress...'),
                  Text('Check console for detailed output'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Warning Card
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Database Migration Tool',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'This will migrate all user markers from subcollections '
                            'to a root Markers collection.',
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '⚠️ Always run DRY RUN first!',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Marker Count
                  if (_markerCount != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Markers to Migrate',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_markerCount',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Dry Run Button
                  ElevatedButton.icon(
                    onPressed: _isRunning
                        ? null
                        : () => _runMigration(dryRun: true),
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('RUN DRY RUN (Safe Test)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Actual Migration Button
                  ElevatedButton.icon(
                    onPressed: _isRunning
                        ? null
                        : () => _showConfirmDialog(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('RUN ACTUAL MIGRATION'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Results
                  if (_lastResult != null) ...[
                    const Text(
                      'Last Migration Result',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: _lastResult!.success
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildResultRow(
                              'Total Markers:',
                              '${_lastResult!.totalMarkers}',
                            ),
                            _buildResultRow(
                              'Migrated:',
                              '${_lastResult!.migratedMarkers}',
                              color: Colors.green,
                            ),
                            _buildResultRow(
                              'Skipped:',
                              '${_lastResult!.skippedMarkers}',
                              color: Colors.orange,
                            ),
                            _buildResultRow(
                              'Errors:',
                              '${_lastResult!.errorCount}',
                              color: _lastResult!.errorCount > 0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            if (_lastResult!.errors.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Errors:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              ...(_lastResult!.errors.take(5).map((error) =>
                                  Text('• $error', style: const TextStyle(fontSize: 12)))),
                              if (_lastResult!.errors.length > 5)
                                Text(
                                  '... and ${_lastResult!.errors.length - 5} more',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Instructions
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instructions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('1. Tap "RUN DRY RUN" to test (no changes made)'),
                          Text('2. Check console output for details'),
                          Text('3. If dry run looks good, tap "RUN ACTUAL MIGRATION"'),
                          Text('4. Verify in Firebase Console'),
                          Text('5. Test the app'),
                          Text('6. Remove this debug screen'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildResultRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirm Migration'),
        content: const Text(
          'This will migrate ALL markers to the new collection structure.\n\n'
          'Have you:\n'
          '✓ Exported your Firestore database\n'
          '✓ Run the dry run successfully\n'
          '✓ Reviewed the dry run output\n\n'
          'Continue with actual migration?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Migrate Now'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _runMigration(dryRun: false);
    }
  }
}
