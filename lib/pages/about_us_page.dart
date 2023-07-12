import 'package:flutter/material.dart';
import 'package:flutter_forager_app/pages/home_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  // Open the personal website link
  void _launchWebsite() async {
    const url =
        'https://portfolio-2023-1a61.fly.dev/'; // Replace with your personal website URL
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Open the LinkedIn profile link
  void _launchLinkedIn() async {
    const url =
        'https://www.linkedin.com/in/travis-pirozzini-2522b5115/'; // Replace with your LinkedIn profile URL
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Open the GitHub profile link
  void _launchGitHub() async {
    const url =
        'https://github.com/T-Pirozzini'; // Replace with your GitHub profile URL
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ABOUT US'),
        titleTextStyle:
            GoogleFonts.philosopher(fontSize: 24, fontWeight: FontWeight.bold),
        centerTitle: true,
        backgroundColor: Colors.deepOrange.shade400,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HomePage(
                  lat: 0,
                  lng: 0,
                  followUser: true,
                  currentIndex: 0,
                ),
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.green.withOpacity(0.7),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Center(
              child: Text(
                'This project is created by the developers Travis Pirozzini and Richard Au.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                height: 550,
                child: Image.asset('lib/assets/images/travis_about.jpg'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                height: 550,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Linkify(
                      onOpen: (link) async {
                        if (await canLaunch(link.url)) {
                          await launch(link.url);
                        } else {
                          throw 'Could not launch ${link.url}';
                        }
                      },
                      text:
                          'Richard Au is a senior at the University of Pittsburgh studying Computer Science. He is from Pittsburgh, PA and enjoys playing video games and watching movies.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _launchWebsite,
                          child: const Text('Personal Website'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _launchLinkedIn,
                          child: const Text('LinkedIn'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _launchGitHub,
                          child: const Text('GitHub'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
