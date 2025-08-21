import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Category {
  final String name;
  final Color color;
  final IconData icon;

  Category({required this.name, required this.color, required this.icon});
}

final List<Category> categories = [
  Category(
    name: 'Food',
    color: Colors.orangeAccent,
    icon: FontAwesomeIcons.burger,
  ),
  Category(
    name: 'Transport',
    color: Colors.blueAccent,
    icon: Icons.directions_bus,
  ),
  Category(
    name: 'Shopping',
    color: Colors.purpleAccent,
    icon: Icons.shopping_cart_outlined,
  ),
  Category(
    name: 'Entertainment',
    color: Colors.green,
    icon: Icons.movie_outlined,
  ),
  Category(name: 'Game', color: Colors.pink, icon: Icons.videogame_asset),
  Category(name: 'Bills', color: Colors.amber, icon: Icons.lightbulb_outline),
  Category(
    name: 'Health',
    color: Colors.redAccent,
    icon: Icons.health_and_safety,
  ),
  Category(name: 'Education', color: Colors.teal, icon: Icons.school_outlined),
  Category(
    name: 'Groceries',
    color: Colors.brown,
    icon: Icons.local_grocery_store,
  ),
  Category(name: 'Travel', color: Colors.cyan, icon: Icons.flight_takeoff),
  Category(
    name: 'Fuel',
    color: Colors.deepOrange,
    icon: Icons.local_gas_station,
  ),
  Category(
    name: 'Subscriptions',
    color: Colors.indigo,
    icon: Icons.subscriptions,
  ),
  Category(name: 'Gifts', color: Colors.pinkAccent, icon: Icons.card_giftcard),
  Category(name: 'Sports', color: Colors.lightGreen, icon: Icons.sports_soccer),
  Category(name: 'Pets', color: Colors.lime, icon: Icons.pets),
  Category(name: 'Taxes', color: Colors.grey, icon: Icons.account_balance),
  Category(name: 'Rent', color: Colors.blueGrey, icon: Icons.home_outlined),
  Category(name: 'Salary', color: Colors.greenAccent, icon: Icons.attach_money),
  Category(
    name: 'Investment',
    color: Colors.deepPurple,
    icon: Icons.trending_up,
  ),
  Category(
    name: 'Miscellaneous',
    color: Colors.tealAccent,
    icon: Icons.more_horiz,
  ),
  Category(name: 'Utilities', color: Colors.lightBlue, icon: Icons.power),
  Category(name: 'Insurance', color: Colors.red.shade200, icon: Icons.security),
];
