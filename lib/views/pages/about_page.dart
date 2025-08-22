import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    const githubUrl = "https://github.com/fahim-foysal-097";

    return Scaffold(
      appBar: AppBar(title: const Text("About"), centerTitle: true),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 30, 18, 5),
            child: const Text(
              """Spendle is a lightweight personal expense tracker designed to help you take control of your finances with ease.

✨ Features:

📝 Log your daily expenses in just a few taps

📊 Track spending across multiple categories and view beautiful charts

💰 View your most recent transactions instantly

📅 Pick custom dates for your expenses

🎨 Clean, minimal, and distraction-free design

🔒 Your data is stored locally on your device - no internet required, no accounts, no hidden tracking.

Spendle is built for simplicity. Add, view, and manage your expenses quickly so you can focus on what matters: understanding where your money goes.""",
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 30, 10, 5),
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () => _launchURL(githubUrl),
              child: const Text("My GitHub"),
            ),
          ),
        ],
      ),
    );
  }
}
