import 'package:flutter/material.dart';
import 'package:flutter_forager_app/pages/home_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  // Open the personal website link
  void _launchWebsiteTravis() async {
    const url = 'https://portfolio-2023-1a61.fly.dev/';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _launchWebsiteRichard() async {
    const url = 'Add your website url here';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Open the LinkedIn profile link
  void _launchLinkedInTravis() async {
    const url = 'https://www.linkedin.com/in/travis-pirozzini-2522b5115/';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _launchLinkedInRichard() async {
    const url = 'https://www.linkedin.com/in/aurichard4/';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Open the GitHub profile link
  void _launchGitHubTravis() async {
    const url = 'https://github.com/T-Pirozzini';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _launchGitHubRichard() async {
    const url = 'https://github.com/au-richard';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  Image.asset(
                    'lib/assets/images/travis_about.jpg',
                  ),
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Travis Pirozzini',
                          style: GoogleFonts.philosopher(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const Text(
                          'Full-Stack',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.start,
                        ),
                        const Text('Mobile(Flutter) & Web(React) Developer',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const Text('UI/UX Certified',
                            style: TextStyle(color: Colors.white)),
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'Whether I\'m in the mountains, slaying an Ancient Blue Dragon with friends, or learning to code - I seek the challenge. Software Development is a continuous journey that allows me to bring my dreams to life through dedication and creative solutions... and I\'m just getting started.',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'I\'m currently open to employment (contract/full & part-time). Please contact me if you\'re interested in working together!',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _launchWebsiteTravis,
                              icon: const FaIcon(FontAwesomeIcons
                                  .person), // Icon for Personal Website
                              label: const Text('Portfolio'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _launchLinkedInTravis,
                              icon: const FaIcon(FontAwesomeIcons
                                  .linkedin), // Icon for LinkedIn
                              label: const Text('LinkedIn'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _launchGitHubTravis,
                              icon: const FaIcon(
                                  FontAwesomeIcons.github), // Icon for GitHub
                              label: const Text('GitHub'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  Image.asset(
                    'lib/assets/images/missing_image.png',
                  ),
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Richard Au',
                          style: GoogleFonts.philosopher(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const Text(
                          'Write your description here...',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _launchWebsiteRichard,
                              icon: const FaIcon(FontAwesomeIcons
                                  .person), // Icon for Personal Website
                              label: const Text('Portfolio'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _launchLinkedInRichard,
                              icon: const FaIcon(FontAwesomeIcons
                                  .linkedin), // Icon for LinkedIn
                              label: const Text('LinkedIn'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _launchGitHubRichard,
                              icon: const FaIcon(
                                  FontAwesomeIcons.github), // Icon for GitHub
                              label: const Text('GitHub'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
