import 'package:flutter/material.dart';
import 'package:mailto/mailto.dart';
import 'package:url_launcher/url_launcher.dart';

class UserFeedback extends StatelessWidget {
  final String? userName;
  final String? userEmail;
  final feedbackController = TextEditingController();

  UserFeedback({Key? key, required this.userName, required this.userEmail})
      : super(key: key);

  launchMailto() async {
    final mailtoLink = Mailto(
      to: ['tpirozzini@gmail.com'],
      subject: 'App Feedback from $userName, $userEmail',
      body: feedbackController.text,
    );

    await launch('$mailtoLink');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(
            "Suggestions/Feedback?",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10.0),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: feedbackController,
                decoration: InputDecoration(
                    hintText: 'Share your thoughts...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[400])),
                style: TextStyle(color: Colors.white),
                maxLines: 5,
              ),
            ),
          ),
          Text(
            "Help us improve the app!",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10.0),
          ElevatedButton(
            onPressed: launchMailto,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              child: Text(
                'Submit Feedback',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
