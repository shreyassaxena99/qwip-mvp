import 'package:flutter/material.dart';

class FilterPodsButton extends StatelessWidget {
  final TimeOfDay? selectedStartTime;
  final TimeOfDay? selectedEndTime;
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
        print("Start time selected: $selectedStartTime");
        print("End time selected: $selectedEndTime");
        if (selectedStartTime == null || selectedEndTime == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please select both start and end times')),
          );
          return;
        }
        if (selectedStartTime!.isAfter(selectedEndTime!)) {
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
