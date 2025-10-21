// This was made by AI, no way im writing all this stuff

// Large dataset (many entries).
// (lib/shared/constants/icon_data.dart). Edit/add entries here.

import 'package:flutter/material.dart';
import 'package:trackedify/data/icon_and_color_data.dart';

/// Simple container for icon + color suggestions.
class CategoryData {
  final IconData icon;
  final Color color;
  const CategoryData(this.icon, this.color);
}

/// Safe helper: pick icon from iconCategories by category name and index.
/// If requested list / index is missing, fallback to Icons.tag.
IconData _iconFromCategory(String categoryName, int index) {
  try {
    final list = iconCategories[categoryName];
    if (list != null && index >= 0 && index < list.length) {
      return list[index];
    }
  } catch (_) {}
  return Icons.tag;
}

/// Public dataset: many keys (lowercase). Use _iconFromCategory(cat, idx)
/// to guarantee icons are taken from the canonical iconCategories map.
final Map<String, CategoryData> categoryDataset = {
  // ---------------- Food & Drink ----------------
  'groceries': CategoryData(_iconFromCategory('Food & Drink', 0), Colors.green),
  'grocery': CategoryData(_iconFromCategory('Food & Drink', 0), Colors.green),
  'supermarket': CategoryData(
    _iconFromCategory('Shopping', 7),
    Colors.green.shade700,
  ),
  'super market': CategoryData(
    _iconFromCategory('Shopping', 7),
    Colors.green.shade700,
  ),
  'food': CategoryData(_iconFromCategory('Food & Drink', 1), Colors.orange),
  'dining': CategoryData(_iconFromCategory('Food & Drink', 7), Colors.orange),
  'restaurant': CategoryData(
    _iconFromCategory('Food & Drink', 1),
    Colors.orange,
  ),
  'takeout': CategoryData(
    _iconFromCategory('Food & Drink', 20),
    Colors.orange.shade300,
  ),
  'take away': CategoryData(
    _iconFromCategory('Food & Drink', 20),
    Colors.orange.shade300,
  ),
  'coffee': CategoryData(_iconFromCategory('Food & Drink', 13), Colors.brown),
  'cafe': CategoryData(_iconFromCategory('Food & Drink', 2), Colors.brown),
  'tea': CategoryData(_iconFromCategory('Food & Drink', 12), Colors.brown),
  'bakery': CategoryData(_iconFromCategory('Food & Drink', 11), Colors.amber),
  'dessert': CategoryData(
    _iconFromCategory('Food & Drink', 9),
    Colors.pinkAccent,
  ),
  'pizza': CategoryData(
    _iconFromCategory('Food & Drink', 8),
    Colors.deepOrange,
  ),
  'ice cream': CategoryData(
    _iconFromCategory('Food & Drink', 9),
    Colors.pinkAccent,
  ),
  'bar': CategoryData(_iconFromCategory('Food & Drink', 3), Colors.deepOrange),
  'drinks': CategoryData(_iconFromCategory('Food & Drink', 10), Colors.amber),
  'juice': CategoryData(
    _iconFromCategory('Food & Drink', 10),
    Colors.orangeAccent,
  ),
  'snacks': CategoryData(_iconFromCategory('Food & Drink', 0), Colors.lime),

  // ---------------- Transport & Travel ----------------
  'transport': CategoryData(
    _iconFromCategory('Travel & Transport', 1),
    Colors.blue,
  ),
  'travel': CategoryData(
    _iconFromCategory('Travel & Transport', 0),
    Colors.yellow.shade700,
  ),
  'transportation': CategoryData(
    _iconFromCategory('Travel & Transport', 1),
    Colors.yellow.shade700,
  ),
  'taxi': CategoryData(
    _iconFromCategory('Travel & Transport', 11),
    Colors.yellow.shade700,
  ),
  'ride': CategoryData(
    _iconFromCategory('Travel & Transport', 1),
    Colors.yellow.shade700,
  ),
  'uber': CategoryData(
    _iconFromCategory('Travel & Transport', 1),
    Colors.yellow.shade700,
  ),
  'bus': CategoryData(
    _iconFromCategory('Travel & Transport', 3),
    Colors.yellow.shade700,
  ),
  'train': CategoryData(
    _iconFromCategory('Travel & Transport', 2),
    Colors.orange.shade700,
  ),
  'flight': CategoryData(
    _iconFromCategory('Travel & Transport', 0),
    Colors.indigo,
  ),
  'airplane': CategoryData(
    _iconFromCategory('Travel & Transport', 0),
    Colors.indigo,
  ),
  'airport': CategoryData(
    _iconFromCategory('Travel & Transport', 21),
    Colors.indigo,
  ),
  'hotel': CategoryData(
    _iconFromCategory('Travel & Transport', 8),
    Colors.teal,
  ),
  'vacation': CategoryData(
    _iconFromCategory('Travel & Transport', 14),
    Colors.cyan,
  ),
  'luggage': CategoryData(
    _iconFromCategory('Travel & Transport', 22),
    Colors.blueGrey,
  ),
  'ferry': CategoryData(
    _iconFromCategory('Travel & Transport', 10),
    Colors.blue,
  ),
  'boat': CategoryData(
    _iconFromCategory('Travel & Transport', 10),
    Colors.lightBlue,
  ),
  'parking': CategoryData(
    _iconFromCategory('Home & Utilities', 16),
    Colors.blueGrey,
  ),
  'toll': CategoryData(
    _iconFromCategory('Travel & Transport', 24),
    Colors.brown,
  ),
  'fuel': CategoryData(
    _iconFromCategory('Travel & Transport', 5),
    Colors.deepOrange,
  ),
  'diesel': CategoryData(
    _iconFromCategory('Travel & Transport', 5),
    Colors.deepOrange,
  ),
  'petrol': CategoryData(
    _iconFromCategory('Travel & Transport', 5),
    Colors.deepOrange,
  ),

  // ---------------- Home / Bills / Utilities ----------------
  'rent': CategoryData(
    _iconFromCategory('Home & Utilities', 23),
    Colors.indigo,
  ),
  'mortgage': CategoryData(
    _iconFromCategory('Home & Utilities', 23),
    Colors.indigo,
  ),
  'bills': CategoryData(_iconFromCategory('Home & Utilities', 3), Colors.blue),
  'utilities': CategoryData(
    _iconFromCategory('Home & Utilities', 3),
    Colors.lightBlue,
  ),
  'electricity': CategoryData(
    _iconFromCategory('Home & Utilities', 19),
    Colors.yellow,
  ),
  'water': CategoryData(
    _iconFromCategory('Health & Fitness', 12),
    Colors.lightBlue,
  ),
  'internet': CategoryData(
    _iconFromCategory('Technology', 9),
    Colors.blueAccent,
  ),
  'phone': CategoryData(_iconFromCategory('Technology', 1), Colors.blueAccent),
  'gas bill': CategoryData(
    _iconFromCategory('Home & Utilities', 18),
    Colors.deepOrange,
  ),
  'garbage': CategoryData(
    _iconFromCategory('Home & Utilities', 16),
    Colors.grey,
  ),
  'trash': CategoryData(_iconFromCategory('Other', 14), Colors.grey),
  'repair': CategoryData(
    _iconFromCategory('Home & Utilities', 21),
    Colors.brown,
  ),
  'maintenance': CategoryData(
    _iconFromCategory('Home & Utilities', 21),
    Colors.brown,
  ),
  'cleaning': CategoryData(
    _iconFromCategory('Home & Utilities', 2),
    Colors.brown,
  ), // ---------------- Health & Personal Care ----------------
  'health': CategoryData(
    _iconFromCategory('Health & Fitness', 0),
    Colors.purple,
  ),
  'medical': CategoryData(
    _iconFromCategory('Health & Fitness', 1),
    Colors.redAccent,
  ),
  'doctor': CategoryData(
    _iconFromCategory('Health & Fitness', 1),
    Colors.deepPurple,
  ),
  'dentist': CategoryData(
    _iconFromCategory('Health & Fitness', 1),
    Colors.deepPurple,
  ),
  'pharmacy': CategoryData(
    _iconFromCategory('Health & Fitness', 2),
    Colors.red,
  ),
  'hospital': CategoryData(
    _iconFromCategory('Health & Fitness', 1),
    Colors.deepPurple,
  ),
  'clinic': CategoryData(
    _iconFromCategory('Health & Fitness', 1),
    Colors.deepPurple,
  ),
  'fitness': CategoryData(
    _iconFromCategory('Health & Fitness', 3),
    Colors.teal,
  ),
  'gym': CategoryData(_iconFromCategory('Health & Fitness', 3), Colors.teal),
  'yoga': CategoryData(_iconFromCategory('Health & Fitness', 6), Colors.green),
  'spa': CategoryData(
    _iconFromCategory('Health & Fitness', 5),
    Colors.purpleAccent,
  ),
  'medical supplies': CategoryData(
    _iconFromCategory('Health & Fitness', 2),
    Colors.red,
  ),
  'wellness': CategoryData(
    _iconFromCategory('Health & Fitness', 0),
    Colors.deepPurple,
  ), // ---------------- Finance ----------------
  'income': CategoryData(
    _iconFromCategory('Finance', 12),
    Colors.green.shade700,
  ),
  'salary': CategoryData(
    _iconFromCategory('Finance', 12),
    Colors.green.shade700,
  ),
  'bonus': CategoryData(_iconFromCategory('Finance', 0), Colors.green),
  'savings': CategoryData(_iconFromCategory('Finance', 1), Colors.teal),
  'investment': CategoryData(_iconFromCategory('Finance', 15), Colors.indigo),
  'stocks': CategoryData(_iconFromCategory('Finance', 15), Colors.indigo),
  'crypto': CategoryData(_iconFromCategory('Finance', 14), Colors.orange),
  'tax': CategoryData(_iconFromCategory('Finance', 8), Colors.brown),
  'taxes': CategoryData(_iconFromCategory('Finance', 8), Colors.brown),
  'loan': CategoryData(_iconFromCategory('Finance', 2), Colors.brown),
  // 'insurance': CategoryData(_iconFromCategory('Other', 0), Colors.blueGrey),
  'bank': CategoryData(_iconFromCategory('Finance', 5), Colors.blueGrey),
  'atm': CategoryData(_iconFromCategory('Finance', 11), Colors.blueGrey),
  'payment': CategoryData(
    _iconFromCategory('Shopping', 9),
    Colors.deepPurple,
  ), // ---------------- Shopping & Services ----------------
  'shopping': CategoryData(_iconFromCategory('Shopping', 0), Colors.pinkAccent),
  'online shopping': CategoryData(
    _iconFromCategory('Shopping', 15),
    Colors.indigo,
  ),
  'clothing': CategoryData(_iconFromCategory('Shopping', 1), Colors.pink),
  'apparel': CategoryData(_iconFromCategory('Shopping', 1), Colors.pink),
  'electronics': CategoryData(
    _iconFromCategory('Technology', 0),
    Colors.blueGrey,
  ),
  'hardware': CategoryData(_iconFromCategory('Other', 10), Colors.brown),
  'beauty': CategoryData(
    _iconFromCategory('Beauty & Grooming', 0),
    Colors.purpleAccent,
  ),
  'salon': CategoryData(
    _iconFromCategory('Beauty & Grooming', 2),
    Colors.purpleAccent,
  ),
  'delivery': CategoryData(_iconFromCategory('Shopping', 16), Colors.green),
  'amazon': CategoryData(_iconFromCategory('Shopping', 16), Colors.green),
  'grocery delivery': CategoryData(
    _iconFromCategory('Shopping', 16),
    Colors.green,
  ), // ---------------- Entertainment & Leisure ----------------
  'entertainment': CategoryData(
    _iconFromCategory('Entertainment', 0),
    Colors.deepPurple,
  ),
  'movies': CategoryData(
    _iconFromCategory('Entertainment', 0),
    Colors.deepPurple,
  ),
  'streaming': CategoryData(
    _iconFromCategory('Entertainment', 14),
    Colors.deepPurple,
  ),
  'games': CategoryData(
    _iconFromCategory('Entertainment', 1),
    Colors.deepPurple,
  ),
  'steam': CategoryData(
    _iconFromCategory('Entertainment', 1),
    Colors.deepPurple,
  ),
  'concert': CategoryData(
    _iconFromCategory('Entertainment', 20),
    Colors.indigo,
  ),
  'theatre': CategoryData(
    _iconFromCategory('Entertainment', 3),
    Colors.deepPurple,
  ), // ---------------- Education & Work ----------------
  'education': CategoryData(_iconFromCategory('Education', 0), Colors.indigo),
  'study': CategoryData(_iconFromCategory('Education', 0), Colors.indigo),
  'books': CategoryData(_iconFromCategory('Education', 1), Colors.indigo),
  'courses': CategoryData(_iconFromCategory('Education', 3), Colors.indigo),
  'school fees': CategoryData(_iconFromCategory('Education', 0), Colors.indigo),
  'college fees': CategoryData(
    _iconFromCategory('Education', 0),
    Colors.indigo,
  ),
  'tution fees': CategoryData(_iconFromCategory('Education', 0), Colors.indigo),
  'office': CategoryData(
    _iconFromCategory('Work & Office', 0),
    Colors.blueGrey,
  ),
  'supplies': CategoryData(
    _iconFromCategory('Work & Office', 4),
    Colors.deepOrange,
  ), // ---------------- Family & Kids ----------------
  'childcare': CategoryData(
    _iconFromCategory('Family & Personal', 2),
    Colors.purple,
  ),
  'daycare': CategoryData(
    _iconFromCategory('Family & Personal', 2),
    Colors.purple,
  ),
  'kids': CategoryData(
    _iconFromCategory('Family & Personal', 2),
    Colors.pinkAccent,
  ),
  'baby': CategoryData(
    _iconFromCategory('Family & Personal', 11),
    Colors.pinkAccent,
  ),
  'pets': CategoryData(_iconFromCategory('Family & Personal', 0), Colors.teal),
  'pet care': CategoryData(
    _iconFromCategory('Family & Personal', 0),
    Colors.teal,
  ),
  'school': CategoryData(
    _iconFromCategory('Education', 0),
    Colors.indigo,
  ), // ---------------- Home & Garden ----------------
  'garden': CategoryData(
    _iconFromCategory('Gardening & Outdoor', 0),
    Colors.green,
  ),
  'plants': CategoryData(
    _iconFromCategory('Gardening & Outdoor', 4),
    Colors.green,
  ),
  'flowers': CategoryData(
    _iconFromCategory('Gardening & Outdoor', 1),
    Colors.pinkAccent,
  ),
  'landscaping': CategoryData(
    _iconFromCategory('Gardening & Outdoor', 2),
    Colors.green,
  ),
  'home improvement': CategoryData(
    _iconFromCategory('Home & Utilities', 21),
    Colors.brown,
  ),
  'furniture': CategoryData(
    _iconFromCategory('Home & Utilities', 11),
    Colors.brown,
  ),
  'decor': CategoryData(
    _iconFromCategory('Home & Utilities', 11),
    Colors.purple,
  ), // ---------------- Subscriptions & Digital ----------------
  'subscription': CategoryData(
    _iconFromCategory('Subscriptions', 0),
    Colors.deepPurple,
  ),
  'subscriptions': CategoryData(
    _iconFromCategory('Subscriptions', 0),
    Colors.deepPurple,
  ),
  'software': CategoryData(_iconFromCategory('Technology', 0), Colors.blueGrey),
  'apps': CategoryData(_iconFromCategory('Technology', 1), Colors.blueGrey),
  'hosting': CategoryData(
    _iconFromCategory('Technology', 16),
    Colors.indigo,
  ), // ---------------- Sports & Fitness ----------------
  'sports': CategoryData(_iconFromCategory('Sports', 0), Colors.orange),
  'fitness class': CategoryData(_iconFromCategory('Sports', 17), Colors.teal),
  'gym membership': CategoryData(
    _iconFromCategory('Health & Fitness', 3),
    Colors.teal,
  ),
  'ticket': CategoryData(
    _iconFromCategory('Entertainment', 22),
    Colors.deepPurple,
  ),
  'tickets': CategoryData(
    _iconFromCategory('Entertainment', 22),
    Colors.deepPurple,
  ), // ---------------- Gifts & Charity ----------------
  'gift': CategoryData(
    _iconFromCategory('Gifts & Donations', 0),
    Colors.pinkAccent,
  ),
  'present': CategoryData(
    _iconFromCategory('Gifts & Donations', 0),
    Colors.pinkAccent,
  ),
  'donation': CategoryData(
    _iconFromCategory('Gifts & Donations', 2),
    Colors.green,
  ), // ---------------- Insurance & Legal ----------------
  'insurance': CategoryData(
    _iconFromCategory('Insurance & Legal', 0),
    Colors.blueGrey,
  ),
  'policy': CategoryData(
    _iconFromCategory('Insurance & Legal', 0),
    Colors.blueGrey,
  ),
  'legal': CategoryData(
    _iconFromCategory('Insurance & Legal', 1),
    Colors.grey,
  ), // ---------------- Auto & Vehicle ----------------
  'auto': CategoryData(
    _iconFromCategory('Auto & Vehicle', 0),
    Colors.yellow.shade700,
  ),
  'car': CategoryData(
    _iconFromCategory('Auto & Vehicle', 0),
    Colors.yellow.shade700,
  ),
  'car repair': CategoryData(
    _iconFromCategory('Auto & Vehicle', 2),
    Colors.orange,
  ),
  'ev charging': CategoryData(
    _iconFromCategory('Auto & Vehicle', 3),
    Colors.teal,
  ), // ---------------- Technology & Gadgets ----------------
  'computer': CategoryData(_iconFromCategory('Technology', 0), Colors.blueGrey),
  'pc': CategoryData(_iconFromCategory('Technology', 0), Colors.blueGrey),
  'laptop': CategoryData(_iconFromCategory('Technology', 5), Colors.blueGrey),
  'phone bill': CategoryData(
    _iconFromCategory('Technology', 1),
    Colors.blueAccent,
  ),
  'internet bill': CategoryData(
    _iconFromCategory('Technology', 9),
    Colors.blueAccent,
  ), // ---------------- Hobbies & Crafts ----------------
  'hobby': CategoryData(_iconFromCategory('Hobbies & Crafts', 0), Colors.teal),
  'crafts': CategoryData(
    _iconFromCategory('Hobbies & Crafts', 0),
    Colors.purple,
  ),
  'craft supplies': CategoryData(
    _iconFromCategory('Hobbies & Crafts', 0),
    Colors.deepOrange,
  ), // ---------------- Other / Misc ----------------
  'misc': CategoryData(_iconFromCategory('Other', 1), Colors.grey),
  'fee': CategoryData(_iconFromCategory('Other', 24), Colors.brown),
  'charge': CategoryData(_iconFromCategory('Other', 19), Colors.redAccent),
  'refund': CategoryData(_iconFromCategory('Other', 11), Colors.green),
  'exchange': CategoryData(_iconFromCategory('Other', 15), Colors.deepPurple),
  'unknown': CategoryData(_iconFromCategory('Other', 0), Colors.grey),
  'miscellaneous': CategoryData(
    _iconFromCategory('Other', 1),
    Colors.grey,
  ), // ---------------- Extended / many synonyms ----------------
  // Food synonyms
  'deli': CategoryData(
    _iconFromCategory('Food & Drink', 0),
    Colors.green.shade600,
  ),
  'butcher': CategoryData(
    _iconFromCategory('Food & Drink', 0),
    Colors.red.shade400,
  ),
  'seafood': CategoryData(_iconFromCategory('Food & Drink', 21), Colors.blue),
  'sushi': CategoryData(_iconFromCategory('Food & Drink', 21), Colors.teal),
  'ramen': CategoryData(_iconFromCategory('Food & Drink', 14), Colors.orange),
  'kebab': CategoryData(
    _iconFromCategory('Food & Drink', 15),
    Colors.deepOrange,
  ),
  'brunch': CategoryData(
    _iconFromCategory('Food & Drink', 12),
    Colors.orange.shade200,
  ),
  'breakfast': CategoryData(
    _iconFromCategory('Food & Drink', 16),
    Colors.yellow.shade600,
  ),
  'lunch': CategoryData(
    _iconFromCategory('Food & Drink', 18),
    Colors.orange.shade300,
  ),
  'dinner': CategoryData(
    _iconFromCategory('Food & Drink', 19),
    Colors.deepOrange.shade400,
  ), // Shopping synonyms
  'grocerystore': CategoryData(_iconFromCategory('Shopping', 7), Colors.green),
  'convenience': CategoryData(
    _iconFromCategory('Shopping', 6),
    Colors.green.shade600,
  ),
  'mall': CategoryData(_iconFromCategory('Shopping', 5), Colors.indigo),
  'retail': CategoryData(
    _iconFromCategory('Shopping', 4),
    Colors.indigo.shade700,
  ),
  'coupon': CategoryData(
    _iconFromCategory('Shopping', 11),
    Colors.amber,
  ), // Transport synonyms
  'ride share': CategoryData(
    _iconFromCategory('Travel & Transport', 1),
    Colors.yellow.shade700,
  ),
  'motorbike': CategoryData(
    _iconFromCategory('Travel & Transport', 12),
    Colors.orange,
  ),
  'two wheeler': CategoryData(
    _iconFromCategory('Travel & Transport', 12),
    Colors.orange,
  ),
  'car rental': CategoryData(
    _iconFromCategory('Travel & Transport', 26),
    Colors.blueGrey,
  ), // Finance synonyms
  'bank fees': CategoryData(_iconFromCategory('Finance', 8), Colors.brown),
  'cash withdrawal': CategoryData(
    _iconFromCategory('Finance', 11),
    Colors.blueGrey,
  ),
  'transfer': CategoryData(_iconFromCategory('Finance', 14), Colors.deepPurple),
  'wire transfer': CategoryData(
    _iconFromCategory('Finance', 14),
    Colors.deepPurple,
  ),

  // Health synonyms
  'pharmacy purchase': CategoryData(
    _iconFromCategory('Health & Fitness', 2),
    Colors.red,
  ),
  'medical checkup': CategoryData(
    _iconFromCategory('Health & Fitness', 1),
    Colors.deepPurple,
  ),

  // Entertainment synonyms
  'arcade': CategoryData(
    _iconFromCategory('Entertainment', 7),
    Colors.deepPurple,
  ),
  'karaoke': CategoryData(
    _iconFromCategory('Entertainment', 20),
    Colors.pinkAccent,
  ),

  // Home synonyms
  'plumbing': CategoryData(
    _iconFromCategory('Home & Utilities', 20),
    Colors.blueGrey,
  ),
  'electrical': CategoryData(
    _iconFromCategory('Home & Utilities', 19),
    Colors.yellow.shade700,
  ),
  'heating': CategoryData(
    _iconFromCategory('Home & Utilities', 17),
    Colors.orange,
  ),

  // Large catch-all many words to improve coverage (you can continue adding)
  'coffee beans': CategoryData(
    _iconFromCategory('Food & Drink', 13),
    Colors.brown,
  ),
  'energy': CategoryData(
    _iconFromCategory('Home & Utilities', 19),
    Colors.yellow,
  ),
  'internet service': CategoryData(
    _iconFromCategory('Technology', 9),
    Colors.blueAccent,
  ),
  'software license': CategoryData(
    _iconFromCategory('Subscriptions', 0),
    Colors.deepPurple,
  ),
  'cloud storage': CategoryData(
    _iconFromCategory('Technology', 16),
    Colors.lightBlue,
  ),
  'photo printing': CategoryData(
    _iconFromCategory('Entertainment', 15),
    Colors.blueGrey,
  ),
  'movie rental': CategoryData(
    _iconFromCategory('Entertainment', 0),
    Colors.deepPurple,
  ),
  'concert tickets': CategoryData(
    _iconFromCategory('Entertainment', 20),
    Colors.indigo,
  ),
  'museum': CategoryData(_iconFromCategory('Entertainment', 19), Colors.amber),
  'charity donation': CategoryData(
    _iconFromCategory('Gifts & Donations', 2),
    Colors.green,
  ), // final safety fallback (already covered but explicit)
  'default': CategoryData(
    _iconFromCategory('Other', 1),
    Colors.grey,
  ), // ---------------- Additional rules data for unused or underused icons ----------------
  // Food & Drink additions (covering missing indices like 4,5,6,15,19,21,22,23,24 and reinforcing others)
  'fast food': CategoryData(
    _iconFromCategory('Food & Drink', 0),
    Colors.orange,
  ),
  'fine dining': CategoryData(
    _iconFromCategory('Food & Drink', 1),
    Colors.deepOrange,
  ),
  'coffee shop': CategoryData(
    _iconFromCategory('Food & Drink', 2),
    Colors.brown,
  ),
  'pub': CategoryData(_iconFromCategory('Food & Drink', 3), Colors.deepOrange),
  'wine': CategoryData(_iconFromCategory('Food & Drink', 4), Colors.purple),
  'kitchen supplies': CategoryData(
    _iconFromCategory('Food & Drink', 5),
    Colors.grey,
  ),
  'dining out': CategoryData(
    _iconFromCategory('Food & Drink', 6),
    Colors.orange,
  ),
  'birthday': CategoryData(_iconFromCategory('Food & Drink', 7), Colors.pink),
  'pizza shop': CategoryData(
    _iconFromCategory('Food & Drink', 8),
    Colors.deepOrange,
  ),
  'frozen dessert': CategoryData(
    _iconFromCategory('Food & Drink', 9),
    Colors.pinkAccent,
  ),
  'soft drink': CategoryData(
    _iconFromCategory('Food & Drink', 10),
    Colors.amber,
  ),
  'bake shop': CategoryData(
    _iconFromCategory('Food & Drink', 11),
    Colors.amber,
  ),
  'brunch meal': CategoryData(
    _iconFromCategory('Food & Drink', 12),
    Colors.orange.shade200,
  ),
  'espresso': CategoryData(_iconFromCategory('Food & Drink', 13), Colors.brown),
  'noodles': CategoryData(_iconFromCategory('Food & Drink', 14), Colors.orange),
  'grill': CategoryData(
    _iconFromCategory('Food & Drink', 15),
    Colors.deepOrange,
  ),
  'eggs breakfast': CategoryData(
    _iconFromCategory('Food & Drink', 16),
    Colors.yellow,
  ),
  'morning meal': CategoryData(
    _iconFromCategory('Food & Drink', 17),
    Colors.yellow.shade600,
  ),
  'midday meal': CategoryData(
    _iconFromCategory('Food & Drink', 18),
    Colors.orange.shade300,
  ),
  'evening meal': CategoryData(
    _iconFromCategory('Food & Drink', 19),
    Colors.deepOrange.shade400,
  ),
  'delivery food': CategoryData(
    _iconFromCategory('Food & Drink', 20),
    Colors.orange.shade300,
  ),
  'meal set': CategoryData(
    _iconFromCategory('Food & Drink', 21),
    Colors.orange,
  ),
  'hot beverage': CategoryData(
    _iconFromCategory('Food & Drink', 22),
    Colors.brown,
  ),
  'eat out': CategoryData(_iconFromCategory('Food & Drink', 23), Colors.orange),
  'gift card': CategoryData(_iconFromCategory('Shopping', 2), Colors.pink),
  'wallet purchase': CategoryData(
    _iconFromCategory('Shopping', 3),
    Colors.brown,
  ),
  'receipt long': CategoryData(_iconFromCategory('Shopping', 8), Colors.grey),
  'pay': CategoryData(_iconFromCategory('Shopping', 9), Colors.deepPurple),
  'card payment': CategoryData(_iconFromCategory('Shopping', 10), Colors.blue),
  'shop basket': CategoryData(_iconFromCategory('Shopping', 12), Colors.green),
  'qr scan': CategoryData(_iconFromCategory('Shopping', 13), Colors.black),
  'barcode scan': CategoryData(_iconFromCategory('Shopping', 14), Colors.black),
  'sell item': CategoryData(_iconFromCategory('Shopping', 17), Colors.green),
  'price tag': CategoryData(
    _iconFromCategory('Shopping', 18),
    Colors.amber,
  ), // Entertainment additions (covering missing 2,4,5,6,8,9,10,11,12,13,16,17,18,21,23,24)
  'music': CategoryData(_iconFromCategory('Entertainment', 2), Colors.indigo),
  'song': CategoryData(_iconFromCategory('Entertainment', 2), Colors.indigo),
  'video games': CategoryData(
    _iconFromCategory('Entertainment', 4),
    Colors.deepPurple,
  ),
  'tv': CategoryData(_iconFromCategory('Entertainment', 5), Colors.grey),
  'television': CategoryData(
    _iconFromCategory('Entertainment', 5),
    Colors.grey,
  ),
  'audio headset': CategoryData(
    _iconFromCategory('Entertainment', 6),
    Colors.black,
  ),
  'gambling': CategoryData(_iconFromCategory('Entertainment', 8), Colors.red),
  'bar sports': CategoryData(
    _iconFromCategory('Entertainment', 9),
    Colors.orange,
  ),
  'piano music': CategoryData(
    _iconFromCategory('Entertainment', 10),
    Colors.black,
  ),
  'piano': CategoryData(_iconFromCategory('Entertainment', 10), Colors.black),
  'microphone': CategoryData(
    _iconFromCategory('Entertainment', 11),
    Colors.black,
  ),
  'headphones audio': CategoryData(
    _iconFromCategory('Entertainment', 12),
    Colors.black,
  ),
  'speaker sound': CategoryData(
    _iconFromCategory('Entertainment', 13),
    Colors.black,
  ),
  'comedy show': CategoryData(
    _iconFromCategory('Entertainment', 16),
    Colors.deepPurple,
  ),
  'sports stadium': CategoryData(
    _iconFromCategory('Entertainment', 17),
    Colors.green,
  ),
  'theme park': CategoryData(
    _iconFromCategory('Entertainment', 18),
    Colors.cyan,
  ),
  'music album': CategoryData(
    _iconFromCategory('Entertainment', 21),
    Colors.indigo,
  ),
  'film creation': CategoryData(
    _iconFromCategory('Entertainment', 23),
    Colors.deepPurple,
  ),
  'video music': CategoryData(
    _iconFromCategory('Entertainment', 24),
    Colors.indigo,
  ), // Health & Fitness additions (covering all, including underused)
  'safety': CategoryData(
    _iconFromCategory('Health & Fitness', 0),
    Colors.purple,
  ),
  'hospital visit': CategoryData(
    _iconFromCategory('Health & Fitness', 1),
    Colors.redAccent,
  ),
  'medicine': CategoryData(
    _iconFromCategory('Health & Fitness', 2),
    Colors.red,
  ),
  'workout': CategoryData(
    _iconFromCategory('Health & Fitness', 3),
    Colors.teal,
  ),
  'medical service': CategoryData(
    _iconFromCategory('Health & Fitness', 4),
    Colors.red,
  ),
  'relaxation': CategoryData(
    _iconFromCategory('Health & Fitness', 5),
    Colors.purpleAccent,
  ),
  'running': CategoryData(
    _iconFromCategory('Health & Fitness', 6),
    Colors.green,
  ),
  'meditation': CategoryData(
    _iconFromCategory('Health & Fitness', 7),
    Colors.green,
  ),
  'heart monitor': CategoryData(
    _iconFromCategory('Health & Fitness', 8),
    Colors.red,
  ),
  'masks protection': CategoryData(
    _iconFromCategory('Health & Fitness', 9),
    Colors.blue,
  ),
  'healing injury': CategoryData(
    _iconFromCategory('Health & Fitness', 10),
    Colors.redAccent,
  ),
  'aromatherapy': CategoryData(
    _iconFromCategory('Health & Fitness', 11),
    Colors.green,
  ),
  'hydration': CategoryData(
    _iconFromCategory('Health & Fitness', 12),
    Colors.blue,
  ),
  'blood donation': CategoryData(
    _iconFromCategory('Health & Fitness', 13),
    Colors.red,
  ),
  'mental health': CategoryData(
    _iconFromCategory('Health & Fitness', 14),
    Colors.purple,
  ),
  'injury': CategoryData(_iconFromCategory('Health & Fitness', 15), Colors.red),
  'emergency care': CategoryData(
    _iconFromCategory('Health & Fitness', 16),
    Colors.redAccent,
  ),
  'vaccination': CategoryData(
    _iconFromCategory('Health & Fitness', 17),
    Colors.blue,
  ),
  'health info': CategoryData(
    _iconFromCategory('Health & Fitness', 18),
    Colors.purple,
  ),
  'handball': CategoryData(
    _iconFromCategory('Health & Fitness', 19),
    Colors.orange,
  ),
  'gymnastics': CategoryData(
    _iconFromCategory('Health & Fitness', 20),
    Colors.teal,
  ),
  'healthy breakfast': CategoryData(
    _iconFromCategory('Health & Fitness', 21),
    Colors.brown,
  ), // Education additions (covering all)
  'reading': CategoryData(_iconFromCategory('Education', 1), Colors.indigo),
  'lab': CategoryData(_iconFromCategory('Education', 2), Colors.blue),
  'textbook': CategoryData(_iconFromCategory('Education', 3), Colors.indigo),
  'history': CategoryData(_iconFromCategory('Education', 4), Colors.brown),
  'online education': CategoryData(
    _iconFromCategory('Education', 5),
    Colors.indigo,
  ),
  'library': CategoryData(_iconFromCategory('Education', 6), Colors.brown),
  'notes': CategoryData(_iconFromCategory('Education', 7), Colors.grey),
  'math': CategoryData(_iconFromCategory('Education', 8), Colors.green),
  'art class': CategoryData(_iconFromCategory('Education', 9), Colors.purple),
  'languages': CategoryData(_iconFromCategory('Education', 10), Colors.blue),
  'translation': CategoryData(_iconFromCategory('Education', 11), Colors.blue),
  'alphabet': CategoryData(_iconFromCategory('Education', 12), Colors.red),
  'numerics': CategoryData(_iconFromCategory('Education', 13), Colors.green),
  'math functions': CategoryData(
    _iconFromCategory('Education', 14),
    Colors.green,
  ),
  'biology': CategoryData(_iconFromCategory('Education', 15), Colors.green),
  'test': CategoryData(_iconFromCategory('Education', 16), Colors.grey),
  'stories': CategoryData(_iconFromCategory('Education', 17), Colors.indigo),
  'air travel': CategoryData(
    _iconFromCategory('Travel & Transport', 0),
    Colors.indigo,
  ),
  'driving': CategoryData(
    _iconFromCategory('Travel & Transport', 1),
    Colors.yellow.shade700,
  ),
  'rail': CategoryData(
    _iconFromCategory('Travel & Transport', 2),
    Colors.orange.shade700,
  ),
  'bus ride': CategoryData(
    _iconFromCategory('Travel & Transport', 3),
    Colors.yellow.shade700,
  ),
  'bike': CategoryData(
    _iconFromCategory('Travel & Transport', 4),
    Colors.green,
  ),
  'gas': CategoryData(
    _iconFromCategory('Travel & Transport', 5),
    Colors.deepOrange,
  ),
  'beach': CategoryData(
    _iconFromCategory('Travel & Transport', 6),
    Colors.cyan,
  ),
  'surf': CategoryData(_iconFromCategory('Travel & Transport', 7), Colors.blue),
  'accommodation': CategoryData(
    _iconFromCategory('Travel & Transport', 8),
    Colors.teal,
  ),
  'maps': CategoryData(
    _iconFromCategory('Travel & Transport', 9),
    Colors.blueGrey,
  ),
  'ship': CategoryData(
    _iconFromCategory('Travel & Transport', 10),
    Colors.lightBlue,
  ),
  'cab': CategoryData(
    _iconFromCategory('Travel & Transport', 11),
    Colors.yellow.shade700,
  ),
  'motorcycle': CategoryData(
    _iconFromCategory('Travel & Transport', 12),
    Colors.orange,
  ),
  'electric vehicle': CategoryData(
    _iconFromCategory('Travel & Transport', 13),
    Colors.teal,
  ),
  'airplane ticket': CategoryData(
    _iconFromCategory('Travel & Transport', 14),
    Colors.indigo,
  ),
  'space travel': CategoryData(
    _iconFromCategory('Travel & Transport', 15),
    Colors.deepPurple,
  ),
  'boat sail': CategoryData(
    _iconFromCategory('Travel & Transport', 16),
    Colors.blue,
  ),
  'hike': CategoryData(
    _iconFromCategory('Travel & Transport', 17),
    Colors.green,
  ),
  'kayak': CategoryData(
    _iconFromCategory('Travel & Transport', 18),
    Colors.blue,
  ),
  'paraglide': CategoryData(
    _iconFromCategory('Travel & Transport', 19),
    Colors.cyan,
  ),
  'skiing': CategoryData(
    _iconFromCategory('Travel & Transport', 20),
    Colors.white,
  ),
  'airport terminal': CategoryData(
    _iconFromCategory('Travel & Transport', 21),
    Colors.indigo,
  ),
  'baggage': CategoryData(
    _iconFromCategory('Travel & Transport', 22),
    Colors.blueGrey,
  ),
  'sightseeing': CategoryData(
    _iconFromCategory('Travel & Transport', 23),
    Colors.cyan,
  ),
  'road traffic': CategoryData(
    _iconFromCategory('Travel & Transport', 24),
    Colors.brown,
  ),
  'rail travel': CategoryData(
    _iconFromCategory('Travel & Transport', 25),
    Colors.orange.shade700,
  ),
  'rent car': CategoryData(
    _iconFromCategory('Travel & Transport', 26),
    Colors.blueGrey,
  ),
  'gps': CategoryData(
    _iconFromCategory('Travel & Transport', 27),
    Colors.blue,
  ), // Home & Utilities additions (covering all)
  'home': CategoryData(_iconFromCategory('Home & Utilities', 0), Colors.indigo),
  'bedroom': CategoryData(
    _iconFromCategory('Home & Utilities', 1),
    Colors.blue,
  ),
  'clean': CategoryData(_iconFromCategory('Home & Utilities', 2), Colors.brown),
  'lighting': CategoryData(
    _iconFromCategory('Home & Utilities', 3),
    Colors.yellow,
  ),
  'environment': CategoryData(
    _iconFromCategory('Home & Utilities', 4),
    Colors.green,
  ),
  'bath': CategoryData(_iconFromCategory('Home & Utilities', 5), Colors.blue),
  'air conditioning': CategoryData(
    _iconFromCategory('Home & Utilities', 6),
    Colors.lightBlue,
  ),
  'power supply': CategoryData(
    _iconFromCategory('Home & Utilities', 7),
    Colors.yellow,
  ),
  'kitchen home': CategoryData(
    _iconFromCategory('Home & Utilities', 8),
    Colors.orange,
  ),
  'living room': CategoryData(
    _iconFromCategory('Home & Utilities', 9),
    Colors.brown,
  ),
  'lounge': CategoryData(
    _iconFromCategory('Home & Utilities', 10),
    Colors.brown,
  ),
  'seating': CategoryData(
    _iconFromCategory('Home & Utilities', 11),
    Colors.brown,
  ),
  'door': CategoryData(_iconFromCategory('Home & Utilities', 12), Colors.brown),
  'windows': CategoryData(
    _iconFromCategory('Home & Utilities', 13),
    Colors.blueGrey,
  ),
  'roof': CategoryData(_iconFromCategory('Home & Utilities', 14), Colors.brown),
  'outdoor yard': CategoryData(
    _iconFromCategory('Home & Utilities', 15),
    Colors.green,
  ),
  'car garage': CategoryData(
    _iconFromCategory('Home & Utilities', 16),
    Colors.grey,
  ),
  'temperature': CategoryData(
    _iconFromCategory('Home & Utilities', 17),
    Colors.orange,
  ),
  'gas utility': CategoryData(
    _iconFromCategory('Home & Utilities', 18),
    Colors.deepOrange,
  ),
  'electric': CategoryData(
    _iconFromCategory('Home & Utilities', 19),
    Colors.yellow,
  ),
  'pipes': CategoryData(
    _iconFromCategory('Home & Utilities', 20),
    Colors.blueGrey,
  ),
  'home fix': CategoryData(
    _iconFromCategory('Home & Utilities', 21),
    Colors.brown,
  ),
  'apartment rent': CategoryData(
    _iconFromCategory('Home & Utilities', 22),
    Colors.indigo,
  ),
  'house purchase': CategoryData(
    _iconFromCategory('Home & Utilities', 23),
    Colors.indigo,
  ),
  'growth': CategoryData(_iconFromCategory('Finance', 0), Colors.green),
  'save money': CategoryData(_iconFromCategory('Finance', 1), Colors.teal),
  'card': CategoryData(_iconFromCategory('Finance', 2), Colors.blue),
  'job': CategoryData(_iconFromCategory('Finance', 3), Colors.blueGrey),
  'money': CategoryData(_iconFromCategory('Finance', 4), Colors.green),
  'bank account': CategoryData(
    _iconFromCategory('Finance', 5),
    Colors.blueGrey,
  ),
  'pay bill': CategoryData(_iconFromCategory('Finance', 6), Colors.deepPurple),
  // 'exchange': CategoryData(_iconFromCategory('Finance', 7), Colors.deepPurple),
  'receipt finance': CategoryData(
    _iconFromCategory('Finance', 8),
    Colors.brown,
  ),
  'quote': CategoryData(_iconFromCategory('Finance', 9), Colors.grey),
  'multiple payments': CategoryData(
    _iconFromCategory('Finance', 10),
    Colors.deepPurple,
  ),
  'wallet balance': CategoryData(
    _iconFromCategory('Finance', 11),
    Colors.blueGrey,
  ),
  'earn money': CategoryData(
    _iconFromCategory('Finance', 12),
    Colors.green.shade700,
  ),
  'no money': CategoryData(_iconFromCategory('Finance', 13), Colors.red),
  'swap': CategoryData(_iconFromCategory('Finance', 14), Colors.orange),
  'chart bar': CategoryData(_iconFromCategory('Finance', 15), Colors.indigo),
  'pie': CategoryData(_iconFromCategory('Finance', 16), Colors.indigo),
  'account': CategoryData(_iconFromCategory('Finance', 17), Colors.blueGrey),
  'line chart': CategoryData(_iconFromCategory('Finance', 18), Colors.indigo),
  'track finance': CategoryData(
    _iconFromCategory('Finance', 19),
    Colors.indigo,
  ), // Family & Personal additions (covering all)
  'pet': CategoryData(_iconFromCategory('Family & Personal', 0), Colors.teal),
  'family room': CategoryData(
    _iconFromCategory('Family & Personal', 1),
    Colors.purple,
  ),
  'child': CategoryData(
    _iconFromCategory('Family & Personal', 2),
    Colors.purple,
  ),
  'favorite star': CategoryData(
    _iconFromCategory('Family & Personal', 3),
    Colors.yellow,
  ),
  'personal': CategoryData(
    _iconFromCategory('Family & Personal', 4),
    Colors.blue,
  ),
  'friends': CategoryData(
    _iconFromCategory('Family & Personal', 5),
    Colors.green,
  ),
  'cake': CategoryData(_iconFromCategory('Family & Personal', 6), Colors.pink),
  'birthday cake': CategoryData(
    _iconFromCategory('Family & Personal', 6),
    Colors.pink,
  ),
  'heart': CategoryData(_iconFromCategory('Family & Personal', 7), Colors.red),
  'female': CategoryData(
    _iconFromCategory('Family & Personal', 8),
    Colors.pink,
  ),
  'male': CategoryData(_iconFromCategory('Family & Personal', 9), Colors.blue),
  'senior': CategoryData(
    _iconFromCategory('Family & Personal', 10),
    Colors.grey,
  ),
  'baby station': CategoryData(
    _iconFromCategory('Family & Personal', 11),
    Colors.pinkAccent,
  ),
  'pregnancy': CategoryData(
    _iconFromCategory('Family & Personal', 12),
    Colors.pink,
  ),
  'escalator safety': CategoryData(
    _iconFromCategory('Family & Personal', 13),
    Colors.grey,
  ),
  'diversity group1': CategoryData(
    _iconFromCategory('Family & Personal', 14),
    Colors.green,
  ),
  'diversity group2': CategoryData(
    _iconFromCategory('Family & Personal', 15),
    Colors.green,
  ),
  'diversity group3': CategoryData(
    _iconFromCategory('Family & Personal', 16),
    Colors.green,
  ),
  'restroom': CategoryData(
    _iconFromCategory('Family & Personal', 17),
    Colors.blue,
  ),
  'people emoji': CategoryData(
    _iconFromCategory('Family & Personal', 18),
    Colors.blue,
  ),
  'family home': CategoryData(
    _iconFromCategory('Family & Personal', 19),
    Colors.indigo,
  ),
  'desktop': CategoryData(_iconFromCategory('Technology', 0), Colors.blueGrey),
  'mobile': CategoryData(_iconFromCategory('Technology', 1), Colors.blueAccent),
  'camera': CategoryData(_iconFromCategory('Technology', 2), Colors.grey),
  'paint brush': CategoryData(
    _iconFromCategory('Technology', 3),
    Colors.purple,
  ),
  'gadgets': CategoryData(_iconFromCategory('Technology', 4), Colors.blueGrey),
  'notebook': CategoryData(_iconFromCategory('Technology', 5), Colors.blueGrey),
  'printer': CategoryData(_iconFromCategory('Technology', 6), Colors.grey),
  'scan': CategoryData(_iconFromCategory('Technology', 7), Colors.grey),
  'wifi router': CategoryData(_iconFromCategory('Technology', 8), Colors.blue),
  'wifi': CategoryData(_iconFromCategory('Technology', 9), Colors.blueAccent),
  'dev mode': CategoryData(_iconFromCategory('Technology', 10), Colors.green),
  'coding': CategoryData(_iconFromCategory('Technology', 11), Colors.green),
  'bug': CategoryData(_iconFromCategory('Technology', 12), Colors.red),
  'console': CategoryData(_iconFromCategory('Technology', 13), Colors.black),
  'web http': CategoryData(_iconFromCategory('Technology', 14), Colors.blue),
  'website': CategoryData(_iconFromCategory('Technology', 15), Colors.indigo),
  'cloud service': CategoryData(
    _iconFromCategory('Technology', 16),
    Colors.lightBlue,
  ),
  'data storage': CategoryData(
    _iconFromCategory('Technology', 17),
    Colors.grey,
  ),
  'memory card': CategoryData(_iconFromCategory('Technology', 18), Colors.grey),
  'usb drive': CategoryData(_iconFromCategory('Technology', 19), Colors.grey),
  'bluetooth device': CategoryData(
    _iconFromCategory('Technology', 20),
    Colors.blue,
  ),
  'cell phone': CategoryData(
    _iconFromCategory('Technology', 21),
    Colors.blueAccent,
  ),
  'ram': CategoryData(_iconFromCategory('Technology', 22), Colors.grey),
  'robot': CategoryData(
    _iconFromCategory('Technology', 23),
    Colors.teal,
  ), // Sports additions (covering all)
  'soccer': CategoryData(_iconFromCategory('Sports', 0), Colors.green),
  'basketball': CategoryData(_iconFromCategory('Sports', 1), Colors.orange),
  'tennis': CategoryData(_iconFromCategory('Sports', 2), Colors.green),
  'swimming': CategoryData(_iconFromCategory('Sports', 3), Colors.blue),
  'baseball': CategoryData(_iconFromCategory('Sports', 4), Colors.red),
  'cricket': CategoryData(_iconFromCategory('Sports', 5), Colors.green),
  'football': CategoryData(_iconFromCategory('Sports', 6), Colors.brown),
  'golf': CategoryData(_iconFromCategory('Sports', 7), Colors.green),
  'handball sport': CategoryData(_iconFromCategory('Sports', 8), Colors.orange),
  'hockey': CategoryData(_iconFromCategory('Sports', 9), Colors.blue),
  'kabaddi': CategoryData(_iconFromCategory('Sports', 10), Colors.orange),
  'martial arts': CategoryData(_iconFromCategory('Sports', 11), Colors.red),
  'mma': CategoryData(_iconFromCategory('Sports', 12), Colors.red),
  'motorsports': CategoryData(_iconFromCategory('Sports', 13), Colors.black),
  'rugby': CategoryData(_iconFromCategory('Sports', 14), Colors.brown),
  'volleyball': CategoryData(_iconFromCategory('Sports', 15), Colors.orange),
  'general sports': CategoryData(
    _iconFromCategory('Sports', 16),
    Colors.orange,
  ),
  'gym fitness': CategoryData(_iconFromCategory('Sports', 17), Colors.teal),
  'yoga fitness': CategoryData(_iconFromCategory('Sports', 18), Colors.green),
  'more': CategoryData(_iconFromCategory('Other', 0), Colors.grey),
  'others': CategoryData(_iconFromCategory('Other', 0), Colors.grey),
  'categories': CategoryData(_iconFromCategory('Other', 1), Colors.grey),
  'access': CategoryData(_iconFromCategory('Other', 2), Colors.blue),
  'alarm clock': CategoryData(_iconFromCategory('Other', 3), Colors.red),
  'news announcement': CategoryData(
    _iconFromCategory('Other', 4),
    Colors.orange,
  ),
  'build tool': CategoryData(_iconFromCategory('Other', 5), Colors.brown),
  'construct': CategoryData(_iconFromCategory('Other', 6), Colors.brown),
  'design': CategoryData(_iconFromCategory('Other', 7), Colors.purple),
  'engineer': CategoryData(_iconFromCategory('Other', 8), Colors.grey),
  'fix': CategoryData(_iconFromCategory('Other', 9), Colors.brown),
  'tools': CategoryData(_iconFromCategory('Other', 10), Colors.brown),
  'light source': CategoryData(_iconFromCategory('Other', 11), Colors.yellow),
  'colors': CategoryData(_iconFromCategory('Other', 12), Colors.purple),
  'pest': CategoryData(_iconFromCategory('Other', 13), Colors.green),
  'recycle': CategoryData(_iconFromCategory('Other', 14), Colors.green),
  'solar': CategoryData(_iconFromCategory('Other', 15), Colors.yellow),
  'wind': CategoryData(_iconFromCategory('Other', 16), Colors.lightBlue),
  'water leak': CategoryData(_iconFromCategory('Other', 17), Colors.blue),
  'alert': CategoryData(_iconFromCategory('Other', 18), Colors.red),
  'information': CategoryData(_iconFromCategory('Other', 19), Colors.blue),
  'support': CategoryData(_iconFromCategory('Other', 20), Colors.green),
  'query': CategoryData(_iconFromCategory('Other', 21), Colors.grey),
  'config': CategoryData(_iconFromCategory('Other', 22), Colors.grey),
  'adjust': CategoryData(_iconFromCategory('Other', 23), Colors.grey),
  'time line': CategoryData(_iconFromCategory('Other', 24), Colors.blue),
  'past': CategoryData(_iconFromCategory('Other', 25), Colors.brown),
  'location map': CategoryData(
    _iconFromCategory('Other', 26),
    Colors.blueGrey,
  ), // Beauty & Grooming additions (covering all)
  'makeup': CategoryData(
    _iconFromCategory('Beauty & Grooming', 0),
    Colors.purpleAccent,
  ),
  'facial': CategoryData(
    _iconFromCategory('Beauty & Grooming', 1),
    Colors.pink,
  ),
  'fashion': CategoryData(
    _iconFromCategory('Beauty & Grooming', 2),
    Colors.purple,
  ),
  'massage': CategoryData(
    _iconFromCategory('Beauty & Grooming', 3),
    Colors.purpleAccent,
  ),
  'haircut': CategoryData(
    _iconFromCategory('Beauty & Grooming', 4),
    Colors.brown,
  ),
  'scissors': CategoryData(
    _iconFromCategory('Beauty & Grooming', 5),
    Colors.grey,
  ),
  'bath shower': CategoryData(
    _iconFromCategory('Beauty & Grooming', 6),
    Colors.blue,
  ), // Gifts & Donations additions (covering all)
  'giftcard': CategoryData(
    _iconFromCategory('Gifts & Donations', 0),
    Colors.pinkAccent,
  ),
  'redeem gift': CategoryData(
    _iconFromCategory('Gifts & Donations', 1),
    Colors.green,
  ),
  'volunteer': CategoryData(
    _iconFromCategory('Gifts & Donations', 2),
    Colors.green,
  ),
  'like': CategoryData(_iconFromCategory('Gifts & Donations', 3), Colors.red),
  'donate money': CategoryData(
    _iconFromCategory('Gifts & Donations', 4),
    Colors.green,
  ), // Subscriptions additions (covering all)
  'subscribe': CategoryData(
    _iconFromCategory('Subscriptions', 0),
    Colors.deepPurple,
  ),
  'netflix': CategoryData(
    _iconFromCategory('Subscriptions', 0),
    Colors.deepPurple,
  ),
  'renew': CategoryData(
    _iconFromCategory('Subscriptions', 1),
    Colors.deepPurple,
  ),
  'recurring': CategoryData(
    _iconFromCategory('Subscriptions', 2),
    Colors.deepPurple,
  ),
  'subscription card': CategoryData(
    _iconFromCategory('Subscriptions', 3),
    Colors.blue,
  ), // Auto & Vehicle additions (covering all)
  'vehicle': CategoryData(
    _iconFromCategory('Auto & Vehicle', 0),
    Colors.yellow.shade700,
  ),
  'rental car': CategoryData(
    _iconFromCategory('Auto & Vehicle', 1),
    Colors.blueGrey,
  ),
  'fix car': CategoryData(
    _iconFromCategory('Auto & Vehicle', 2),
    Colors.orange,
  ),
  'charging station': CategoryData(
    _iconFromCategory('Auto & Vehicle', 3),
    Colors.teal,
  ),
  'fuel station': CategoryData(
    _iconFromCategory('Auto & Vehicle', 4),
    Colors.deepOrange,
  ),
  'bike motor': CategoryData(
    _iconFromCategory('Auto & Vehicle', 5),
    Colors.orange,
  ),
  'bus transport': CategoryData(
    _iconFromCategory('Auto & Vehicle', 6),
    Colors.yellow.shade700,
  ), // Work & Office additions (covering all)
  'job work': CategoryData(
    _iconFromCategory('Work & Office', 0),
    Colors.blueGrey,
  ),
  'business': CategoryData(
    _iconFromCategory('Work & Office', 1),
    Colors.blueGrey,
  ),
  'profile': CategoryData(_iconFromCategory('Work & Office', 2), Colors.blue),
  'documents': CategoryData(
    _iconFromCategory('Work & Office', 3),
    Colors.deepOrange,
  ),
  'meeting': CategoryData(_iconFromCategory('Work & Office', 4), Colors.indigo),

  // Hobbies & Crafts additions (covering all)
  'create art': CategoryData(
    _iconFromCategory('Hobbies & Crafts', 0),
    Colors.teal,
  ),
  'painting': CategoryData(
    _iconFromCategory('Hobbies & Crafts', 1),
    Colors.purple,
  ),
  'toys play': CategoryData(
    _iconFromCategory('Hobbies & Crafts', 2),
    Colors.pink,
  ),
  'puzzle': CategoryData(
    _iconFromCategory('Hobbies & Crafts', 3),
    Colors.orange,
  ),
  'play local': CategoryData(
    _iconFromCategory('Hobbies & Crafts', 4),
    Colors.green,
  ), // Gardening & Outdoor additions (covering all)
  'nature outdoor': CategoryData(
    _iconFromCategory('Gardening & Outdoor', 0),
    Colors.green,
  ),
  'park visit': CategoryData(
    _iconFromCategory('Gardening & Outdoor', 1),
    Colors.green,
  ),
  'mountain': CategoryData(
    _iconFromCategory('Gardening & Outdoor', 2),
    Colors.brown,
  ),
  'lawn': CategoryData(
    _iconFromCategory('Gardening & Outdoor', 3),
    Colors.green,
  ),
  'flowers garden': CategoryData(
    _iconFromCategory('Gardening & Outdoor', 4),
    Colors.pinkAccent,
  ),
  'coverage': CategoryData(
    _iconFromCategory('Insurance & Legal', 0),
    Colors.blueGrey,
  ),
  'court': CategoryData(_iconFromCategory('Insurance & Legal', 1), Colors.grey),
  'protection': CategoryData(
    _iconFromCategory('Insurance & Legal', 2),
    Colors.blue,
  ),
  'law': CategoryData(_iconFromCategory('Insurance & Legal', 3), Colors.grey),
};
