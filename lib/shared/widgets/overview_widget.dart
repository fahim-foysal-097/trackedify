import 'package:flutter/material.dart';
import 'package:spendle/shared/constants/text_constant.dart';

class OverviewWidget extends StatelessWidget {
  const OverviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 200, 30, 20),
      child: Stack(
        children: [
          Container(
            height: 220,
            // height: MediaQuery.of(context).size.width / 2,
            // width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.secondary,
                  Theme.of(context).colorScheme.tertiary,
                ],
                transform: const GradientRotation(3.1416 / 4),
              ),
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                  spreadRadius: 5,
                  blurRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              width: double.infinity,
              // child: Image.asset('assets/img/cc.png', fit: BoxFit.values.reversed),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 26, 0, 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Balance ^',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 0),
                Text(r'$2,544.00', style: KTextstyle.headerText),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 140, 0, 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Income', style: KTextstyle.smallHeaderText),
                SizedBox(height: 0),
                Text(r'$1,800.00', style: KTextstyle.moneySmallText),
              ],
            ),
          ),
          Container(
            alignment: Alignment.bottomRight,
            padding: const EdgeInsets.fromLTRB(0, 140, 20, 5),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expenses', style: KTextstyle.smallHeaderText),
                SizedBox(height: 0),
                Text(r'$285.00', style: KTextstyle.moneySmallText),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(0, 40, 20, 0),
            alignment: Alignment.bottomRight,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFd9ed92),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const SizedBox(width: 50, height: 50),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(0, 40, 50, 0),
            alignment: Alignment.bottomRight,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFb5e48c),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const SizedBox(width: 50, height: 50),
            ),
          ),
        ],
      ),
    );
  }
}
