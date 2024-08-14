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

  @override
  void initState() {
    super.initState();
    _fetchUsername();
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
        title: Text(
          'COMMENTS',
          style: TextStyle(letterSpacing: 2.5),
        ),
        titleTextStyle:
            GoogleFonts.philosopher(fontSize: 24, fontWeight: FontWeight.bold),
        centerTitle: true,
        backgroundColor: Colors.deepOrange.shade300,
      ),
      body: Column(
        children: [
          // Recipe information
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipe.name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Submitted by: ${widget.recipe.userName}',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                    Text(
                      '${DateFormat.yMMMd().format(widget.recipe.timestamp)}',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ingredients:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          for (var ingredient in widget.recipe.ingredients)
                            Row(
                              children: [
                                Icon(
                                  ingredient.isForaged
                                      ? Icons.eco
                                      : Icons.shopping_cart,
                                  color: ingredient.isForaged
                                      ? Colors.green
                                      : Colors.grey,
                                  size: 20,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  '${ingredient.quantity} ${ingredient.name}',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instructions:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          for (var step in widget.recipe.steps.asMap().entries)
                            Text('${step.key + 1}. ${step.value}',
                                style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
          Divider(),
          // Comments section
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
                  return Center(child: Text('No comments yet.'));
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      title: Text(comment['userName']),
                      subtitle: Text(comment['message']),
                      trailing: comment['timestamp'] != null
                          ? Text(
                              '${DateFormat.yMMMd().format((comment['timestamp'] as Timestamp).toDate())}',
                            )
                          : Text('Just now'),
                    );
                  },
                );
              },
            ),
          ),
          // Add a comment
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      labelText: 'Add a comment...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
