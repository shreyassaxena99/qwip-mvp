import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TimePickerModal extends StatefulWidget {
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onTimeSelected;
  final DateTime selectedDate; // Date selected by the user
  final DateTime currentDate; // Current date and time
  final TimeOfDay?
      selectedStartTime; // Optional argument for additional filtering

  const TimePickerModal({
    Key? key,
    required this.initialTime,
    required this.onTimeSelected,
    required this.selectedDate,
    required this.currentDate,
    this.selectedStartTime,
  }) : super(key: key);

  @override
  _TimePickerModalState createState() => _TimePickerModalState();
}

class _TimePickerModalState extends State<TimePickerModal> {
  int selectedHour = 0;
  int selectedMinute = 0;

  @override
  void initState() {
    super.initState();

    // Initialize selected hour and minute
    selectedHour = widget.initialTime.hour;
    selectedMinute = widget.initialTime.minute -
        (widget.initialTime.minute % 15); // Round to 15-minute intervals
  }

  @override
  Widget build(BuildContext context) {
    // Check if the selected date is the same as the current date
    bool isToday = widget.selectedDate.year == widget.currentDate.year &&
        widget.selectedDate.month == widget.currentDate.month &&
        widget.selectedDate.day == widget.currentDate.day;

    // Get the start time hour and minute if provided
    int? startTimeHour = widget.selectedStartTime?.hour;
    int? startTimeMinute = widget.selectedStartTime?.minute;

    // Filter hours based on selectedStartTime and current time
    List<int> validHours =
        List<int>.generate(24, (index) => index).where((hour) {
      if (isToday && hour < widget.currentDate.hour) {
        return false; // Exclude past hours for today
      }
      if (startTimeHour != null && hour < startTimeHour) {
        return false; // Exclude hours before selected start time
      }
      return true;
    }).toList();

    // Filter minutes based on the current hour or the start time
    List<int> validMinutes =
        (isToday && selectedHour == widget.currentDate.hour)
            ? List<int>.generate(4, (index) => index * 15)
                .where((minute) => minute > widget.currentDate.minute)
                .toList()
            : (startTimeHour != null && selectedHour == startTimeHour)
                ? List<int>.generate(4, (index) => index * 15)
                    .where((minute) => minute > (startTimeMinute ?? 0))
                    .toList()
                : List<int>.generate(4, (index) => index * 15);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(
            height: 200, // Set the height of the picker
            child: Row(
              children: [
                // Hour Picker
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                        initialItem: validHours.indexOf(selectedHour)),
                    itemExtent: 40.0,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedHour = validHours[index];
                        selectedMinute = 0; // Reset minute when hour changes
                      });
                    },
                    children: validHours.map((hour) {
                      return Center(
                        child: Text(
                          hour.toString().padLeft(2, '0'),
                          style: const TextStyle(fontSize: 18),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Minute Picker
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                        initialItem: validMinutes.indexOf(selectedMinute)),
                    itemExtent: 40.0,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedMinute = validMinutes[index];
                      });
                    },
                    children: validMinutes.map((minute) {
                      return Center(
                        child: Text(
                          minute.toString().padLeft(2, '0'),
                          style: const TextStyle(fontSize: 18),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onTimeSelected(
                TimeOfDay(hour: selectedHour, minute: selectedMinute),
              );
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
