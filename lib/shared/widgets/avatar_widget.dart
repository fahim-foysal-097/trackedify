import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 260, 0, 0),
      child: Container(
        alignment: Alignment.center,
        height: 170,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(
                255,
                71,
                90,
                100,
              ).withValues(alpha: 0.2),
              spreadRadius: 2,
              blurRadius: 4,
              offset: const Offset(0, 0),
            ),
          ],
          // color: Colors.red,
        ),
        child: const CircleAvatar(
          radius: 80,
          backgroundImage: AssetImage('assets/img/pfp.png'),
        ),
      ),
    );
  }
}
