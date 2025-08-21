import 'package:flutter/material.dart';
import 'package:spendle/shared/constants/text_constant.dart';

class WelcomeWidget extends StatelessWidget {
  const WelcomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(30, 100, 0, 0),
      child: Stack(
        children: [
          // GestureDetector(
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) {
          //           return const SettingsPage();
          //         },
          //       ),
          //     );
          //   },
          //   child: const Align(
          //     alignment: Alignment.topRight,
          //     child: Padding(
          //       padding: EdgeInsets.fromLTRB(0, 15, 22, 0),
          //       child: Icon(Icons.settings, size: 30, color: Colors.white),
          //     ),
          //   ),
          // ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text('Welcome back,', style: KTextstyle.smallHeaderText),
              Text('User Name', style: KTextstyle.headerText),
            ],
          ),
        ],
      ),
    );
  }
}
