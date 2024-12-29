import 'package:flutter/material.dart';

class PriceMarker extends StatelessWidget {
  final int price;

  const PriceMarker({Key? key, required this.price}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8F5), // Cream background
        borderRadius: BorderRadius.circular(10), // Rounded edges
        border: Border.all(
          color: const Color(0xFFF9F8F5), // Cream border
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51), // 20% opacity shadow
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        '£${price.toString()}', // Display price as "£X"
        style: const TextStyle(
          color: Colors.black, // Cream text
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
