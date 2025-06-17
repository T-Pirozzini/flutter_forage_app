import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_forager_app/models/recipe.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CommentsPage extends StatefulWidget {
  final Recipe recipe;

  const CommentsPage({required this.recipe, Key? key}) : super(key: key);

  @override
  _CommentsPageState createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _commentController = TextEditingController();
  final String _userEmail = FirebaseAuth.instance.currentUser!.email!;
  String? _username;
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _checkIfLiked();
    _likeCount = widget.recipe.likes.length;
  }

  Future<void> _fetchUsername() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(_userEmail)
          .get();
      if (userDoc.exists) {
        setState(() {
          _username = userDoc.get('username');
        });
      }
    } catch (e) {
      print('Error fetching username: $e');
    }
  }

  Future<void> _checkIfLiked() async {
    setState(() {
      _isLiked = widget.recipe.likes.contains(_userEmail);
    });
  }

  Future<void> _toggleLike() async {
    final recipeRef =
        FirebaseFirestore.instance.collection('Recipes').doc(widget.recipe.id);

    if (_isLiked) {
      await recipeRef.update({
        'likes': FieldValue.arrayRemove([_userEmail])
      });
      setState(() {
        _isLiked = false;
        _likeCount--;
      });
    } else {
      await recipeRef.update({
        'likes': FieldValue.arrayUnion([_userEmail])
      });
      setState(() {
        _isLiked = true;
        _likeCount++;
      });
    }
  }

  Future<void> _showLikesDialog() async {
    if (_likeCount == 0) return;

    // Fetch user details for each like
    final users = await Future.wait(
      widget.recipe.likes.map((email) async {
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(email)
            .get();
        return userDoc.exists ? userDoc.get('username') : email;
      }),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Liked by',
          style: GoogleFonts.josefinSans(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: users.length,
            itemBuilder: (context, index) => ListTile(
              leading: CircleAvatar(
                child: Text(users[index][0].toUpperCase()),
              ),
              title: Text(users[index],
                  style: GoogleFonts.josefinSans(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) {
      return;
    }

    final comment = {
      'userName': _username ?? _userEmail,
      'message': _commentController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('Recipes')
        .doc(widget.recipe.id)
        .collection('Comments')
        .add(comment);

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments',
            style: GoogleFonts.josefinSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            )),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Recipe header card
          Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe name and like button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.recipe.name,
                          style: GoogleFonts.josefinSans(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              color: _isLiked ? Colors.red : Colors.grey,
                            ),
                            onPressed: _toggleLike,
                          ),
                        ],
                      ),
                    ],
                  ),
                  _buildLikeCount(),
                  const SizedBox(height: 8),

                  // Description if exists
                  if (widget.recipe.description != null &&
                      widget.recipe.description!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          widget.recipe.description!,
                          style: GoogleFonts.josefinSans(fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),

                  // Recipe metadata
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'By ${widget.recipe.userName}',
                        style: GoogleFonts.josefinSans(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Text(
                        DateFormat.yMMMd().format(widget.recipe.timestamp),
                        style: GoogleFonts.josefinSans(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Comments section title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Comments',
                style: GoogleFonts.josefinSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Comments list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Recipes')
                  .doc(widget.recipe.id)
                  .collection('Comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final comments = snapshot.data!.docs;

                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      'No comments yet. Be the first to comment!',
                      style: GoogleFonts.josefinSans(),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final timestamp = comment['timestamp'] != null
                        ? (comment['timestamp'] as Timestamp).toDate()
                        : DateTime.now();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                                  comment['userName'],
                                  style: GoogleFonts.josefinSans(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM d, h:mm a').format(timestamp),
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              comment['message'],
                              style: GoogleFonts.josefinSans(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Add comment section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.deepOrange,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _addComment,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikeCount() {
    return GestureDetector(
      onTap: _showLikesDialog,
      child: Text(
        '$_likeCount ${_likeCount == 1 ? 'like' : 'likes'}',
        style: TextStyle(
          color: Colors.grey,
        ),
      ),
    );
  }
}
