import 'package:flutter/material.dart';

class FilterPodsButton extends StatelessWidget {
  final String? selectedStartTime;
  final String? selectedEndTime;
  final List<String> timeSlots;
  final VoidCallback onFilter;

  const FilterPodsButton({
    Key? key,
    this.selectedStartTime,
    this.selectedEndTime,
    required this.timeSlots,
    required this.onFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        if (selectedStartTime == null || selectedEndTime == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please select both start and end times')),
          );
          return;
        }
        int startIndex = timeSlots.indexOf(selectedStartTime!);
        int endIndex = timeSlots.indexOf(selectedEndTime!);
        if (endIndex <= startIndex) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('End time must be after start time')),
          );
          return;
        }
        onFilter(); // Trigger filtering logic
      },
      backgroundColor: const Color(0xFFAD7E4D), // Brown background color
      child: const Icon(
        Icons.search, // Magnifying glass icon
        color: Colors.white, // Icon color
        size: 24, // Icon size
      ),
    );
  }
}
