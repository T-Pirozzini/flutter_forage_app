import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forager_app/components/screen_heading.dart';
import 'package:flutter_forager_app/shared/styled_text.dart';
import 'package:flutter_forager_app/theme.dart';
import 'package:intl/intl.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String? username;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsername() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.email)
        .get();

    if (userDoc.exists) {
      setState(() {
        username = userDoc.data()?['username'];
      });
    }
  }

  Future<void> _submit({
    required String collection,
    required String field,
    required TextEditingController controller,
    required String successMsg,
    required String errorMsg,
  }) async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection(collection).add({
        'userId': currentUser.uid,
        'userEmail': currentUser.email!,
        'username': username ?? currentUser.email!.split('@')[0],
        field: text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      controller.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(successMsg)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$errorMsg: $e')));
    }
  }

  Widget _buildInputSection({
    required String title,
    required String hint,
    required TextEditingController controller,
    required VoidCallback onSubmit,
    int maxLines = 4,
    String buttonText = 'Submit',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          maxLines: maxLines,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
            child: Text(buttonText),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildIntroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      color: AppColors.titleBarColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StyledText('Welcome Back to Forager!'),
          const SizedBox(height: 8),
          Text(
            'I’m truly sorry for the lack of updates over the past months. '
            'Your continued support means the world, and I’m committed to making '
            'this app better than ever. Please share your ideas and feedback below, '
            'and let’s build a community worth exploring together!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Buy Me a Coffee link coming soon!'),
                  ),
                );
              },
              child: const Text(
                'Support the App via Buy Me a Coffee',
                style: TextStyle(color: Colors.deepOrange),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final timeFormat = DateFormat('MMM d, yyyy h:mm a');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 32.0),
              child: Text('No messages yet. Start the conversation!'),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] as Timestamp?;
            final displayName = data['username'] ??
                data['userEmail']?.split('@')[0] ??
                'Anonymous';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.deepOrange.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                        if (timestamp != null)
                          Text(
                            timeFormat.format(timestamp.toDate()),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(data['message'] ?? ''),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ScreenHeading(title: 'Feedback & Community Board'),
          _buildIntroSection(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputSection(
                    title: 'Share Your Feedback',
                    hint: 'What features would you like to see?',
                    controller: _feedbackController,
                    onSubmit: () => _submit(
                      collection: 'Feedback',
                      field: 'feedback',
                      controller: _feedbackController,
                      successMsg: 'Feedback submitted successfully!',
                      errorMsg: 'Failed to submit feedback',
                    ),
                    buttonText: 'Submit Feedback',
                  ),
                  const Divider(),
                  _buildInputSection(
                    title: 'Community Message Board',
                    hint: 'Post a message to the community...',
                    controller: _messageController,
                    onSubmit: () => _submit(
                      collection: 'Messages',
                      field: 'message',
                      controller: _messageController,
                      successMsg: 'Message posted successfully!',
                      errorMsg: 'Failed to post message',
                    ),
                    maxLines: 2,
                    buttonText: 'Post Message',
                  ),
                  _buildMessageList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
